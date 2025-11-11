#!/bin/bash
# Export peer configuration as QR code PNG

set -e

PEER_NAME="${1}"
PEERS_DIR="/opt/questvpn/peers"

if [ -z "$PEER_NAME" ]; then
    echo "Usage: $0 <peer-name>"
    echo "Available peers:"
    ls -1 "$PEERS_DIR"/*.conf 2>/dev/null | xargs -n1 basename -s .conf || echo "No peers found"
    exit 1
fi

PEER_CONF="$PEERS_DIR/${PEER_NAME}.conf"

if [ ! -f "$PEER_CONF" ]; then
    echo "Error: Peer configuration not found: $PEER_CONF"
    exit 1
fi

# Generate QR code
QR_FILE="$PEERS_DIR/${PEER_NAME}.png"

qrencode -t png -o "$QR_FILE" < "$PEER_CONF"

echo "QR code generated: $QR_FILE"
echo ""
echo "To scan on Meta Quest:"
echo "1. Transfer $QR_FILE to your computer"
echo "2. Open WireGuard app on Quest"
echo "3. Select 'Scan from QR code'"
echo "4. Display the QR code on your screen"
echo ""
echo "Configuration:"
cat "$PEER_CONF"
