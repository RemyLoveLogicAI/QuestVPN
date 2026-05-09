#!/bin/bash
set -e

# QuestVPN Health Check Script
# Validates system health and service status

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

# Source environment variables
source "$ENV_FILE"

echo "=========================================="
echo "  QuestVPN Health Check - $REGION"
echo "=========================================="
echo ""

# Check SSH connectivity
echo -n "Checking SSH connectivity... "
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${WG_HOST}/22" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "Cannot connect to SSH port on $WG_HOST"
    exit 1
fi

# Check WireGuard port
echo -n "Checking WireGuard port (${WG_PORT:-51820}/udp)... "
if nc -vzu "$WG_HOST" "${WG_PORT:-51820}" 2>&1 | grep -q succeeded; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}Cannot verify (UDP check requires server-side test)${NC}"
fi

# Check WireGuard dashboard
echo -n "Checking WireGuard dashboard... "
if timeout 5 curl -s -o /dev/null -w "%{http_code}" "http://${WG_HOST}:51821" | grep -q "200\|401"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Check AdGuard Home
echo -n "Checking AdGuard Home... "
if timeout 5 curl -s -o /dev/null -w "%{http_code}" "http://${WG_HOST}:3000" | grep -q "200\|302"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}Not accessible (may be restricted to VPN)${NC}"
fi

# DNS resolution test (requires VPN connection)
echo -n "Testing DNS resolution (10.2.0.2)... "
if command -v dig &> /dev/null; then
    if dig @10.2.0.2 +short example.com 2>/dev/null | grep -q .; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}Requires VPN connection${NC}"
    fi
else
    echo -e "${YELLOW}dig not installed, skipping${NC}"
fi

echo ""
echo "=========================================="
echo "  Health Check Summary"
echo "=========================================="
echo ""
echo "Region: $REGION"
echo "Host: $WG_HOST"
echo "WireGuard Port: ${WG_PORT:-51820}"
echo "Dashboard: http://${WG_HOST}:51821"
echo "AdGuard: http://${WG_HOST}:3000"
echo ""
echo -e "${GREEN}Health check complete!${NC}"
