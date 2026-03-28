#!/bin/bash
set -e

# QuestVPN Server Key Rotation Script
# CAUTION: This will disconnect all peers temporarily

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <region>"
    echo ""
    echo "Arguments:"
    echo "  region : west or east"
    echo ""
    echo "WARNING: This will disconnect all peers and require re-configuration!"
    echo ""
    echo "Example:"
    echo "  $0 west"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

REGION=$1
ENV_FILE="$PROJECT_ROOT/.env.$REGION"

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: $ENV_FILE not found${NC}"
    exit 1
fi

source "$ENV_FILE"

echo "=========================================="
echo "  WireGuard Server Key Rotation"
echo "=========================================="
echo ""
echo -e "${RED}WARNING: This operation will disconnect all peers!${NC}"
echo "All peer configurations will need to be regenerated."
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Rotating keys for region: $REGION"
echo "Server: $WG_HOST"
echo ""

# Generate new server keys
NEW_PRIVATE_KEY=$(wg genkey)
NEW_PUBLIC_KEY=$(echo "$NEW_PRIVATE_KEY" | wg pubkey)

echo "New server public key: $NEW_PUBLIC_KEY"
echo ""

echo -e "${YELLOW}IMPORTANT: Save the new public key for peer configurations!${NC}"
echo ""
echo "Next steps:"
echo "  1. SSH to the $REGION server"
echo "  2. Update WireGuard server configuration with new keys"
echo "  3. Restart WireGuard: docker compose restart wg-easy"
echo "  4. Regenerate all peer configurations with new server public key"
echo ""

# Save keys to file for reference
KEYS_FILE="$PROJECT_ROOT/keys-${REGION}-$(date +%Y%m%d_%H%M%S).txt"
cat > "$KEYS_FILE" << EOF
Region: $REGION
Generated: $(date)

Server Private Key: $NEW_PRIVATE_KEY
Server Public Key: $NEW_PUBLIC_KEY

IMPORTANT: Store this file securely and delete after rotation is complete.
EOF

chmod 600 "$KEYS_FILE"
echo "Keys saved to: $KEYS_FILE"
echo -e "${RED}Delete this file after rotation is complete!${NC}"
echo ""
echo "Key rotation initiated. Complete the steps above to finish."
