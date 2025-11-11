# QuestVPN Best Setup

**Production-grade WireGuard VPN optimized for Meta Quest devices**

A complete, secure, and beginner-friendly solution for the best WireGuard VPN experience on Meta Quest with two deployment lanes:

- **Lane A (On-device):** Official WireGuard Android app on Quest with split-tunnel controls, MTU auto-tuning, and optional Always-On + lockdown
- **Lane B (Router/Hotspot):** GL.iNet/OpenWrt as a WireGuard client for seamless "always-on VPN" when connected to that SSID

## Features

### 🚀 Dual-Region Deployment
- **West (HIL)** and **East (ASH)** Hetzner Cloud regions
- Automatic failover with dual profiles per peer
- Geographic redundancy for reliability

### 🔒 Privacy-First DNS
- **Unbound** validating recursive resolver (DNSSEC, qname-minimization)
- **AdGuard Home** blocks ads, trackers, and malware
- Zero DNS leaks - all queries stay within your infrastructure

### ⚡ Optimized Performance
- MTU auto-detection per peer (DF ping sweep 1280–1420)
- PersistentKeepalive = 25 for NAT traversal
- Dual ports: 51820/udp and 443/udp (for restrictive networks)

### 🛡️ Security Hardened
- SSH key-only authentication
- UFW strict allowlist firewall
- fail2ban protection
- Unattended security updates
- Minimal logging

### 🎯 Quest-Optimized
- One-tap QR code provisioning
- Per-app split tunneling support
- Sideloading guides for Quest 2/3/Pro
- Optional Always-On + lockdown mode

### 🔧 Developer Experience
- GitHub Codespaces ready
- One-command Ansible deployment
- Comprehensive helper scripts
- Built-in health checks

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for detailed setup instructions.

### 1. Deploy Infrastructure

```bash
# Open in GitHub Codespaces or local devcontainer
# Configure your hosts
cp .env.example .env.west
cp .env.example .env.east
# Edit .env.west and .env.east with your settings

# Update inventory
nano infra/ansible/inventory.ini

# Deploy both regions
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml
```

### 2. Create Quest Peer

```bash
# Generate dual-region profiles with full tunnel
./scripts/gen-peer.sh quest-user both full

# QR codes saved to:
# peers/quest-user.west.qr.png
# peers/quest-user.east.qr.png
```

### 3. Connect Quest

1. Enable Developer Mode on Quest
2. Install WireGuard via SideQuest or WebADB
3. Scan QR code to add profiles
4. Connect and verify

See [docs/QUEST_SIDELOAD.md](docs/QUEST_SIDELOAD.md) for detailed instructions.

## Architecture

### Network Overlay

```
10.2.0.0/24 - WireGuard overlay network
├── 10.2.0.1 - WireGuard server gateway
├── 10.2.0.2 - AdGuard Home (DNS)
└── 10.2.0.3 - Unbound (recursive resolver)

Peers: 10.2.0.10 - 10.2.0.254 (/32 assignments)
```

### Service Stack

```
┌─────────────────┐
│   WireGuard     │ :51820/udp, :443/udp
│   (wg-easy)     │ :51821/tcp (web UI)
└────────┬────────┘
         │ DNS → 10.2.0.2
         ▼
┌─────────────────┐
│  AdGuard Home   │ :53/udp (internal only)
│                 │ :3000/tcp (setup UI)
└────────┬────────┘
         │ Upstream → 10.2.0.3
         ▼
┌─────────────────┐
│    Unbound      │ :53/udp (internal only)
│   (DNSSEC)      │ → Root DNS servers
└─────────────────┘
```

## Repository Structure

