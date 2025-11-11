#!/bin/bash
# Generate a new WireGuard peer configuration

set -e

PEER_NAME="${1:-quest-$(date +%s)}"
REGION="${2:-west}"
PEERS_DIR="/opt/questvpn/peers"
DOCKER_DIR="/opt/questvpn/docker"

if [ ! -d "$PEERS_DIR" ]; then
    mkdir -p "$PEERS_DIR"
fi

echo "Generating peer: $PEER_NAME for region: $REGION"

# Use wg-easy API or generate manually
cd "$DOCKER_DIR"

# Generate keys
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)
PRESHARED_KEY=$(wg genpsk)

# Get server public key from running container
if [ "$REGION" = "west" ]; then
    CONTAINER="wg-easy-west"
else
    CONTAINER="wg-easy-east"
fi

SERVER_PUBLIC_KEY=$(docker exec "$CONTAINER" wg show wg0 public-key 2>/dev/null || echo "SERVER_PUBLIC_KEY_PLACEHOLDER")
SERVER_ENDPOINT=$(docker exec "$CONTAINER" printenv WG_HOST)

# Create peer config
cat > "$PEERS_DIR/${PEER_NAME}.conf" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.2.0.$(shuf -i 10-250 -n 1)/32
DNS = 10.2.0.2

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
Endpoint = $SERVER_ENDPOINT:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "Peer configuration created: $PEERS_DIR/${PEER_NAME}.conf"
echo "Run export-peer.sh to generate QR code"

# Add peer to server
docker exec "$CONTAINER" bash -c "cat >> /etc/wireguard/wg0.conf <<PEER
# $PEER_NAME
[Peer]
PublicKey = $PUBLIC_KEY
PresharedKey = $PRESHARED_KEY
AllowedIPs = 10.2.0.$(shuf -i 10-250 -n 1)/32
PEER
"

# Reload WireGuard
docker exec "$CONTAINER" wg syncconf wg0 <(wg showconf wg0) 2>/dev/null || true

echo "Peer added to server successfully!"
