# Quest VPN - Quick Start Guide

## Overview

Quest VPN provides a secure WireGuard VPN solution optimized for Meta Quest devices with multi-region support, DNS ad-blocking via AdGuard Home, and recursive DNS resolution with Unbound.

## Prerequisites

- Linux server (Ubuntu 20.04+ recommended) in two regions (West/East)
- Docker and Docker Compose installed
- SSH access to servers
- Domain names pointed to your servers (optional, for dynamic DNS)

## Quick Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/RemyLoveLogicAI/QuestVPN.git
cd QuestVPN
```

### 2. Configure Environment

Copy the example environment file:

```bash
cp docker/.env.example docker/.env
```

Edit `docker/.env` and set:
- `WG_HOST_WEST`: Your west region domain/IP
- `WG_HOST_EAST`: Your east region domain/IP  
- `WG_PASSWORD`: Web UI password for wg-easy
- Cloudflare credentials (if using DDNS)

### 3. Update Ansible Inventory

Edit `ansible/inventory.ini` with your server details:

```ini
[vpn_west]
your-west-server.com ansible_user=ubuntu region=west

[vpn_east]
your-east-server.com ansible_user=ubuntu region=east
```

### 4. Deploy with Ansible

Run the one-shot deployment playbook:

```bash
cd ansible
ansible-playbook -i inventory.ini deploy.yml
```

This will:
- ✅ Install Docker and dependencies
- ✅ Harden SSH (disable password auth, disable root login)
- ✅ Configure UFW firewall
- ✅ Set up fail2ban for SSH protection
- ✅ Deploy WireGuard, AdGuard Home, and Unbound
- ✅ Copy utility scripts

### 5. Generate Your First Peer

SSH into your server and generate a peer configuration:

```bash
ssh ubuntu@your-west-server.com
cd /opt/questvpn/scripts
./gen-peer.sh my-quest-1 west
```

### 6. Export QR Code

Generate a QR code for easy import to Meta Quest:

```bash
./export-peer.sh my-quest-1
```

This creates `my-quest-1.png` in `/opt/questvpn/peers/`

### 7. Transfer QR Code

Download the QR code to your computer:

```bash
# On your local machine
scp ubuntu@your-west-server.com:/opt/questvpn/peers/my-quest-1.png .
```

## Access Web Interfaces

### wg-easy (WireGuard Management)
- URL: `https://your-server.com:443`
- Default port: 443 (HTTPS)
- Use password from `.env` file

### AdGuard Home (DNS Management)
- URL: `http://your-server.com:3000`
- Initial setup required on first visit
- Configure upstream DNS to point to Unbound (10.2.0.3)

## Network Architecture

```
Internet
    ↓
WireGuard (51820/udp) → wg-easy (10.2.0.1)
    ↓                         ↓
Quest Device → VPN Tunnel → AdGuard Home (10.2.0.2)
                                  ↓
                            Unbound (10.2.0.3)
                                  ↓
                            Internet (DNS Queries)
```

## Regions

- **West Region**: Lower latency for users in Americas/West Coast
- **East Region**: Lower latency for users in Europe/East Coast/Asia

Choose the region closest to your location for best performance.

## Next Steps

- [Quest Sideload Guide](quest-sideload.md) - Install WireGuard on Meta Quest
- [Split Tunnel Configuration](split-tunnel.md) - Route only specific traffic through VPN
- [Always-On ADB](always-on-adb.md) - Enable persistent ADB over WiFi
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## Utility Scripts

All scripts are located in `/opt/questvpn/scripts/`:

- `gen-peer.sh <name> <region>` - Generate new peer configuration
- `export-peer.sh <name>` - Export peer config as QR code PNG
- `revoke-peer.sh <name> <region>` - Revoke and archive peer
- `mtu-autotune.sh <interface> <region>` - Auto-tune MTU for optimal performance
- `healthcheck.sh <region>` - Check VPN health status
- `cf-ddns.sh <region>` - Update Cloudflare DNS with current IP

## Security Features

✅ SSH hardening (key-only authentication, no root login)  
✅ UFW firewall with minimal required ports  
✅ fail2ban for brute-force protection  
✅ WireGuard with modern cryptography  
✅ Private DNS resolution (no ISP snooping)  
✅ Ad-blocking at DNS level  

## Support

For issues, check the [Troubleshooting Guide](troubleshooting.md) or open an issue on GitHub.
