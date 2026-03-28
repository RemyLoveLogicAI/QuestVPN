#!/bin/bash
set -e

echo "=========================================="
echo "  QuestVPN Development Environment"
echo "=========================================="
echo ""

# Make scripts executable
if [ -d "/workspace/scripts" ]; then
    chmod +x /workspace/scripts/*.sh
    echo "✓ Made scripts executable"
fi

# Create peers directory if it doesn't exist
mkdir -p /workspace/peers
touch /workspace/peers/.gitkeep
echo "✓ Created peers directory"

# Check SSH key
if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
    echo "✓ SSH key found"
else
    echo "⚠ No SSH key found. Generate one with:"
    echo "  ssh-keygen -t ed25519 -C 'questvpn-dev'"
fi

# Display tool versions
echo ""
echo "Installed tools:"
echo "  - Ansible: $(ansible --version | head -n 1)"
echo "  - Python: $(python3 --version)"
echo "  - Docker: $(docker --version 2>/dev/null || echo 'Not available in container')"
echo "  - jq: $(jq --version)"
echo "  - yq: $(yq --version)"
echo "  - qrencode: $(qrencode --version 2>&1 | head -n 1)"
echo ""

# Display quick start guide
echo "=========================================="
echo "  Quick Start"
echo "=========================================="
echo ""
echo "1. Configure your servers:"
echo "   cp .env.example .env.west"
echo "   cp .env.example .env.east"
echo "   nano .env.west"
echo "   nano .env.east"
echo ""
echo "2. Update Ansible inventory:"
echo "   nano infra/ansible/inventory.ini"
echo ""
echo "3. Deploy infrastructure:"
echo "   ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml"
echo ""
echo "4. Generate peer configuration:"
echo "   ./scripts/gen-peer.sh quest-user both full"
echo ""
echo "5. Check system health:"
echo "   ./scripts/healthcheck.sh west"
echo ""
echo "=========================================="
echo "  Documentation"
echo "=========================================="
echo ""
echo "  - README.md: Project overview"
echo "  - QUICKSTART.md: Detailed setup guide"
echo "  - SECURITY.md: Security best practices"
echo "  - docs/: Additional documentation"
echo ""
echo "=========================================="
echo "  Ready to begin!"
echo "=========================================="
echo ""