```
quest-vpn-best/
├── README.md                    # This file
├── QUICKSTART.md                # Step-by-step deployment guide
├── SECURITY.md                  # Security best practices
├── LICENSE                      # MIT license
├── .gitignore                   # Git ignore patterns
├── .env.example                 # Environment template
│
├── .devcontainer/               # GitHub Codespaces configuration
│   ├── devcontainer.json
│   └── Dockerfile
│
├── infra/ansible/               # Infrastructure as Code
│   ├── inventory.ini            # Host definitions
│   ├── group_vars/all.yml       # Global variables
│   ├── playbook.yml             # Main deployment playbook
│   └── roles/
│       ├── common/              # SSH, firewall, fail2ban
│       ├── docker/              # Docker Engine setup
│       └── wg_stack/            # WireGuard stack deployment
│
├── regions/                     # Per-region configurations
│   ├── west/
│   │   └── docker-compose.yml
│   ├── east/
│   │   └── docker-compose.yml
│   └── shared/
│       ├── adguard/bootstrap.yaml
│       ├── unbound/unbound.conf
│       └── unbound/root.hints
│
├── scripts/                     # Helper utilities
│   ├── gen-peer.sh              # Generate new peer configs
│   ├── export-peer.sh           # Re-export existing peer
│   ├── revoke-peer.sh           # Revoke peer access
│   ├── rotate-keys.sh           # Rotate server keys
│   ├── healthcheck.sh           # System health validation
│   ├── mtu-autotune.sh          # MTU optimization
│   └── cf-ddns.sh               # Cloudflare DDNS updater
│
├── docs/                        # Detailed documentation
│   ├── QUEST_SIDELOAD.md        # Quest installation guide
│   ├── ROUTER_CLIENT.md         # GL.iNet setup
│   ├── SPLIT_TUNNEL.md          # Split tunneling strategies
│   ├── ALWAYS_ON_ADB.md         # Always-On configuration
│   ├── MTU_TUNING.md            # MTU optimization guide
│   └── TROUBLESHOOTING.md       # Common issues and fixes
│
└── peers/                       # Generated peer configs (gitignored)
    └── .gitkeep
```

## Scripts Reference

### Peer Management

```bash
# Generate new peer (full tunnel, both regions)
./scripts/gen-peer.sh <name> both full

# Generate split tunnel (excludes LAN)
./scripts/gen-peer.sh <name> west split

# Export existing peer QR codes
./scripts/export-peer.sh <name> west

# Revoke peer access
./scripts/revoke-peer.sh <name> both
```

### Maintenance

```bash
# System health check
./scripts/healthcheck.sh west

# Update Cloudflare DNS records
./scripts/cf-ddns.sh

# Rotate server keys (advanced)
./scripts/rotate-keys.sh west
```

## Security Considerations

- **Secrets Management:** Never commit `.env` files. Use `.env.example` as template.
- **SSH Access:** Key-only authentication, disable root login.
- **Firewall:** UFW allowlist with minimal open ports.
- **Updates:** Unattended security updates enabled.
- **Logging:** Minimal retention, rotate frequently.
- **DNS Privacy:** All DNS queries encrypted and resolved internally.

See [SECURITY.md](SECURITY.md) for complete security guidelines.

## Use Cases

### On-Device (Lane A)
- Install WireGuard app on Quest via sideloading
- Import dual-region profiles via QR code
- Select region based on location or performance
- Configure per-app split tunneling for optimal performance
- Enable Always-On for complete privacy

### Router/Hotspot (Lane B)
- Generate router peer configuration
- Import into GL.iNet travel router
- Connect Quest to router's SSID
- Automatic VPN for all devices on that network
- No Quest-side configuration needed

## Optional Features

### Cloudflare DDNS
Automatically update DNS records when server IPs change:

```bash
# Add to .env.west and .env.east
CF_API_TOKEN=your_token
CF_ZONE_ID=your_zone_id
CF_RECORD_NAME_WEST=west.vpn.example.com
CF_RECORD_NAME_EAST=east.vpn.example.com

# Update records
./scripts/cf-ddns.sh
```

### IPv6 Support
Enable dual-stack for improved connectivity:

```bash
# In .env files
ENABLE_IPV6=true
```

## Troubleshooting

Common issues and solutions:

- **Can't connect:** Check UDP ports 51820 and 443 are open
- **No internet:** Verify AdGuard → Unbound DNS chain
- **Slow speeds:** Run `./scripts/mtu-autotune.sh` for your peer
- **DNS leaks:** Ensure `WG_DEFAULT_DNS=10.2.0.2` in config
- **Packet loss:** Increase PersistentKeepalive to 25

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for complete guide.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly in both regions
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgments

- [WireGuard](https://www.wireguard.com/) - Fast, modern VPN protocol
- [wg-easy](https://github.com/wg-easy/wg-easy) - WireGuard management UI
- [AdGuard Home](https://adguard.com/adguard-home/) - Network-wide ad blocking
- [Unbound](https://nlnetlabs.nl/projects/unbound/) - Validating DNS resolver
- [Hetzner Cloud](https://www.hetzner.com/cloud) - Reliable infrastructure

## Support

- **Issues:** [GitHub Issues](https://github.com/RemyLoveLogicAI/QuestVPN/issues)
- **Documentation:** See [docs/](docs/) directory
- **Security:** See [SECURITY.md](SECURITY.md) for reporting vulnerabilities

---

**Built with ❤️ for the Meta Quest community**
