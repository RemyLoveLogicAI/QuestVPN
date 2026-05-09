#!/bin/bash
set -e

# QuestVPN MTU Auto-Tuning Script
# Detects optimal MTU for WireGuard connection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <region> [target-host]"
    echo ""
    echo "Arguments:"
    echo "  region      : west or east"
    echo "  target-host : Optional. Host to ping (default: gateway from .env)"
    echo ""
    echo "Example:"
    echo "  $0 west"
    echo "  $0 east 1.1.1.1"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

REGION=$1
TARGET=${2:-}
ENV_FILE="$PROJECT_ROOT/.env.$REGION"

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: $ENV_FILE not found${NC}"
    exit 1
fi

# Source environment variables
source "$ENV_FILE"

# Use WG_HOST as target if not specified
if [ -z "$TARGET" ]; then
    TARGET="$WG_HOST"
fi

echo "=========================================="
echo "  MTU Auto-Tuning - $REGION"
echo "=========================================="
echo ""
echo "Target host: $TARGET"
echo "Testing MTU range: 1280-1420"
echo ""

# WireGuard overhead is typically 60 bytes
WG_OVERHEAD=80

OPTIMAL_MTU=1280

for MTU in 1420 1400 1380 1360 1340 1320 1300 1280; do
    PACKET_SIZE=$((MTU - WG_OVERHEAD))
    echo -n "Testing MTU $MTU (packet size $PACKET_SIZE)... "
    
    if ping -M do -s "$PACKET_SIZE" -c 3 -W 2 "$TARGET" &> /dev/null; then
        echo -e "${GREEN}OK${NC}"
        OPTIMAL_MTU=$MTU
        break
    else
        echo -e "${RED}FAILED${NC}"
    fi
done

echo ""
echo "=========================================="
echo "  Results"
echo "=========================================="
echo ""
echo -e "Optimal MTU: ${GREEN}$OPTIMAL_MTU${NC}"
echo ""
echo "Update your WireGuard configuration with:"
echo "  MTU = $OPTIMAL_MTU"
echo ""
echo "Or regenerate peer configs to apply automatically."

exit 0
