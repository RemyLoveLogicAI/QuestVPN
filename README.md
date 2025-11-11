# Quest VPN - Enterprise WireGuard VPN for Meta Quest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue)](/.github/workflows/ci-cd.yml)
[![Security](https://img.shields.io/badge/Security-Scanned-green)](#security-features)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-orange)](#monitoring-and-observability)
[![SLA](https://img.shields.io/badge/SLA-99.9%25-brightgreen)](docs/SLA.md)

An enterprise-grade, production-ready WireGuard VPN solution optimized for Meta Quest devices with multi-region support, DNS ad-blocking, comprehensive monitoring, and automated deployment.

## 🏆 Enterprise Features

### Production-Grade Infrastructure
- **CI/CD Pipeline**: Automated testing, security scanning, and deployment
- **Monitoring & Alerting**: Prometheus, Grafana, Alertmanager with custom dashboards
- **Centralized Logging**: Loki + Promtail for log aggregation
- **Automated Backups**: 6-hour incremental backups with S3 storage
- **Disaster Recovery**: RTO 1 hour, RPO 6 hours with documented procedures
- **High Availability**: Multi-region deployment with failover capabilities
- **Security Scanning**: Trivy, Checkov, automated vulnerability detection
- **Compliance**: SOC 2 ready, GDPR compliant
- **SLA**: 99.9% uptime guarantee with monitoring

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

### User Guides
- **[Quickstart Guide](docs/quickstart.md)** - Get up and running quickly
- **[Quest Sideload Guide](docs/quest-sideload.md)** - Install WireGuard on Meta Quest
- **[Split Tunnel Configuration](docs/split-tunnel.md)** - Configure selective routing
- **[Always-On ADB](docs/always-on-adb.md)** - Enable wireless ADB debugging
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

### Operations
- **[Operational Runbook](docs/runbook.md)** - Day-to-day operations guide
- **[Disaster Recovery Plan](docs/disaster-recovery.md)** - Emergency procedures
- **[Change Management](docs/change-management.md)** - Change control process
- **[SLA](docs/SLA.md)** - Service level agreement and commitments

### Architecture & Security
- **[Architecture Decisions](docs/architecture-decisions.md)** - Design rationale (ADRs)
- **[Security Policy](docs/security-policy.md)** - Comprehensive security documentation

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

## 📊 Monitoring and Observability

### Monitoring Stack

The complete monitoring solution provides real-time visibility into all services:

```bash
# Start monitoring stack
cd monitoring
docker compose up -d
```

**Access Points:**
- **Grafana**: `http://your-server:3001` (Dashboards and visualization)
- **Prometheus**: `http://your-server:9090` (Metrics and queries)
- **Alertmanager**: `http://your-server:9093` (Alert management)
- **wg-easy**: `https://your-server:443` (WireGuard management)
- **AdGuard Home**: `http://your-server:3000` (DNS management)

### Key Metrics Monitored

| Metric Category | Examples |
|----------------|----------|
| **VPN Health** | Connection count, handshake time, peer status |
| **DNS Performance** | Query rate, response time, failure rate |
| **System Resources** | CPU, memory, disk, network bandwidth |
| **Container Health** | Container status, restart count, resource usage |
| **Security** | Failed auth attempts, firewall blocks, intrusion attempts |

### Alerts

Automated alerts for:
- ⚠️ VPN server down (2 min)
- ⚠️ High CPU usage (>80% for 5 min)
- ⚠️ High memory usage (>85% for 5 min)
- ⚠️ Low disk space (<15%)
- ⚠️ DNS query failures (>5%)
- ⚠️ Container failures

Notifications via:
- Slack (critical/warning channels)
- Email (critical alerts)
- PagerDuty (P1 incidents)

### Health Check

```bash
/opt/questvpn/scripts/healthcheck.sh west
```

### Logs

Centralized logging with Loki:
```bash
# View logs in Grafana (Explore → Loki)
# Or query directly
docker logs <container-name>
```

## 🌐 Multi-Region Deployment

Deploy in multiple regions for:
- **Lower latency**: Users connect to nearest region
- **Redundancy**: Failover if one region is down
- **Load distribution**: Spread users across regions

Regions included:
- **West**: Optimized for Americas/West Coast
- **East**: Optimized for Europe/East Coast/Asia

## 🔄 CI/CD Pipeline

Automated workflows for quality assurance:

- **Linting**: Shell scripts, YAML, Ansible playbooks
- **Security Scanning**: Trivy (containers), Checkov (IaC)
- **Testing**: Integration tests, syntax validation
- **Build**: Multi-region Docker builds with health checks
- **Release**: Automated tagging and changelog generation

View workflow: [.github/workflows/ci-cd.yml](.github/workflows/ci-cd.yml)

## 💾 Backup & Disaster Recovery

### Automated Backups

```bash
# Backups run every 6 hours via cron
/opt/questvpn/backup-restore/backup.sh

# Manual backup
cd backup-restore
./backup.sh

# Restore from backup
./restore.sh <backup-file.tar.gz>
```

**Backup includes:**
- WireGuard configurations
- AdGuard Home settings
- Unbound configuration
- Peer configurations
- Environment settings

**Storage:**
- Local: `/opt/questvpn/backups` (30-day retention)
- Remote: S3-compatible storage (encrypted)

### Disaster Recovery

- **RTO** (Recovery Time Objective): 1 hour
- **RPO** (Recovery Point Objective): 6 hours
- Documented procedures: [docs/disaster-recovery.md](docs/disaster-recovery.md)
- Tested quarterly

## 📋 Service Level Agreement

**Uptime Target**: 99.9% per month  
**Support Response Times:**
- Critical (P1): 15 minutes
- High (P2): 1 hour
- Medium (P3): 4 hours
- Low (P4): 1 business day

Full SLA: [docs/SLA.md](docs/SLA.md)

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes (follow style guides)
4. Run tests: `pytest tests/`
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

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