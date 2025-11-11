# Split Tunnel Configuration

## Overview

Split tunneling allows you to route only specific traffic through the VPN while letting other traffic use your normal internet connection. This is useful for:

- **Local Network Access**: Access devices on your home network
- **Performance**: Stream local media without VPN overhead
- **Selective Privacy**: Only protect sensitive apps/traffic
- **Bandwidth**: Reduce VPN server load

## Understanding AllowedIPs

The `AllowedIPs` parameter in WireGuard controls which traffic goes through the VPN tunnel.

### Full Tunnel (Default)
```
AllowedIPs = 0.0.0.0/0
```
Routes ALL traffic through VPN.

### Split Tunnel Examples

#### 1. VPN Only for Specific Subnets

Route only traffic to specific networks through VPN:

```
AllowedIPs = 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
```

This routes:
- Private networks through VPN
- Everything else direct

#### 2. Exclude Local Network

Route everything EXCEPT your local network:

```
AllowedIPs = 0.0.0.0/1, 128.0.0.0/1
# Exclude local: 192.168.1.0/24
```

For Quest, to exclude local network (192.168.1.0/24):

```
AllowedIPs = 0.0.0.0/5, 8.0.0.0/7, 11.0.0.0/8, 12.0.0.0/6, 16.0.0.0/4, 32.0.0.0/3, 64.0.0.0/2, 128.0.0.0/3, 160.0.0.0/5, 168.0.0.0/6, 172.0.0.0/12, 172.32.0.0/11, 172.64.0.0/10, 172.128.0.0/9, 173.0.0.0/8, 174.0.0.0/7, 176.0.0.0/4, 192.0.0.0/9, 192.128.0.0/11, 192.160.0.0/13, 192.169.0.0/16, 192.170.0.0/15, 192.172.0.0/14, 192.176.0.0/12, 192.192.0.0/10, 193.0.0.0/8, 194.0.0.0/7, 196.0.0.0/6, 200.0.0.0/5, 208.0.0.0/4, 224.0.0.0/3
```

**Easier method**: Use a split-tunnel calculator like https://www.procustodibus.com/blog/2021/03/wireguard-allowedips-calculator/

#### 3. VPN Only for Specific Domains (DNS-based)

For domain-based routing, you need additional tools. On Android/Quest, you can use apps like:
- **NetGuard** (with WireGuard integration)
- **AFWall+** (requires root)

## Quest-Specific Configurations

### Configuration 1: Privacy Browsing Only

Route only web browsing through VPN, keep local apps direct:

```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.2.0.X/32
DNS = 10.2.0.2

[Peer]
PublicKey = <server-public-key>
Endpoint = vpn-west.example.com:51820
AllowedIPs = 0.0.0.0/1, 128.0.0.0/1
PersistentKeepalive = 25
```

Then in WireGuard app, enable "Applications" and select only browsers.

### Configuration 2: Keep Quest Services Local

Exclude Meta services from VPN:

1. Use split AllowedIPs (exclude Meta IPs)
2. Use "Exclude applications" in WireGuard settings
3. Add: `com.oculus.*`, `com.facebook.*`

### Configuration 3: LAN Access with VPN

Allow local network access while using VPN:

```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.2.0.X/32
DNS = 10.2.0.2

[Peer]
PublicKey = <server-public-key>
Endpoint = vpn-west.example.com:51820
# Exclude 192.168.0.0/16 (adjust to your local network)
AllowedIPs = 0.0.0.0/5, 8.0.0.0/7, 11.0.0.0/8, 12.0.0.0/6, 16.0.0.0/4, 32.0.0.0/3, 64.0.0.0/2, 128.0.0.0/2, 193.0.0.0/8, 194.0.0.0/7, 196.0.0.0/6, 200.0.0.0/5, 208.0.0.0/4, 224.0.0.0/3
PersistentKeepalive = 25
```

## Per-Application Split Tunneling

WireGuard for Android supports per-app tunneling:

### Include Only Specific Apps

1. Open WireGuard app on Quest
2. Edit your tunnel configuration
3. Tap "Applications"
4. Select "Include only selected applications"
5. Choose apps that should use VPN (e.g., browsers, specific games)

### Exclude Specific Apps

1. Same as above, but select "Exclude selected applications"
2. Choose apps that should bypass VPN (e.g., local streaming apps)

## Common Split-Tunnel Scenarios

### Scenario 1: Gaming with Low Latency

**Goal**: Route only web browsing through VPN, keep games direct

**Config**:
```
AllowedIPs = 0.0.0.0/1, 128.0.0.0/1
```

**WireGuard App**: Include only browser apps

### Scenario 2: Streaming Local Media

**Goal**: Access Plex/Jellyfin on local network, everything else through VPN

**Config**:
```
# Exclude your local network (e.g., 192.168.1.0/24)
AllowedIPs = <calculated split-tunnel IPs>
```

**OR** use per-app exclusion for media apps

### Scenario 3: Work VPN Access

**Goal**: Access work resources through VPN, personal apps direct

**Config**:
```
# Only route work subnet
AllowedIPs = 10.50.0.0/16
```

## Testing Split Tunnel

### Verify What Goes Through VPN

1. Enable VPN tunnel
2. Visit https://www.whatismyip.com/ in Quest Browser
3. If split tunnel is working:
   - Included traffic shows VPN IP
   - Excluded traffic shows real IP

### Check Routing Table

Via ADB:
```bash
adb shell ip route
```

Look for routes pointing to WireGuard interface (usually `wg0`).

### Test Local Network Access

With VPN enabled:
```bash
# From computer, SSH to Quest
adb connect <quest-local-ip>

# From Quest, ping local device
adb shell ping 192.168.1.1
```

If local access works, split tunnel is configured correctly.

## Troubleshooting

### Can't Access Local Devices

- Verify local network is excluded from `AllowedIPs`
- Check if "Block connections without VPN" is enabled (disable it)
- Ensure local devices are on same subnet

### Some Sites Don't Load

- DNS might be routing incorrectly
- Try using split DNS (VPN DNS for some, local DNS for others)
- Or use `DNS = 10.2.0.2, 1.1.1.1`

### VPN Doesn't Route Anything

- Check `AllowedIPs` isn't too restrictive
- Verify server-side routing is enabled
- Check firewall rules on server

## Advanced: Policy-Based Routing

For complex routing scenarios, consider:

1. **Multiple VPN Configs**: Create separate tunnels for different purposes
2. **VPN Chaining**: Route Quest → VPN1 → VPN2 for specific apps
3. **External Router**: Configure split-tunnel on your router instead

## Tools and Resources

- **AllowedIPs Calculator**: https://www.procustodibus.com/blog/2021/03/wireguard-allowedips-calculator/
- **CIDR Calculator**: https://www.ipaddressguide.com/cidr
- **WireGuard Docs**: https://www.wireguard.com/#conceptual-overview

## Performance Impact

| Configuration | Performance | Privacy | Complexity |
|--------------|-------------|---------|------------|
| Full Tunnel | Medium | High | Low |
| Exclude Local | Medium-High | High | Medium |
| Include Apps Only | High | Medium | Low |
| Custom AllowedIPs | High | Custom | High |

Choose based on your priorities!

## Next Steps

- [Always-On ADB](always-on-adb.md) - Enable wireless debugging
- [Troubleshooting](troubleshooting.md) - Common issues
- [Quickstart](quickstart.md) - Back to main guide
