# Quick Start Guide

This guide will walk you through deploying your WireGuard VPN infrastructure and connecting your Meta Quest device in under 30 minutes.

## Prerequisites

### Infrastructure
- Two Hetzner Cloud VPS instances (Ubuntu 24.04 LTS)
  - West region: Hillsboro (HIL)
  - East region: Ashburn (ASH)
  - Minimum: CX11 (2 vCPU, 2GB RAM)
- Public IPv4 addresses for both servers
- Optional: Domain names for easier management

### Local Environment
- GitHub Codespaces (recommended) or Docker Desktop
- SSH key pair for server access
- Meta Quest device (Quest 2, 3, or Pro)

## Step 1: Prepare Infrastructure

### Create Hetzner Cloud Servers

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create two projects or use one project with labels

**West Server (Hillsboro):**
```
Name: questvpn-west
Location: Hillsboro, OR (hil)
Image: Ubuntu 24.04
Type: CX11 (or larger)
SSH Key: Add your public key
```

**East Server (Ashburn):**
```
Name: questvpn-east
Location: Ashburn, VA (ash)
Image: Ubuntu 24.04
Type: CX11 (or larger)
SSH Key: Add your public key
```

3. Note the IPv4 addresses assigned to each server

### Optional: Configure DNS

If you have a domain, create A records:
```
west.vpn.example.com → <west-server-ip>
east.vpn.example.com → <east-server-ip>
```

Or use Cloudflare DDNS (configured later).

## Step 2: Open in Codespaces

1. Fork or clone this repository to your GitHub account
2. Click "Code" → "Codespaces" → "Create codespace on main"
3. Wait for the devcontainer to build (includes all required tools)

Alternatively, open locally:
```bash
git clone https://github.com/RemyLoveLogicAI/QuestVPN.git
cd QuestVPN
code .
# Reopen in container when prompted
```

## Step 3: Configure Environment

### Create Environment Files

```bash
# Copy template for both regions
cp .env.example .env.west
cp .env.example .env.east
```

### Edit West Configuration

```bash
nano .env.west
```

Required settings:
```bash
# Public hostname or IP (can use Cloudflare DDNS later)
WG_HOST=<west-server-ip>
WG_HOST_BACKUP=<east-server-ip>

# Ports
WG_PORT=51820
WG_PORT_ALT=443

# Dashboard password (choose strong password)
WG_DASHBOARD_PASS=<strong-password>

# DNS (AdGuard Home internal address)
WG_DEFAULT_DNS=10.2.0.2

# Region identifier
REGION_TAG=west

# AdGuard setup port (restrict after initial setup)
ADGUARD_SETUP_PORT=3000

# IPv6 support (enable if your server has IPv6)
ENABLE_IPV6=true
```

Optional Cloudflare DDNS:
```bash
CF_API_TOKEN=<your-cloudflare-token>
CF_ZONE_ID=<your-zone-id>
CF_RECORD_NAME_WEST=west.vpn.example.com
```

### Edit East Configuration

```bash
nano .env.east
```

Same as west, but change:
```bash
WG_HOST=<east-server-ip>
WG_HOST_BACKUP=<west-server-ip>
REGION_TAG=east
CF_RECORD_NAME_EAST=east.vpn.example.com
```

### Update Ansible Inventory

```bash
nano infra/ansible/inventory.ini
```

```ini
[vpn_west]
questvpn-west ansible_host=<west-server-ip> ansible_user=root region=west

[vpn_east]
questvpn-east ansible_host=<east-server-ip> ansible_user=root region=east

[vpn_servers:children]
vpn_west
vpn_east

[vpn_servers:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
```

## Step 4: Test SSH Connectivity

```bash
# Test west server
ssh -i ~/.ssh/id_rsa root@<west-server-ip> "echo 'West server reachable'"

# Test east server
ssh -i ~/.ssh/id_rsa root@<east-server-ip> "echo 'East server reachable'"
```

If you encounter issues:
- Ensure your SSH key is loaded: `ssh-add ~/.ssh/id_rsa`
- Verify the key is authorized on the servers
- Check firewall rules allow SSH (port 22)

## Step 5: Deploy Infrastructure

### Run Ansible Playbook

```bash
ansible-playbook -i infra/ansible/inventory.ini infra/ansible/playbook.yml
```

This will:
1. Harden SSH access (disable root login, key-only auth)
2. Configure UFW firewall with strict rules
3. Install and configure fail2ban
4. Enable unattended security updates
5. Install Docker Engine with security hardening
6. Deploy WireGuard, AdGuard Home, and Unbound
7. Configure DNS chain (WireGuard → AdGuard → Unbound)
8. Open required ports (22, 51820, 443, 51821, 3000)
9. Start all services with health checks

