# GL.iNet Router WireGuard Client Setup

Configure your GL.iNet travel router as a WireGuard client for effortless Quest VPN connectivity.

## Lane B: Router-Based VPN

Instead of configuring VPN on each device, set up your router as a VPN client:

- **Benefit:** Quest automatically uses VPN when connected to router's SSID
- **Use case:** Travel, hotels, public Wi-Fi
- **Setup:** One-time router configuration

## Supported Routers

GL.iNet models with WireGuard support:

- GL-AXT1800 (Slate AX)
- GL-A1300 (Slate Plus)
- GL-MT1300 (Beryl)
- GL-AR750S (Slate)
- GL-MT300N-V2 (Mango)
- Any GL.iNet router with firmware 3.x or 4.x

## Step 1: Generate Router Peer Config

```bash
# Generate config for router
./scripts/gen-peer.sh router-home west full

# Output: peers/router-home.west.conf
```

## Step 2: Access Router Admin Panel

1. Connect computer to router's Wi-Fi
2. Open browser to: `http://192.168.8.1`
3. Login with admin password
4. Complete initial setup if first time

## Step 3: Configure WireGuard Client

### GL.iNet Firmware 4.x

1. Go to **VPN** → **WireGuard Client**
2. Click **Set Up WireGuard Client Manually**
3. Paste contents of `peers/router-home.west.conf`
4. **Configuration Name:** QuestVPN West
5. Click **Save**

### GL.iNet Firmware 3.x

1. Go to **Applications** → **WireGuard Client**
2. Click **Add Configuration**
3. Paste configuration file contents
4. Name: **QuestVPN West**
5. Click **Apply**

## Step 4: Connect Router to VPN

1. In WireGuard Client page, click **Connect**
2. Wait 10-15 seconds
3. Status should show **Connected**
4. Check **Current IP** displays VPN server IP

## Step 5: Verify Connection

### Check Router Status

1. In router admin panel, go to **Internet** or **WAN**
2. Should show WireGuard interface as active
3. Public IP should be VPN server IP

### Check Device IP

1. Connect Quest to router's Wi-Fi
2. Open Quest Browser
3. Visit: `https://ifconfig.me/`
4. Should display VPN server IP

### DNS Leak Test

1. Visit: `https://dnsleaktest.com/`
2. Run Standard Test
3. Should only show VPN server location

## Configuration Options

### Policy-Based Routing

Route only specific devices through VPN:

1. Go to **VPN** → **VPN Policy**
2. Select **Only allow the following use VPN**
3. Add Quest device by MAC address
4. Other devices use regular internet

### Kill Switch

Prevent internet access if VPN disconnects:

1. Go to **VPN** → **WireGuard Client**
2. Enable **VPN Kill Switch**
3. Internet blocked when VPN is down

### DNS Configuration

Force router to use VPN DNS:

1. Go to **Network** → **DNS**
2. **Mode:** Manual
3. **Primary DNS:** 10.2.0.2 (AdGuard)
4. **Secondary DNS:** Leave empty
5. Apply changes

## Multi-Region Setup

### Add Both Regions

```bash
# Generate both configs
./scripts/gen-peer.sh router-home west full
./scripts/gen-peer.sh router-home east full
```

**In router admin panel:**

1. Add **QuestVPN West** configuration
2. Add **QuestVPN East** configuration
3. Switch between regions as needed

### Auto-Failover (Advanced)

Some GL.iNet routers support failover:

1. Set both configs as profiles
2. Enable **Auto Reconnect**
3. Router switches if primary fails

## OpenWrt Generic Setup

For non-GL.iNet OpenWrt routers:

### Install WireGuard

```bash
# SSH to router
ssh root@192.168.1.1

# Install packages
opkg update
opkg install wireguard-tools luci-app-wireguard

# Reboot
reboot
```

### Configure Interface

1. Go to **Network** → **Interfaces**
2. Click **Add new interface**
3. **Name:** wg0
4. **Protocol:** WireGuard VPN
5. **Private Key:** (from generated config)
6. Click **Create Interface**

**General Settings:**
- **Public Key:** (server public key)
- **Endpoint:** (server IP:port)
- **Persistent Keep Alive:** 25

