# Split Tunneling Strategies

Guide to configuring split tunneling for optimal Quest VPN performance.

## What is Split Tunneling?

**Full Tunnel:** All traffic goes through VPN
- Maximum privacy
- Simple configuration
- May increase latency for local services

**Split Tunnel:** Only specific traffic through VPN
- Optimized performance
- LAN access preserved
- Requires careful configuration

## When to Use Each Mode

### Full Tunnel Use Cases

- **Maximum privacy:** All traffic encrypted
- **Public Wi-Fi:** Protect all connections
- **Geo-unblocking:** Access region-restricted content
- **Simplicity:** No configuration needed

### Split Tunnel Use Cases

- **Performance:** Lower latency for local apps
- **LAN access:** Use local file shares, Plex, etc.
- **Selective privacy:** Only sensitive apps via VPN
- **Bandwidth:** Reduce VPN server load

## Network-Level Split Tunneling

Configure at tunnel level using `AllowedIPs`.

### Example Configurations

**Full Tunnel (Default):**
```ini
[Interface]
Address = 10.2.0.10/32
DNS = 10.2.0.2

[Peer]
AllowedIPs = 0.0.0.0/0, ::/0
```

**Split Tunnel - Exclude RFC1918 Private Networks:**
```ini
[Interface]
Address = 10.2.0.10/32
DNS = 10.2.0.2

[Peer]
# Routes everything except:
# 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
AllowedIPs = 0.0.0.0/5, 8.0.0.0/7, 11.0.0.0/8, 12.0.0.0/6, 16.0.0.0/4, 32.0.0.0/3, 64.0.0.0/2, 128.0.0.0/3, 160.0.0.0/5, 168.0.0.0/6, 172.0.0.0/12, 172.32.0.0/11, 172.64.0.0/10, 172.128.0.0/9, 173.0.0.0/8, 174.0.0.0/7, 176.0.0.0/4, 192.0.0.0/9, 192.128.0.0/11, 192.160.0.0/13, 192.169.0.0/16, 192.170.0.0/15, 192.172.0.0/14, 192.176.0.0/12, 192.192.0.0/10, 193.0.0.0/8, 194.0.0.0/7, 196.0.0.0/6, 200.0.0.0/5, 208.0.0.0/4
```

**Split Tunnel - Only Route Specific Networks:**
```ini
[Interface]
Address = 10.2.0.10/32
DNS = 10.2.0.2

[Peer]
# Only route streaming services (example IPs)
AllowedIPs = 208.67.222.0/24, 1.1.1.0/24
```

## Application-Level Split Tunneling

WireGuard Android supports per-app rules.

### Configuration

In WireGuard app on Quest:

1. Edit tunnel
2. Scroll to **Applications**
3. Choose mode:
   - **Exclude:** All apps use VPN except selected
   - **Include:** Only selected apps use VPN

### Recommended Exclude List

**System Apps to Exclude:**
- Meta Home (Quest interface)
- Meta TV (local streaming)
- Settings
- File Manager
- Gallery

**Local Network Apps:**
- Plex (if server is local)
- File share apps
- Casting apps
- Local game streaming (Virtual Desktop, ALVR)

**Keep on VPN:**
- Oculus Browser
- YouTube VR
- Netflix VR
- Any apps requiring privacy

### Recommended Include List

If using Include mode (only selected apps use VPN):

**Privacy-Critical Apps:**
- Oculus Browser
- YouTube VR
- Any video streaming apps
- Social media apps
- Shopping apps

**Performance-Sensitive Apps:**
- Leave out: VR games, local streaming, system apps

## Hybrid Strategies

### Strategy 1: LAN Access + VPN Privacy

**Goal:** Access local network, protect internet traffic

**Configuration:**
```bash
# Generate split tunnel config
./scripts/gen-peer.sh quest-hybrid west split
```

**Modify AllowedIPs to exclude your LAN:**
```ini
# If your home network is 192.168.1.0/24
# Exclude it from VPN routing
AllowedIPs = 0.0.0.0/5, 8.0.0.0/7, ... [long list excluding 192.168.1.0/24]
```

**Use Case:**
- Access local Plex server at 192.168.1.100
- All internet traffic via VPN
- Ad blocking still works

### Strategy 2: VPN for Browsers Only

**Goal:** Only web traffic via VPN, everything else direct

**Configuration:**
- Network-level: Full tunnel
- App-level: Include mode
- Add: Oculus Browser only

**Use Case:**
- Web privacy and ad blocking
- Low latency for VR games
- Local app access

### Strategy 3: Region-Specific Routing

**Goal:** Route specific services through VPN, rest direct

**Configuration:**
```bash
# Generate config with specific IPs only
```

**Modify AllowedIPs:**
```ini
# Only route Netflix, Hulu, streaming services
# (Example IPs - update with actual ranges)
AllowedIPs = 23.0.0.0/8, 54.0.0.0/8, 208.67.222.0/24
```