Expected duration: 5-10 minutes per region

### Verify Deployment

The playbook will print URLs at the end:
```
PLAY RECAP ********************************************************
questvpn-west : ok=45 changed=32
questvpn-east : ok=45 changed=32

WEST REGION:
  WireGuard UI: http://<west-ip>:51821
  AdGuard Home: http://<west-ip>:3000

EAST REGION:
  WireGuard UI: http://<east-ip>:51821
  AdGuard Home: http://<east-ip>:3000
```

### Initial AdGuard Setup

For each region:

1. Open `http://<server-ip>:3000` in browser
2. Click "Get Started"
3. Set admin username and password
4. **Important:** Set upstream DNS to `10.2.0.3:53` (Unbound)
5. Disable other upstreams (Cloudflare, Google, etc.)
6. Enable DNSSEC validation
7. Complete setup

After setup, **restrict AdGuard port** (see Security section).

## Step 6: Generate Quest Peer

### Create Dual-Region Profile

```bash
# Full tunnel (all traffic through VPN)
./scripts/gen-peer.sh quest-user both full

# Or split tunnel (exclude local networks)
./scripts/gen-peer.sh quest-user both split
```

Output:
```
Generating peer: quest-user
Region: both
Tunnel mode: full

West Region:
  Allocated IP: 10.2.0.10/32
  MTU detected: 1420
  Config: peers/quest-user.west.conf
  QR Code: peers/quest-user.west.qr.png

East Region:
  Allocated IP: 10.2.0.10/32
  MTU detected: 1420
  Config: peers/quest-user.east.conf
  QR Code: peers/quest-user.east.qr.png

Peer generated successfully!
```

### View QR Codes

In Codespaces:
```bash
# View QR code in terminal (ASCII)
cat peers/quest-user.west.qr.txt

# Download PNG files via browser
# Click peers folder → Download quest-user.west.qr.png
```

## Step 7: Install WireGuard on Quest

### Enable Developer Mode

1. Open Meta Quest mobile app
2. Go to Menu → Devices → Select your Quest
3. Tap "Developer Mode" toggle
4. Accept developer agreement

### Install WireGuard via SideQuest

**Method 1: SideQuest (Recommended)**

