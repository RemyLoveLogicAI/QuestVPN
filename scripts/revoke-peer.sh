#!/bin/bash
# Revoke a WireGuard peer

set -e

PEER_NAME="${1}"
REGION="${2:-west}"
PEERS_DIR="/opt/questvpn/peers"
DOCKER_DIR="/opt/questvpn/docker"

if [ -z "$PEER_NAME" ]; then
    echo "Usage: $0 <peer-name> [region]"
    echo "Available peers:"
    ls -1 "$PEERS_DIR"/*.conf 2>/dev/null | xargs -n1 basename -s .conf || echo "No peers found"
    exit 1
fi

PEER_CONF="$PEERS_DIR/${PEER_NAME}.conf"

if [ ! -f "$PEER_CONF" ]; then
    echo "Error: Peer configuration not found: $PEER_CONF"
    exit 1
fi

# Get public key from peer config
PUBLIC_KEY=$(grep "^PublicKey" "$PEER_CONF" | cut -d= -f2 | tr -d ' ' || echo "")

if [ -z "$PUBLIC_KEY" ]; then
    # Try to extract from server config
    PUBLIC_KEY=$(wg-quick strip "$PEER_CONF" | grep -A1 "\[Peer\]" | grep "PublicKey" | cut -d= -f2 | tr -d ' ')
fi

if [ "$REGION" = "west" ]; then
    CONTAINER="wg-easy-west"
else
    CONTAINER="wg-easy-east"
fi

# Remove peer from server
echo "Revoking peer: $PEER_NAME"

if [ -n "$PUBLIC_KEY" ]; then
    docker exec "$CONTAINER" wg set wg0 peer "$PUBLIC_KEY" remove 2>/dev/null || echo "Peer not found on server"
fi

# Archive the peer config
ARCHIVE_DIR="$PEERS_DIR/revoked"
mkdir -p "$ARCHIVE_DIR"
mv "$PEER_CONF" "$ARCHIVE_DIR/"
[ -f "$PEERS_DIR/${PEER_NAME}.png" ] && mv "$PEERS_DIR/${PEER_NAME}.png" "$ARCHIVE_DIR/"

echo "Peer revoked and archived to: $ARCHIVE_DIR"
