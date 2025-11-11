#!/bin/bash
set -e

# QuestVPN Peer Export Script
# Re-exports existing peer configuration as QR code

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PEERS_DIR="$PROJECT_ROOT/peers"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <peer-name> <region>"
    echo ""
    echo "Arguments:"
    echo "  peer-name : Name of existing peer"
    echo "  region    : west, east, or both"
    echo ""
    echo "Example:"
    echo "  $0 quest-user west"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

PEER_NAME=$1
REGION=$2

export_region() {
    local region=$1
    local conf_file="$PEERS_DIR/${PEER_NAME}.${region}.conf"
    
    if [ ! -f "$conf_file" ]; then
        echo -e "${RED}Error: Config file not found: $conf_file${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Exporting peer: $PEER_NAME ($region)${NC}"
    
    # Generate QR codes
    if command -v qrencode &> /dev/null; then
        QR_FILE="$PEERS_DIR/${PEER_NAME}.${region}.qr.png"
        qrencode -t PNG -o "$QR_FILE" -r "$conf_file"
        echo -e "${GREEN}QR code (PNG): $QR_FILE${NC}"
        
        QR_TEXT_FILE="$PEERS_DIR/${PEER_NAME}.${region}.qr.txt"
        qrencode -t ANSIUTF8 -r "$conf_file" > "$QR_TEXT_FILE"
        echo -e "${GREEN}QR code (ASCII): $QR_TEXT_FILE${NC}"
        
        # Display ASCII QR in terminal
        echo ""
        cat "$QR_TEXT_FILE"
        echo ""
    else
        echo -e "${RED}Error: qrencode not installed${NC}"
        exit 1
    fi
}

if [ "$REGION" = "both" ]; then
    export_region "west"
    export_region "east"
else
    export_region "$REGION"
fi

echo -e "${GREEN}Export complete!${NC}"
