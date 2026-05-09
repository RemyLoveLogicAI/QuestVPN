#!/bin/bash
set -e

# QuestVPN Peer Generation Script
# Generates WireGuard peer configurations with QR codes and MTU auto-tuning

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PEERS_DIR="$PROJECT_ROOT/peers"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage
usage() {
    echo "Usage: $0 <peer-name> <region> <tunnel-mode>"
    echo ""
    echo "Arguments:"
    echo "  peer-name    : Name for the peer (e.g., quest-user, router-home)"
    echo "  region       : west, east, or both"
    echo "  tunnel-mode  : full or split"
    echo ""
    echo "Examples:"
    echo "  $0 quest-user both full"
    echo "  $0 router-home west split"
    exit 1
}

# Check arguments
if [ $# -ne 3 ]; then
    usage
fi

PEER_NAME=$1
REGION=$2
TUNNEL_MODE=$3

# Validate inputs
if [[ ! "$REGION" =~ ^(west|east|both)$ ]]; then
    echo -e "${RED}Error: Region must be 'west', 'east', or 'both'${NC}"
    exit 1
fi

if [[ ! "$TUNNEL_MODE" =~ ^(full|split)$ ]]; then
    echo -e "${RED}Error: Tunnel mode must be 'full' or 'split'${NC}"
    exit 1
fi

# Create peers directory if it doesn't exist
mkdir -p "$PEERS_DIR"

# Function to generate peer for a specific region
generate_peer_region() {
    local region=$1
    local env_file="$PROJECT_ROOT/.env.$region"
    
    echo -e "${GREEN}Generating peer for region: $region${NC}"
    
    # Check if env file exists
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Error: $env_file not found${NC}"
        echo "Please create it from .env.example"
        exit 1
    fi
    
    # Source environment variables
    source "$env_file"
    
    # Generate WireGuard keys
    PRIVATE_KEY=$(wg genkey)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)
    PRESHARED_KEY=$(wg genpsk)
    
    # Allocate IP (simple incrementing for demo - in production, track used IPs)
    # For this example, we'll use a random IP in the range 10.2.0.10-254
    PEER_IP="10.2.0.$((RANDOM % 245 + 10))"
    
    # Determine AllowedIPs based on tunnel mode
    if [ "$TUNNEL_MODE" = "full" ]; then
        ALLOWED_IPS="0.0.0.0/0, ::/0"
    else
        # Split tunnel - exclude RFC1918 private networks
        ALLOWED_IPS="0.0.0.0/5, 8.0.0.0/7, 11.0.0.0/8, 12.0.0.0/6, 16.0.0.0/4, 32.0.0.0/3, 64.0.0.0/2, 128.0.0.0/3, 160.0.0.0/5, 168.0.0.0/6, 172.0.0.0/12, 172.32.0.0/11, 172.64.0.0/10, 172.128.0.0/9, 173.0.0.0/8, 174.0.0.0/7, 176.0.0.0/4, 192.0.0.0/9, 192.128.0.0/11, 192.160.0.0/13, 192.169.0.0/16, 192.170.0.0/15, 192.172.0.0/14, 192.176.0.0/12, 192.192.0.0/10, 193.0.0.0/8, 194.0.0.0/7, 196.0.0.0/6, 200.0.0.0/5, 208.0.0.0/4"
    fi
    
    # Auto-detect MTU (default to 1420 if detection fails)
    MTU=1420
    if command -v ping &> /dev/null && [ -n "$WG_HOST" ]; then
        echo "Auto-detecting optimal MTU..."
        for test_mtu in 1420 1400 1380 1360 1340 1320 1280; do
            if ping -M do -s $((test_mtu - 80)) -c 1 -W 2 "$WG_HOST" &> /dev/null; then
                MTU=$test_mtu
                echo "Optimal MTU detected: $MTU"
                break
            fi
        done
    fi
    
    # Generate peer configuration file
    CONF_FILE="$PEERS_DIR/${PEER_NAME}.${region}.conf"
    cat > "$CONF_FILE" << EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = ${PEER_IP}/32
DNS = ${WG_DEFAULT_DNS:-10.2.0.2}
MTU = $MTU

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
PresharedKey = $PRESHARED_KEY
Endpoint = ${WG_HOST}:${WG_PORT:-51820}
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = ${WG_PERSISTENT_KEEPALIVE:-25}
EOF
    
    echo -e "${GREEN}Config file created: $CONF_FILE${NC}"
    
    # Generate QR code (PNG)
    if command -v qrencode &> /dev/null; then
        QR_FILE="$PEERS_DIR/${PEER_NAME}.${region}.qr.png"
        qrencode -t PNG -o "$QR_FILE" -r "$CONF_FILE"
        echo -e "${GREEN}QR code (PNG) created: $QR_FILE${NC}"
        
        # Also generate ASCII QR code for terminal display
        QR_TEXT_FILE="$PEERS_DIR/${PEER_NAME}.${region}.qr.txt"
        qrencode -t ANSIUTF8 -r "$CONF_FILE" > "$QR_TEXT_FILE"
        echo -e "${GREEN}QR code (ASCII) created: $QR_TEXT_FILE${NC}"
    else
        echo -e "${YELLOW}Warning: qrencode not found, skipping QR code generation${NC}"
    fi
    
    # Display summary
    echo ""
    echo "Peer configuration summary:"
    echo "  Name: $PEER_NAME"
    echo "  Region: $region"
    echo "  IP: ${PEER_IP}/32"
    echo "  MTU: $MTU"
    echo "  Tunnel mode: $TUNNEL_MODE"
    echo "  Public key: $PUBLIC_KEY"
    echo ""
    echo "Add this peer to your WireGuard server with:"
    echo "  Public Key: $PUBLIC_KEY"
    echo "  Allowed IPs: ${PEER_IP}/32"
    echo "  Preshared Key: $PRESHARED_KEY"
    echo ""
}

# Generate for specified region(s)
if [ "$REGION" = "both" ]; then
    generate_peer_region "west"
    echo ""
    generate_peer_region "east"
else
    generate_peer_region "$REGION"
fi

echo -e "${GREEN}Peer generation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Scan the QR code with WireGuard app on your device"
echo "  2. Or manually import the .conf file"
echo "  3. Connect and verify with: ./scripts/healthcheck.sh $REGION"
