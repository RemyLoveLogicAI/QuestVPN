# Quest VPN - WireGuard VPN for Meta Quest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready WireGuard VPN solution optimized for Meta Quest devices with multi-region support, DNS ad-blocking, and automated deployment.

## 🎯 Features

- **🌍 Multi-Region Support**: Deploy in West and East regions for optimal performance
- **🔐 WireGuard VPN**: Modern, fast, and secure VPN protocol
- **🛡️ DNS Security**: 
  - AdGuard Home for ad-blocking and DNS filtering
  - Unbound for recursive DNS resolution
  - Protection against DNS leaks and tracking
- **🚀 One-Shot Deployment**: Automated Ansible playbook for complete infrastructure setup
- **🔒 Security Hardening**:
  - SSH hardening (key-only auth, no root login)
  - UFW firewall configuration
  - fail2ban for brute-force protection
- **🛠️ Utility Scripts**:
  - Peer generation with QR code export
  - Peer revocation and management
  - MTU auto-tuning for optimal performance
  - Health checks and monitoring
  - Cloudflare Dynamic DNS support
- **📱 Quest-Optimized**:
  - Detailed sideloading guides (SideQuest/WebADB)
  - Split-tunnel configuration for local network access
  - Always-on ADB over WiFi setup
  - Comprehensive troubleshooting guide
- **🐳 Docker-Based**: Easy deployment with Docker Compose
- **👨‍💻 DevContainer Ready**: Pre-configured development environment

## 🏗️ Architecture

```
┌─────────────┐
│  Meta Quest │
│   Device    │
└──────┬──────┘
       │ WireGuard Tunnel (51820/udp)
       │
       ▼
┌──────────────────────────────────────┐
│         VPN Server (10.2.0.0/24)     │
│  ┌────────────────────────────────┐  │
│  │ wg-easy (10.2.0.1)             │  │
│  │ - WireGuard server             │  │
│  │ - Web UI (443/tcp)             │  │
│  └──────────┬─────────────────────┘  │
│             │                         │
│  ┌──────────▼─────────────────────┐  │
│  │ AdGuard Home (10.2.0.2)        │  │
│  │ - DNS filtering & ad-blocking  │  │
│  │ - Web UI (3000/tcp)            │  │
│  └──────────┬─────────────────────┘  │
│             │                         │
│  ┌──────────▼─────────────────────┐  │
│  │ Unbound (10.2.0.3)             │  │
│  │ - Recursive DNS resolver       │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Linux server (Ubuntu 20.04+) in two regions
- SSH access to servers
- Domain names (optional, for DDNS)
- Meta Quest headset with Developer Mode enabled

### 1. Clone Repository

```bash
git clone https://github.com/RemyLoveLogicAI/QuestVPN.git
cd QuestVPN
```

### 2. Configure

```bash
# Copy environment template
cp docker/.env.example docker/.env

# Edit configuration
nano docker/.env
```

Set your values:
```env
WG_HOST_WEST=vpn-west.example.com
WG_HOST_EAST=vpn-east.example.com
WG_PASSWORD=secure_password_here
```

### 3. Update Inventory

Edit `ansible/inventory.ini` with your server details:

```ini
[vpn_west]
your-west-server.com ansible_user=ubuntu region=west

[vpn_east]
your-east-server.com ansible_user=ubuntu region=east
```

### 4. Deploy

```bash
cd ansible
ansible-playbook -i inventory.ini deploy.yml
```

### 5. Generate Peer

```bash
ssh ubuntu@your-west-server.com
cd /opt/questvpn/scripts
./gen-peer.sh my-quest-1 west
./export-peer.sh my-quest-1
```

### 6. Install on Quest

Transfer the QR code and follow the [Quest Sideload Guide](docs/quest-sideload.md).

## 📚 Documentation

- **[Quickstart Guide](docs/quickstart.md)** - Get up and running quickly
- **[Quest Sideload Guide](docs/quest-sideload.md)** - Install WireGuard on Meta Quest
- **[Split Tunnel Configuration](docs/split-tunnel.md)** - Configure selective routing
- **[Always-On ADB](docs/always-on-adb.md)** - Enable wireless ADB debugging
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🛠️ Utility Scripts

Located in `/opt/questvpn/scripts/`:

| Script | Description |
|--------|-------------|
| `gen-peer.sh` | Generate new WireGuard peer configuration |
| `export-peer.sh` | Export peer config as QR code PNG |
| `revoke-peer.sh` | Revoke and archive a peer |
| `mtu-autotune.sh` | Auto-tune MTU for optimal performance |
| `healthcheck.sh` | Check VPN service health |
| `cf-ddns.sh` | Update Cloudflare DNS with current IP |

**Example Usage:**

```bash
# Generate peer for Quest device
./gen-peer.sh quest-headset-1 west

