#!/bin/bash
# Auto-tune MTU for optimal performance

set -e

INTERFACE="${1:-wg0}"
REGION="${2:-west}"

if [ "$REGION" = "west" ]; then
    CONTAINER="wg-easy-west"
else
    CONTAINER="wg-easy-east"
fi

echo "Auto-tuning MTU for $INTERFACE on $REGION region..."

# Get the default gateway
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n1)

if [ -z "$GATEWAY" ]; then
    echo "Error: Could not determine default gateway"
    exit 1
fi

# Test MTU sizes from 1500 down to 1280 (IPv6 minimum)
for MTU in 1500 1492 1472 1420 1400 1380 1360 1340 1320 1280; do
    # Subtract 80 bytes for WireGuard overhead (60 for WG + 20 for IP)
    TEST_SIZE=$((MTU - 80))
    
    echo -n "Testing MTU $MTU (payload $TEST_SIZE)... "
    
    if ping -M do -s $TEST_SIZE -c 1 -W 2 $GATEWAY >/dev/null 2>&1; then
        echo "OK"
        OPTIMAL_MTU=$MTU
        break
    else
        echo "FAILED"
    fi
done

if [ -z "$OPTIMAL_MTU" ]; then
    echo "Error: Could not determine optimal MTU, using default 1420"
    OPTIMAL_MTU=1420
fi

echo ""
echo "Optimal MTU: $OPTIMAL_MTU"
echo "Updating WireGuard configuration..."

# Update docker-compose environment
sed -i "s/WG_MTU=.*/WG_MTU=$OPTIMAL_MTU/" "/opt/questvpn/docker/docker-compose.yml"

# Restart container to apply new MTU
cd /opt/questvpn/docker
docker-compose restart wg-easy

echo "MTU updated to $OPTIMAL_MTU and container restarted"
echo ""
echo "Update your peer configs with MTU = $OPTIMAL_MTU"
