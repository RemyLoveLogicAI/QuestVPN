#!/bin/bash
# Health check for VPN services

set -e

REGION="${1:-west}"

if [ "$REGION" = "west" ]; then
    CONTAINER_PREFIX="west"
else
    CONTAINER_PREFIX="east"
fi

echo "=== Quest VPN Health Check - $REGION ==="
echo ""

# Check Docker containers
echo "Docker Containers:"
docker ps --filter "name=$CONTAINER_PREFIX" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check WireGuard status
echo "WireGuard Status:"
if docker exec "wg-easy-$CONTAINER_PREFIX" wg show 2>/dev/null; then
    echo "✓ WireGuard is running"
else
    echo "✗ WireGuard is not running"
fi
echo ""

# Check AdGuard
echo "AdGuard Status:"
if docker exec "adguard-$CONTAINER_PREFIX" wget -q --spider http://localhost:3000 2>/dev/null; then
    echo "✓ AdGuard is running"
else
    echo "✗ AdGuard is not running"
fi
echo ""

# Check Unbound
echo "Unbound Status:"
if docker exec "unbound-$CONTAINER_PREFIX" sh -c 'echo "server: verbosity: 1" | unbound-checkconf' 2>/dev/null; then
    echo "✓ Unbound is running"
else
    echo "✗ Unbound configuration check failed"
fi
echo ""

# Check network connectivity
echo "Network Connectivity:"
if docker exec "wg-easy-$CONTAINER_PREFIX" ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "✓ External connectivity OK"
else
    echo "✗ No external connectivity"
fi
echo ""

# Check UFW status
echo "Firewall Status:"
ufw status numbered
echo ""

# Check active peers
echo "Active Peers:"
docker exec "wg-easy-$CONTAINER_PREFIX" wg show wg0 peers 2>/dev/null | wc -l || echo "0"
echo ""

# Check disk usage
echo "Disk Usage:"
df -h /opt/questvpn
echo ""

echo "=== Health Check Complete ==="