**Allowed IPs:**
- Add: `0.0.0.0/0`
- Add: `::/0`

**Firewall:**
- Assign to zone: **wan**

### Configure DNS

1. Go to **Network** → **DHCP and DNS**
2. **DNS forwardings:** 10.2.0.2
3. Save and Apply

### Configure Routing

1. Go to **Network** → **Routing**
2. Add route:
   - **Target:** 0.0.0.0/0
   - **Interface:** wg0
   - **Metric:** 10

## Troubleshooting

### Router Cannot Connect

**Check 1: Firewall**
- Ensure UDP ports 51820 or 443 not blocked
- Try alternate port in configuration

**Check 2: Internet connectivity**
- Verify router has active WAN connection
- Test without VPN first

**Check 3: Configuration**
- Verify all fields copied correctly
- Check endpoint matches server IP/domain

### Connected But No Internet

**Issue:** VPN connected but devices can't access internet

**Solutions:**

1. **Check DNS:**
   - Router DNS should be 10.2.0.2
   - Not public resolver

2. **Check routing:**
   - Ensure VPN is default gateway
   - Policy routing may be blocking

3. **Restart services:**
   ```bash
   # SSH to router
   /etc/init.d/network restart
   ```

### Slow Performance

**Solutions:**

1. **Enable hardware offloading:**
   - Some routers support WireGuard offload
   - Check router specs and enable if available

2. **Reduce MTU:**
   - In WireGuard config, add: `MTU = 1380`
   - Lower values if still slow

3. **Check router CPU:**
   - Lower-end routers may struggle with encryption
   - Consider upgrading to faster model

### Quest Won't Connect to Router

**Issue:** Quest can't connect to router Wi-Fi

**Solutions:**

1. **Check Wi-Fi band:**
   - Quest supports 2.4GHz and 5GHz
   - Some settings may disable one band

2. **Check Wi-Fi password:**
   - Verify password is correct
   - Special characters may cause issues

3. **Reset Wi-Fi settings:**
   - Router: Reset Wi-Fi to defaults
   - Quest: Forget network and reconnect

## Advanced Features

### Guest Network Without VPN

Create guest SSID that bypasses VPN:

1. Go to **Network** → **Guest Network**
2. Enable Guest Wi-Fi
3. **VPN:** Disabled for guest network
4. Guests use regular internet, main SSID uses VPN

### VPN on Demand

Schedule VPN activation:

1. Go to **System** → **Scheduled Tasks**
2. Add cron job to enable VPN at specific times
3. Example: VPN on during work hours, off at night

### Multi-Hop VPN (Experimental)

Chain VPN through router then Quest:

1. Router connects to VPN (west)
2. Quest connects to different VPN (east)
3. Double encryption, double latency

**Not recommended for Quest due to performance impact**

## Comparison: Router vs On-Device VPN

| Feature | Router VPN | On-Device VPN |
|---------|------------|---------------|
| Setup | One-time | Per device |
| Switching | Physical location | In-app toggle |
| Performance | Router-dependent | Native |
| Flexibility | All or nothing | Per-app control |
| Portability | Requires router | Device-only |
| Cost | Router purchase | Free |

## Recommended Use Cases

**Choose Router VPN when:**
- Traveling with multiple devices
- Want set-and-forget solution
- Hotel/public Wi-Fi usage
- Multiple family members using Quest

**Choose On-Device VPN when:**
- Single device usage
- Need per-app control
- Frequently switch regions
- Maximum portability

## Best Practices

1. **Keep firmware updated:**
   - Check GL.iNet admin panel for updates
   - Update monthly for security patches

2. **Use strong admin password:**
   - Change default router password
   - Use 20+ character password

3. **Enable router firewall:**
   - Keep enabled even with VPN
   - Defense in depth

4. **Monitor connection:**
   - Check router logs regularly
   - Set up email alerts for disconnections

5. **Test failover:**
   - Periodically test east region
   - Ensure you can switch if needed

## Support

- **Main README:** [../README.md](../README.md)
- **Quest on-device setup:** [QUEST_SIDELOAD.md](QUEST_SIDELOAD.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Enjoy effortless VPN connectivity for your Quest!**
