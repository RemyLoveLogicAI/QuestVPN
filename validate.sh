#!/bin/bash
# Validate Quest VPN setup before deployment

set -e

echo "=== Quest VPN Setup Validator ==="
echo ""

# Track errors
ERRORS=0

# Check Docker
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo "✓ Docker $DOCKER_VERSION installed"
else
    echo "✗ Docker not found"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker Compose
echo -n "Checking Docker Compose... "
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "installed")
    echo "✓ Docker Compose $COMPOSE_VERSION installed"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
    echo "✓ Docker Compose (legacy) $COMPOSE_VERSION installed"
    echo "  ⚠ Consider upgrading to Docker Compose V2 (docker compose)"
else
    echo "✗ Docker Compose not found"
    ERRORS=$((ERRORS + 1))
fi

# Check Ansible
echo -n "Checking Ansible... "
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1 | awk '{print $2}')
    echo "✓ Ansible $ANSIBLE_VERSION installed"
else
    echo "⚠ Ansible not found (optional, needed for deployment)"
fi

# Check qrencode
echo -n "Checking qrencode... "
if command -v qrencode &> /dev/null; then
    echo "✓ qrencode installed"
else
    echo "⚠ qrencode not found (optional, needed for QR code generation)"
fi

# Check wireguard-tools
echo -n "Checking WireGuard tools... "
if command -v wg &> /dev/null; then
    echo "✓ WireGuard tools installed"
else
    echo "⚠ WireGuard tools not found (optional, for advanced management)"
fi

echo ""
echo "=== Configuration Validation ==="
echo ""

# Check .env file
echo -n "Checking docker/.env... "
if [ -f "docker/.env" ]; then
    echo "✓ Found"
    
    # Check required variables
    source docker/.env
    
    if [ -z "$WG_HOST_WEST" ] || [ "$WG_HOST_WEST" = "vpn-west.example.com" ]; then
        echo "  ⚠ WG_HOST_WEST not configured (still using example value)"
    fi
    
    if [ -z "$WG_HOST_EAST" ] || [ "$WG_HOST_EAST" = "vpn-east.example.com" ]; then
        echo "  ⚠ WG_HOST_EAST not configured (still using example value)"
    fi
    
    if [ -z "$WG_PASSWORD" ] || [ "$WG_PASSWORD" = "change_this_password" ]; then
        echo "  ✗ WG_PASSWORD not set or using default value!"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "✗ Not found"
    echo "  Run: cp docker/.env.example docker/.env"
    ERRORS=$((ERRORS + 1))
fi

# Check inventory
echo -n "Checking ansible/inventory.ini... "
if [ -f "ansible/inventory.ini" ]; then
    echo "✓ Found"
    
    if grep -q "example.com" ansible/inventory.ini; then
        echo "  ⚠ Inventory still contains example.com - update with your servers"
    fi
else
    echo "✗ Not found"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker Compose files
echo -n "Checking docker-compose files... "
if [ -f "docker/west/docker-compose.yml" ] && [ -f "docker/east/docker-compose.yml" ]; then
    echo "✓ Found"
    
    # Validate syntax
    cd docker/west
    if docker compose config > /dev/null 2>&1; then
        echo "  ✓ West region: valid syntax"
    else
        echo "  ✗ West region: syntax errors"
        ERRORS=$((ERRORS + 1))
    fi
    cd ../..
    
    cd docker/east
    if docker compose config > /dev/null 2>&1; then
        echo "  ✓ East region: valid syntax"
    else
        echo "  ✗ East region: syntax errors"
        ERRORS=$((ERRORS + 1))
    fi
    cd ../..
else
    echo "✗ Docker Compose files missing"
    ERRORS=$((ERRORS + 1))
fi

# Check Ansible playbook syntax
echo -n "Checking Ansible playbook... "
if [ -f "ansible/deploy.yml" ]; then
    if command -v ansible-playbook &> /dev/null; then
        cd ansible
        if ansible-playbook deploy.yml --syntax-check > /dev/null 2>&1; then
            echo "✓ Valid syntax"
        else
            echo "✗ Syntax errors"
            ERRORS=$((ERRORS + 1))
        fi
        cd ..
    else
        echo "⚠ Cannot validate (Ansible not installed)"
    fi
else
    echo "✗ Not found"
    ERRORS=$((ERRORS + 1))
fi

# Check scripts
echo -n "Checking utility scripts... "
SCRIPT_COUNT=0
for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    else
        echo "  ⚠ $script not executable"
    fi
done
echo "✓ Found $SCRIPT_COUNT scripts"

# Check documentation
echo -n "Checking documentation... "
DOC_COUNT=$(ls -1 docs/*.md 2>/dev/null | wc -l)
echo "✓ Found $DOC_COUNT documentation files"

echo ""
echo "=== Summary ==="
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✅ Validation passed! Your setup is ready."
    echo ""
    echo "Next steps:"
    echo "1. Review docker/.env configuration"
    echo "2. Update ansible/inventory.ini with your servers"
    echo "3. Run: ./deploy.sh <west|east|all>"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s)."
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi
