# Quest VPN - Deploy Script
# One-shot deployment wrapper for convenience

#!/bin/bash

set -e

REGION="${1}"
INVENTORY="${2:-ansible/inventory.ini}"

if [ -z "$REGION" ]; then
    echo "Usage: $0 <west|east|all> [inventory-file]"
    echo ""
    echo "Examples:"
    echo "  $0 west                  # Deploy west region only"
    echo "  $0 east                  # Deploy east region only"
    echo "  $0 all                   # Deploy both regions"
    echo "  $0 west custom.ini       # Use custom inventory"
    exit 1
fi

if [ ! -f "$INVENTORY" ]; then
    echo "Error: Inventory file not found: $INVENTORY"
    exit 1
fi

echo "=== Quest VPN Deployment ==="
echo "Region: $REGION"
echo "Inventory: $INVENTORY"
echo ""

# Check Ansible installation
if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: Ansible not found. Please install Ansible first:"
    echo "  pip install ansible"
    echo "  or"
    echo "  apt-get install ansible"
    exit 1
fi

# Check Docker .env file
if [ ! -f "docker/.env" ]; then
    echo "Warning: docker/.env not found. Creating from template..."
    cp docker/.env.example docker/.env
    echo ""
    echo "Please edit docker/.env with your configuration:"
    echo "  nano docker/.env"
    echo ""
    read -p "Press Enter when ready to continue..."
fi

# Deploy based on region
cd ansible

if [ "$REGION" = "west" ]; then
    echo "Deploying to West region..."
    ansible-playbook -i "$INVENTORY" deploy.yml --limit vpn_west
elif [ "$REGION" = "east" ]; then
    echo "Deploying to East region..."
    ansible-playbook -i "$INVENTORY" deploy.yml --limit vpn_east
elif [ "$REGION" = "all" ]; then
    echo "Deploying to all regions..."
    ansible-playbook -i "$INVENTORY" deploy.yml
else
    echo "Error: Invalid region. Use 'west', 'east', or 'all'"
    exit 1
fi

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Next steps:"
echo "1. Generate a peer configuration:"
echo "   ssh user@vpn-server 'cd /opt/questvpn/scripts && ./gen-peer.sh my-quest-1 $REGION'"
echo ""
echo "2. Export as QR code:"
echo "   ssh user@vpn-server 'cd /opt/questvpn/scripts && ./export-peer.sh my-quest-1'"
echo ""
echo "3. Download QR code:"
echo "   scp user@vpn-server:/opt/questvpn/peers/my-quest-1.png ."
echo ""
echo "4. Access web interfaces:"
echo "   - wg-easy: https://vpn-server:443"
echo "   - AdGuard Home: http://vpn-server:3000"
echo ""