1. Install [SideQuest](https://sidequestvr.com/) on your computer
2. Connect Quest via USB cable
3. Allow USB debugging on Quest when prompted
4. Download WireGuard Android APK:
   ```bash
   wget https://download.wireguard.com/android-client/com.wireguard.android-latest.apk
   ```
5. Drag APK into SideQuest to install

**Method 2: WebADB**

1. Visit [WebADB](https://app.webadb.com/)
2. Connect Quest via USB
3. Allow USB debugging
4. Install WireGuard APK through browser

See [docs/QUEST_SIDELOAD.md](docs/QUEST_SIDELOAD.md) for detailed instructions.

## Step 8: Connect Quest to VPN

### Add Profiles from QR Code

1. Put on Quest headset
2. Open App Library → Unknown Sources → WireGuard
3. Tap "+" → "Create from QR code"
4. Scan `quest-user.west.qr.png` (display on computer screen)
5. Name: "Quest West"
6. Repeat for east: Scan `quest-user.east.qr.png` → "Quest East"

### Connect and Test

1. Select "Quest West" profile
2. Tap toggle to connect
3. Accept VPN permission if prompted
4. Verify connection:
   - Status should show "Connected"
   - Last handshake within seconds
   - Transfer showing bytes

### Verify VPN is Working

**Check Public IP:**
```
1. Open Meta Quest Browser
2. Visit: https://ifconfig.me/
3. Should show your VPN server IP (not home IP)
```

**Check DNS Leak:**
```
1. Visit: https://dnsleaktest.com/
2. Run standard test
3. Should show your VPN server location only
4. No ISP DNS servers should appear
```

**Test Ad Blocking:**
```
1. Visit: https://ads-blocker.com/testing/
2. Most ads should be blocked by AdGuard
```

## Step 9: Configure Split Tunneling (Optional)

### Full Tunnel vs Split Tunnel

**Full tunnel** (default):
- All traffic through VPN
- Maximum privacy
- May increase latency for local services

**Split tunnel**:
- Only specified traffic through VPN
- Keep local network access (casting, file shares)
- Better performance for local apps

### Per-App Split Tunneling

In WireGuard app on Quest:

1. Edit profile (gear icon)
2. Scroll to "Applications"
3. Choose "Exclude" or "Include"

**Exclude mode** (recommended):
- All apps use VPN except selected
- Exclude: Meta Home, Meta TV, local media apps

**Include mode**:
- Only selected apps use VPN
- Include: Browser, streaming apps

See [docs/SPLIT_TUNNEL.md](docs/SPLIT_TUNNEL.md) for detailed strategies.

## Step 10: Enable Always-On (Optional)

### Via ADB (Developer Mode)

```bash
# Connect Quest via ADB
adb connect <quest-ip>:5555

# Enable Always-On for WireGuard
adb shell settings put global wireguard_always_on 1
adb shell settings put secure vpn_always_on com.wireguard.android
adb shell settings put secure vpn_lockdown 1
```

**Note:** Firmware support varies. Some Quest OS versions don't support Always-On.

See [docs/ALWAYS_ON_ADB.md](docs/ALWAYS_ON_ADB.md) for details.

## Step 11: Set Up Router (Optional - Lane B)

### Generate Router Peer

```bash
./scripts/gen-peer.sh router-home west full
```

### Configure GL.iNet Router

1. Access router admin panel (usually http://192.168.8.1)
2. Go to VPN → WireGuard Client
3. Click "Set Up WireGuard Client Manually"
4. Paste contents of `peers/router-home.west.conf`
5. Save and connect

Now any device (including Quest) connected to this router's Wi-Fi will automatically use VPN.

See [docs/ROUTER_CLIENT.md](docs/ROUTER_CLIENT.md) for full guide.

## Maintenance Tasks

### Health Check

```bash
# Check both regions
./scripts/healthcheck.sh west
./scripts/healthcheck.sh east
```

### Export Peer QR Code Again

```bash
./scripts/export-peer.sh quest-user west
```

### Revoke Peer Access

```bash
./scripts/revoke-peer.sh quest-user both
```

### Update DNS Records (Cloudflare DDNS)

```bash
./scripts/cf-ddns.sh
```

### Rotate Server Keys (Advanced)

```bash
# Read documentation first
./scripts/rotate-keys.sh west
```

## Troubleshooting

### Can't connect to VPN
- Check server firewall allows UDP 51820 and 443
- Try alternate port (443) if 51820 is blocked
- Verify server is running: `ssh root@<server-ip> "docker ps"`

### Connected but no internet
- Check DNS chain: `./scripts/healthcheck.sh west`
- Verify AdGuard upstream is Unbound (10.2.0.3)
- Test DNS: `nslookup example.com 10.2.0.2`

### Slow speeds
- Run MTU auto-tune: `./scripts/mtu-autotune.sh quest-user west`
- Try the other region (west vs east)
- Check server bandwidth

### DNS leaks
- Ensure `DNS = 10.2.0.2` in WireGuard config
- Disable "Private DNS" on Quest if enabled
- Re-generate peer config if needed

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for complete troubleshooting guide.

## Security Recommendations

### After Initial Setup

1. **Restrict AdGuard UI access:**
   ```bash
   # SSH to server
   ssh root@<server-ip>
   
   # Edit UFW to block external access to port 3000
   ufw delete allow 3000/tcp
   ufw allow from 10.2.0.0/24 to any port 3000 proto tcp
   ```

2. **Change default passwords:**
   - WireGuard dashboard: Access via http://<server-ip>:51821
   - AdGuard Home: Access via http://<server-ip>:3000

3. **Review firewall rules:**
   ```bash
   ufw status verbose
   ```

4. **Enable 2FA for server SSH** (if supported)

5. **Set up monitoring:**
   - Configure health check cron
   - Set up uptime monitoring (e.g., UptimeRobot)

### Regular Maintenance

- Review WireGuard logs monthly
- Rotate server keys quarterly
- Update server packages: `ssh root@<server> "apt update && apt upgrade -y"`
- Audit peer list and revoke unused peers

See [SECURITY.md](SECURITY.md) for comprehensive security guidelines.

## Next Steps

- Explore [per-app split tunneling](docs/SPLIT_TUNNEL.md)
- Set up [router client](docs/ROUTER_CLIENT.md) for seamless VPN
- Configure [Always-On VPN](docs/ALWAYS_ON_ADB.md)
- Learn about [MTU tuning](docs/MTU_TUNING.md)
- Set up monitoring and alerts

## Support

- **Documentation:** [docs/](docs/) directory
- **Issues:** [GitHub Issues](https://github.com/RemyLoveLogicAI/QuestVPN/issues)
- **Security:** [SECURITY.md](SECURITY.md)

---

**Congratulations!** You now have a production-grade WireGuard VPN optimized for your Meta Quest device.
