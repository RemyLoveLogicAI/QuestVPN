#!/bin/bash
set -e

# QuestVPN Peer Revocation Script
# Revokes peer access and archives configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PEERS_DIR="$PROJECT_ROOT/peers"
REVOKED_DIR="$PEERS_DIR/revoked"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <peer-name> <region>"
    echo ""
    echo "Arguments:"
    echo "  peer-name : Name of peer to revoke"
    echo "  region    : west, east, or both"
    echo ""
    echo "Example:"
    echo "  $0 quest-user both"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

PEER_NAME=$1
REGION=$2

# Create revoked directory
mkdir -p "$REVOKED_DIR"

revoke_region() {
    local region=$1
    local conf_file="$PEERS_DIR/${PEER_NAME}.${region}.conf"
    
    if [ ! -f "$conf_file" ]; then
        echo -e "${YELLOW}Warning: Config file not found: $conf_file${NC}"
        return
    fi
    
    echo -e "${GREEN}Revoking peer: $PEER_NAME ($region)${NC}"
    
    # Archive configuration files
    local timestamp=$(date +%Y%m%d_%H%M%S)
    mv "$conf_file" "$REVOKED_DIR/${PEER_NAME}.${region}.${timestamp}.conf"
    
    # Archive QR codes if they exist
    [ -f "$PEERS_DIR/${PEER_NAME}.${region}.qr.png" ] && \
        mv "$PEERS_DIR/${PEER_NAME}.${region}.qr.png" "$REVOKED_DIR/${PEER_NAME}.${region}.${timestamp}.qr.png"
    
    [ -f "$PEERS_DIR/${PEER_NAME}.${region}.qr.txt" ] && \
        mv "$PEERS_DIR/${PEER_NAME}.${region}.qr.txt" "$REVOKED_DIR/${PEER_NAME}.${region}.${timestamp}.qr.txt"
    
    echo -e "${GREEN}Peer revoked and archived${NC}"
    echo ""
    echo "IMPORTANT: Remove this peer from your WireGuard server:"
    echo "  1. SSH to the $region server"
    echo "  2. Access WireGuard UI or edit config manually"
    echo "  3. Delete the peer entry"
    echo "  4. Restart WireGuard: docker compose restart wg-easy"
}

if [ "$REGION" = "both" ]; then
    revoke_region "west"
    revoke_region "east"
else
    revoke_region "$REGION"
fi

echo -e "${GREEN}Revocation complete!${NC}"
echo "Archived files are in: $REVOKED_DIR"