**Use Case:**
- Geo-unblock streaming services
- Everything else uses regular internet
- Lower latency for most apps

## DNS Considerations

### DNS with Full Tunnel

```ini
DNS = 10.2.0.2  # AdGuard in VPN
```
- All DNS queries via VPN
- Ad blocking works
- No DNS leaks

### DNS with Split Tunnel

**Option 1: VPN DNS for all (recommended)**
```ini
DNS = 10.2.0.2
```
- Ad blocking works for all apps
- DNS queries encrypted
- May cause issues if VPN is down

**Option 2: Local DNS**
```ini
DNS = 192.168.1.1  # Your router
```
- Works without VPN
- No ad blocking
- Potential DNS leaks

**Option 3: Hybrid**
```ini
DNS = 10.2.0.2, 1.1.1.1
```
- Primary: VPN DNS (ad blocking)
- Fallback: Cloudflare
- Compromise between privacy and reliability

## Testing Your Configuration

### Verify VPN Routes

```bash
# On computer (not Quest directly)
# Check what routes are active

# If split tunnel excludes 192.168.0.0/16
ping 192.168.1.1  # Should use local route
ping 8.8.8.8      # Should use VPN route
```

### Check IP Leaks

1. Visit: `https://ipleak.net/`
2. Check:
   - **Your IP:** Should be VPN server (if that traffic routes through VPN)
   - **DNS Addresses:** Should be VPN server only
   - **WebRTC:** Should not leak local IP

### Verify LAN Access

If excluding local network:
1. Try to ping local devices
2. Access local web services (router admin, Plex)
3. Should work without disconnecting VPN

## Performance Impact

### Full Tunnel

- **Latency:** +20-50ms depending on region
- **Throughput:** 80-95% of VPN server bandwidth
- **Battery:** Minimal impact

### Split Tunnel

- **Latency:** +0ms for excluded apps
- **Throughput:** Full local bandwidth for excluded traffic
- **Battery:** Slightly better (less encryption)

## Common Patterns

### Pattern 1: Privacy-First

```
Network: Full tunnel (0.0.0.0/0)
App: Exclude system apps only
Result: Maximum privacy, good performance
```

### Pattern 2: Performance-First

```
Network: Split tunnel (exclude RFC1918)
App: Include browsers only
Result: Maximum performance, selective privacy
```

### Pattern 3: Hybrid

```
Network: Split tunnel (exclude LAN)
App: Exclude local apps
Result: LAN access + internet privacy
```

## Troubleshooting

### LAN Access Not Working

**Issue:** Can't access local network devices

**Check:**
1. Verify AllowedIPs excludes your LAN subnet
2. Ensure DNS is set correctly (may need local DNS)
3. Check firewall isn't blocking LAN traffic

### Some Apps Not Working

**Issue:** Certain apps fail with split tunnel

**Solutions:**
1. Add app to exclusion list
2. Check if app requires specific IPs (add to AllowedIPs)
3. Try full tunnel to identify issue

### DNS Not Resolving

**Issue:** DNS fails for excluded apps

**Solution:**
```ini
# Add local DNS as secondary
DNS = 10.2.0.2, 192.168.1.1
```

## Advanced: Custom CIDR Lists

### Exclude Specific Countries

Use CIDR lists to exclude traffic to specific countries:

```bash
# Example: Exclude US IP ranges
# (Keep US traffic direct, route international through VPN)
```

**Note:** This requires extensive IP lists and is complex. Use network-level routing or router-based solutions for this use case.

### Exclude Specific Services

Maintain lists of IP ranges for specific services:

```bash
# Exclude Meta services (example)
# AllowedIPs = [everything except Meta CDN IPs]
```

## Best Practices

1. **Start with full tunnel**
   - Test everything works
   - Then optimize with split tunneling

2. **Document your config**
   - Note what's excluded and why
   - Makes troubleshooting easier

3. **Test thoroughly**
   - Verify privacy (IP leak tests)
   - Check LAN access
   - Test all critical apps

4. **Keep it simple**
   - Complex configs are error-prone
   - Use app-level splitting when possible

5. **Regular audits**
   - Periodically verify split tunnel still needed
   - Update exclusions as apps change

## Recommendations by Use Case

**Quest for VR Gaming:**
- Network: Split tunnel (exclude LAN)
- App: Exclude system apps, game launchers
- Route: Browser via VPN

**Quest for Media Streaming:**
- Network: Full tunnel
- App: Default (all apps)
- Best privacy for streaming

**Quest for Development:**
- Network: Split tunnel (exclude LAN + dev networks)
- App: Exclude dev tools, include browsers
- LAN access for testing

**Quest for Travel:**
- Network: Full tunnel
- App: Exclude only critical system apps
- Maximum protection on public Wi-Fi

## Support

- **Main guide:** [QUICKSTART.md](../QUICKSTART.md)
- **Quest setup:** [QUEST_SIDELOAD.md](QUEST_SIDELOAD.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Optimize your VPN for the perfect balance of privacy and performance!**
