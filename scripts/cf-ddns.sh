#!/bin/bash
set -e

# QuestVPN Cloudflare DDNS Update Script
# Updates Cloudflare DNS records with current server IPs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "  Cloudflare DDNS Updater"
echo "=========================================="
echo ""

update_dns() {
    local region=$1
    local env_file="$PROJECT_ROOT/.env.$region"
    
    if [ ! -f "$env_file" ]; then
        echo -e "${YELLOW}Warning: $env_file not found, skipping${NC}"
        return
    fi
    
    source "$env_file"
    
    # Check if Cloudflare variables are set
    if [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ZONE_ID" ]; then
        echo -e "${YELLOW}Cloudflare credentials not configured for $region${NC}"
        return
    fi
    
    # Determine record name based on region
    if [ "$region" = "west" ]; then
        RECORD_NAME="${CF_RECORD_NAME_WEST}"
    else
        RECORD_NAME="${CF_RECORD_NAME_EAST}"
    fi
    
    if [ -z "$RECORD_NAME" ]; then
        echo -e "${YELLOW}No record name configured for $region${NC}"
        return
    fi
    
    echo "Updating DNS for $region..."
    echo "  Record: $RECORD_NAME"
    echo "  Current IP: $WG_HOST"
    
    # Get current IP (if WG_HOST is a domain, resolve it first)
    CURRENT_IP="$WG_HOST"
    if ! [[ "$CURRENT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "  Resolving domain to IP..."
        CURRENT_IP=$(dig +short "$WG_HOST" | tail -n1)
    fi
    
    # Get record ID
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=${RECORD_NAME}&type=A" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')
    
    if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
        # Record doesn't exist, create it
        echo "  Creating new DNS record..."
        RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${CURRENT_IP}\",\"ttl\":120,\"proxied\":false}")
    else
        # Record exists, update it
        echo "  Updating existing DNS record..."
        RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${CURRENT_IP}\",\"ttl\":120,\"proxied\":false}")
    fi
    
    # Check response
    SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
    if [ "$SUCCESS" = "true" ]; then
        echo -e "  ${GREEN}DNS record updated successfully${NC}"
    else
        echo -e "  ${RED}Failed to update DNS record${NC}"
        echo "  Response: $RESPONSE"
    fi
    
    echo ""
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo "Install with: apt-get install jq"
    exit 1
fi

# Update both regions
update_dns "west"
update_dns "east"

echo "=========================================="
echo -e "${GREEN}DDNS update complete!${NC}"
echo "=========================================="