# Export as QR code
./export-peer.sh quest-headset-1

# Check system health
./healthcheck.sh west

# Optimize MTU
./mtu-autotune.sh wg0 west
```

## 🔧 Configuration

### Docker Compose

Two independent deployments for multi-region:
- `docker/west/docker-compose.yml` - West region
- `docker/east/docker-compose.yml` - East region

Each includes:
- **wg-easy**: WireGuard server with web UI (port 51820/udp, 443/tcp)
- **AdGuard Home**: DNS filtering (port 53/tcp+udp, 3000/tcp)
- **Unbound**: Recursive DNS resolver

### Network Layout

- **Overlay Network**: 10.2.0.0/24
- **wg-easy**: 10.2.0.1
- **AdGuard Home**: 10.2.0.2
- **Unbound**: 10.2.0.3
- **Peers**: 10.2.0.10-250 (dynamic allocation)

### Firewall Rules

Configured by Ansible:
- TCP 22 (SSH)
- UDP 51820 (WireGuard)
- TCP 443 (wg-easy web UI)
- TCP/UDP 53 (DNS)
- TCP 3000 (AdGuard Home web UI)

## 🔒 Security Features

✅ **SSH Hardening**
- Public key authentication only
- Root login disabled
- Fail2ban protection

✅ **Network Security**
- UFW firewall with minimal ports
- WireGuard with modern cryptography (ChaCha20-Poly1305)
- Private DNS resolution (no ISP logging)

✅ **DNS Security**
- Ad-blocking at DNS level
- Malware and tracking protection
- DNSSEC validation via Unbound

## 🎮 Quest-Specific Features

### Sideloading Methods

1. **SideQuest** - GUI application (beginner-friendly)
2. **WebADB** - Browser-based (no installation)
3. **ADB CLI** - Command-line (advanced)

### Configuration Options

- **Full Tunnel**: All traffic through VPN
- **Split Tunnel**: Selective routing (local network access)
- **Always-On VPN**: Persistent connection
- **Always-On ADB**: Wireless debugging

### Performance Optimization

- MTU auto-tuning for Quest devices
- PersistentKeepalive for stable connections
- Multi-region support for lower latency
- Split-tunnel for reduced bandwidth usage

## 🐳 Development

### DevContainer

Pre-configured development environment:

```bash
# Open in VS Code with DevContainers extension
code .
# Container will auto-provision with:
# - Ansible
# - qrencode
# - Docker-in-Docker
# - WireGuard tools
```

### Manual Setup

```bash
# Install dependencies
pip install ansible qrcode[pil]
apt-get install qrencode wireguard-tools docker-compose

# Test locally
cd docker/west
docker-compose up -d
```

## 📊 Monitoring

### Health Check

```bash
/opt/questvpn/scripts/healthcheck.sh west
```

Output includes:
- Container status
- WireGuard peers count
- Network connectivity
- Firewall rules
- Disk usage

### Web Interfaces

- **wg-easy**: `https://your-server:443` (WireGuard management)
- **AdGuard Home**: `http://your-server:3000` (DNS management)

### Logs

```bash
# Docker logs
cd /opt/questvpn/docker
docker-compose logs -f

# WireGuard status
docker exec wg-easy-west wg show

# AdGuard logs
docker logs adguard-west -f
```

## 🌐 Multi-Region Deployment

Deploy in multiple regions for:
- **Lower latency**: Users connect to nearest region
- **Redundancy**: Failover if one region is down
- **Load distribution**: Spread users across regions

Regions included:
- **West**: Optimized for Americas/West Coast
- **East**: Optimized for Europe/East Coast/Asia

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [WireGuard](https://www.wireguard.com/) - Fast, modern VPN protocol
- [wg-easy](https://github.com/wg-easy/wg-easy) - WireGuard web UI
- [AdGuard Home](https://adguard.com/en/adguard-home/overview.html) - DNS filtering
- [Unbound](https://nlnetlabs.nl/projects/unbound/about/) - Recursive DNS resolver
- Meta Quest community for VR development support

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/RemyLoveLogicAI/QuestVPN/issues)
- **Discussions**: [GitHub Discussions](https://github.com/RemyLoveLogicAI/QuestVPN/discussions)
- **Documentation**: [docs/](docs/)

## 🗺️ Roadmap

- [ ] Automated peer expiration
- [ ] Prometheus metrics export
- [ ] Grafana dashboards
- [ ] IPv6 support
- [ ] Additional region templates
- [ ] Terraform/OpenTofu deployment option
- [ ] Quest app integration scripts
- [ ] Automated backups

---

**Made with ❤️ for the Meta Quest community**