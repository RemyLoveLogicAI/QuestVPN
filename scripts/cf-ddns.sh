#!/bin/bash
# Cloudflare Dynamic DNS updater

set -e

REGION="${1}"

if [ -z "$REGION" ]; then
    echo "Usage: $0 <west|east>"
    exit 1
fi

# Load environment variables
if [ -f /opt/questvpn/docker/.env ]; then
    source /opt/questvpn/docker/.env
else
    echo "Error: .env file not found"
    exit 1
fi

if [ "$REGION" = "west" ]; then
    RECORD_NAME="${CF_RECORD_NAME_WEST}"
else
    RECORD_NAME="${CF_RECORD_NAME_EAST}"
fi

# Get current public IP
PUBLIC_IP=$(curl -s https://api.ipify.org)

if [ -z "$PUBLIC_IP" ]; then
    echo "Error: Could not determine public IP"
    exit 1
fi

echo "Current public IP: $PUBLIC_IP"
echo "Updating DNS record: $RECORD_NAME"

# Get record ID
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=${RECORD_NAME}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
    echo "Error: Could not find DNS record"
    exit 1
fi

# Update record
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${PUBLIC_IP}\",\"ttl\":120,\"proxied\":false}")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
    echo "✓ DNS record updated successfully"
else
    echo "✗ Failed to update DNS record"
    echo "$RESPONSE" | jq .
    exit 1
fi
