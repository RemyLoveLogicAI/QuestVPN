# Troubleshooting Guide

Comprehensive solutions for common QuestVPN issues.

## Table of Contents

1. [Connection Issues](#connection-issues)
2. [Performance Problems](#performance-problems)
3. [DNS and Leak Issues](#dns-and-leak-issues)
4. [Server Issues](#server-issues)
5. [Quest-Specific Issues](#quest-specific-issues)
6. [Advanced Diagnostics](#advanced-diagnostics)

---

## Connection Issues

### Cannot Connect to VPN

**Symptom:** WireGuard shows "Connecting..." but never connects

**Check 1: Server reachability**
```bash
# Test server connectivity
./scripts/healthcheck.sh west

# Ping server
ping <vpn-server-ip>
```

**Check 2: Ports blocked**
- UDP port 51820 may be blocked
- Try alternate port 443:
  ```ini
  [Peer]
  Endpoint = <server>:443
  ```

**Check 3: Firewall rules**
```bash
# SSH to server
ssh root@<server-ip>

# Check UFW status
ufw status verbose

# Should allow:
# 51820/udp ALLOW IN
# 443/udp ALLOW IN
```

**Check 4: Server running**
```bash
# Check Docker containers
ssh root@<server-ip> "docker ps"

# Should show:
# wg-easy-west
# adguard-west
# unbound-west
```

### Connects But Disconnects Immediately

**Symptom:** Connection established then drops

**Check 1: PersistentKeepalive**
```ini
[Peer]
PersistentKeepalive = 25  # Should be set

# If not set, add it
```

**Check 2: DNS issues**
```ini
# Ensure DNS is set
DNS = 10.2.0.2  # Must be VPN DNS
```

**Check 3: Server logs**
```bash
# View WireGuard logs
ssh root@<server-ip> "docker logs wg-easy-west"

# Look for error messages
```

### Intermittent Disconnections

**Symptom:** Connection drops randomly

**Check 1: Network stability**
- Switch Wi-Fi networks
- Try 5GHz instead of 2.4GHz
- Move closer to router

**Check 2: Keepalive too high**
```ini
# Lower keepalive (more frequent pings)
PersistentKeepalive = 15  # From 25
```

**Check 3: MTU issues**
```bash
# Re-run MTU detection
./scripts/mtu-autotune.sh west

# Update config with result
```

---

## Performance Problems

### Slow Speeds

**Symptom:** VPN connection is slow

**Check 1: Server bandwidth**
```bash
# Test without VPN first
# Visit: https://fast.com/

# Then test with VPN
# Compare results
```

**Check 2: MTU optimization**
```bash
# Run MTU auto-tune
./scripts/mtu-autotune.sh west

# Apply recommended MTU to config
```

**Check 3: Server load**
```bash
# Check server CPU/RAM
ssh root@<server-ip> "htop"

# High CPU? Server may be overloaded
```

**Check 4: Network congestion**
- Test at different times of day
- Peak hours may show slowdowns
- Try alternate region (east vs west)

**Check 5: Split tunneling**
- Use split tunnel for performance apps
- See [SPLIT_TUNNEL.md](SPLIT_TUNNEL.md)

### High Latency

**Symptom:** Lag in VR games or streaming

**Check 1: Geographic distance**
```bash
# Test ping to server
ping <vpn-server-ip>

# Should be <100ms
# If higher, try other region
```

**Check 2: ISP routing**
```bash
# Check route to server
traceroute <vpn-server-ip>

# Look for:
# - Many hops (>15)
# - High latency hops
# - Packet loss
```

**Check 3: WireGuard config**
```ini
# Ensure these are set optimally
PersistentKeepalive = 25
MTU = 1420  # Or your tested value
```

**Solution: Use closer region**
- West for US West Coast, Asia-Pacific
- East for US East Coast, Europe

### Packet Loss

**Symptom:** Video stuttering, game lag

**Check 1: Test packet loss**
```bash
# Ping test with count
ping -c 100 8.8.8.8

# Check statistics:
# 0% loss is ideal
# <1% is acceptable
# >5% indicates problem
```

**Check 2: MTU issues**
```bash
# Wrong MTU causes fragmentation
./scripts/mtu-autotune.sh west

# Apply result to config
```

**Check 3: Network quality**
- Switch Wi-Fi networks
- Try wired connection (if possible)
- Check ISP for outages

---

## DNS and Leak Issues

### DNS Not Resolving

**Symptom:** Cannot browse websites, "DNS not found" errors

**Check 1: DNS configuration**
```ini
# In WireGuard config
[Interface]
DNS = 10.2.0.2  # Must be set

# Not 8.8.8.8, 1.1.1.1, or other public DNS
```

**Check 2: AdGuard running**
```bash
# Check AdGuard status
ssh root@<server-ip> "docker ps | grep adguard"

# Should show running container
```

**Check 3: DNS chain**
```bash
# Test DNS resolution
./scripts/healthcheck.sh west

# Should pass DNS test
```

**Check 4: Unbound running**
```bash
# Check Unbound status
ssh root@<server-ip> "docker logs unbound-west"

# Should show successful startup
```

**Emergency fix: Use public DNS**
```ini
# Temporary workaround
DNS = 10.2.0.2, 1.1.1.1

# This works but loses ad-blocking
# Fix server-side DNS issue ASAP
```

### DNS Leaks Detected

**Symptom:** DNS leak test shows ISP DNS servers

**Check 1: Verify DNS setting**
```ini
# Must be VPN DNS only
DNS = 10.2.0.2

# Remove any other DNS entries
```

**Check 2: Disable Private DNS**
- Quest Settings → Network
- Advanced → Private DNS
- Set to "Off"

**Check 3: Test for leaks**
```
Visit: https://dnsleaktest.com/
Run: Standard Test

Should only show:
- Your VPN server location
- No ISP DNS servers
```

**Check 4: IPv6 leaks**
```ini
# If IPv6 enabled, ensure it's routed
AllowedIPs = 0.0.0.0/0, ::/0

# Not just: 0.0.0.0/0
```

### Ad Blocking Not Working

**Symptom:** Ads still showing despite AdGuard

**Check 1: DNS via AdGuard**
```ini
# Verify config
DNS = 10.2.0.2  # AdGuard IP

# Not public DNS
```

**Check 2: AdGuard config**
```bash
# Access AdGuard UI
http://<server-ip>:3000

# Check:
# - Protection enabled
# - Filters active
# - Upstream set to 10.2.0.3 (Unbound)
```

**Check 3: Test ad blocking**
```
Visit: https://ads-blocker.com/testing/

Most ads should be blocked
Some may still show (Acceptable Ads)
```

---

## Server Issues

### Server Not Responding

**Symptom:** Cannot SSH or access services

**Check 1: Server online**
```bash
# Ping server
ping <server-ip>

# If no response, check Hetzner console
```

**Check 2: SSH access**
```bash
# Try SSH
ssh root@<server-ip>

# If fails:
# - Check SSH key
# - Check Hetzner firewall
# - Check UFW rules
```

**Check 3: Services running**
```bash
# Check all containers
docker ps

# Should show:
# wg-easy, adguard, unbound
```

### Docker Containers Stopped

**Symptom:** Services not running

**Check logs:**
```bash
# View container logs
docker logs wg-easy-west
docker logs adguard-west
docker logs unbound-west

# Look for error messages
```

**Restart containers:**
```bash
# Restart all services
cd /opt/questvpn/west
docker compose restart

# Or restart individually
docker restart wg-easy-west
```

**Check resources:**
```bash
# Disk space
df -h

# Should have >10% free

# Memory
free -h

# Should have >100MB free
```

### Port Conflicts

**Symptom:** Container fails to start, port already in use

**Check ports:**
```bash
# List listening ports
netstat -tulpn

# Or
ss -tulpn
```

**Common conflicts:**
- Port 53: Another DNS service running
- Port 3000: Another web service

**Solutions:**
- Stop conflicting service
- Or change port in docker-compose.yml

### Certificate or Key Issues

**Symptom:** WireGuard fails to start, key errors

**Regenerate keys:**
```bash
# Use rotation script
./scripts/rotate-keys.sh west

# Follow instructions to update server
```

**Check permissions:**
```bash
# WireGuard config directory
ssh root@<server-ip>
ls -la /opt/questvpn/west/data/wg-easy

# Should be owned by proper user
```

---

## Quest-Specific Issues

### Cannot Install WireGuard APK

**Symptom:** Installation fails via SideQuest

**Check 1: Developer Mode**
- Ensure enabled in Meta app
- Verify via Quest Settings

**Check 2: USB Debugging**
- Reconnect Quest to computer
- Allow USB debugging when prompted
- Check "Always allow from this computer"

**Check 3: ADB connection**
```bash
# Test ADB
adb devices

# Should show Quest device
# If not, reinstall ADB or SideQuest
```

**Check 4: APK compatibility**
- Download latest APK from wireguard.com
- Some old APKs may not work on new firmware

### WireGuard App Crashes

**Symptom:** App closes unexpectedly

**Solution 1: Clear app data**
1. Quest Settings → Apps → Unknown Sources → WireGuard
2. Storage → Clear Data
3. Reopen app, re-import configs

**Solution 2: Reinstall app**
```bash
# Uninstall
adb uninstall com.wireguard.android

# Reinstall
adb install com.wireguard.android-latest.apk
```

**Solution 3: Check Quest OS**
- Update to latest Quest OS
- Old firmware may have bugs

### Cannot Scan QR Code

**Symptom:** QR scanner doesn't recognize code

**Solution 1: Adjust brightness**
- Increase computer screen brightness
- Make QR code larger (full screen)

**Solution 2: Print code**
- Print QR code on paper
- Scan from paper instead

**Solution 3: Use file import**
```bash
# Copy config to Quest
adb push peers/quest-user.west.conf /sdcard/Download/

# Import from file in WireGuard app
```

### Quest Firmware Update Breaks VPN

**Symptom:** VPN stopped working after Quest OS update

**Check 1: Always-On settings**
```bash
# Verify settings still present
adb shell settings get secure vpn_always_on

# If null, re-enable
```

**Check 2: WireGuard app**
- May need reinstall after major updates
- Re-sideload if needed

**Check 3: Config compatibility**
- Regenerate configs if needed
- Test with new config first

---

## Advanced Diagnostics

### Full Diagnostic Check

```bash
# 1. Test server connectivity
ping <server-ip>
traceroute <server-ip>

# 2. Test ports
nc -vzu <server-ip> 51820
nc -vzu <server-ip> 443

# 3. Run health check
./scripts/healthcheck.sh west

# 4. Test DNS
dig @10.2.0.2 example.com

# 5. Test MTU
./scripts/mtu-autotune.sh west

# 6. Check for leaks
# Visit: https://ipleak.net/
```

### Server-Side Diagnostics

```bash
# SSH to server
ssh root@<server-ip>

# Check Docker
docker ps
docker stats

# Check logs
journalctl -u docker -n 100
docker logs wg-easy-west --tail 100
docker logs adguard-west --tail 100

# Check network
ip addr show
ip route show
iptables -L -v -n

# Check WireGuard
wg show

# Check system resources
htop
df -h
free -h
```

### Network Capture (Advanced)

**On server:**
```bash
# Capture WireGuard traffic
tcpdump -i wg0 -w capture.pcap

# Analyze with Wireshark later
```

**On client:**
```bash
# Capture all traffic
tcpdump -i any -w client-capture.pcap

# Filter WireGuard
tcpdump -i any port 51820
```

### Common Error Codes

**Error: "Bad configuration"**
- Syntax error in .conf file
- Check all fields are valid

**Error: "Name resolution failure"**
- Endpoint hostname doesn't resolve
- Use IP address instead

**Error: "Destination address required"**
- AllowedIPs missing or invalid
- Should be: 0.0.0.0/0, ::/0

**Error: "Operation not permitted"**
- VPN permission not granted
- Check Quest VPN settings

---

## Getting Help

### Collect Information

Before asking for help, collect:

1. **System info:**
   - Quest model and firmware version
   - WireGuard app version
   - Server OS and region

2. **Configuration:**
   - Sanitized .conf file (remove keys!)
   - docker-compose.yml
   - .env file (remove passwords!)

3. **Logs:**
   - WireGuard server logs
   - AdGuard logs
   - Quest system logs (if possible)

4. **Test results:**
   - Health check output
   - DNS leak test results
   - Speed test results

### Where to Get Help

- **GitHub Issues:** [QuestVPN Issues](https://github.com/RemyLoveLogicAI/QuestVPN/issues)
- **Documentation:** Read all relevant guides
- **Search:** Check if issue already reported

### Reporting Issues

Include:
- Clear description of problem
- Steps to reproduce
- Expected vs actual behavior
- System information (above)
- What you've already tried

**Do NOT include:**
- Private keys
- Passwords
- Personal information

---

## Preventive Maintenance

### Regular Tasks

**Weekly:**
- Check VPN connectivity
- Verify ad blocking working
- Test both regions

**Monthly:**
- Update Quest OS
- Update WireGuard app
- Review server logs
- Check disk space

**Quarterly:**
- Rotate server keys
- Update passwords
- Review peer list
- Test disaster recovery

### Monitoring

Set up automated health checks:

```bash
# Add to cron
0 */6 * * * /path/to/scripts/healthcheck.sh west >> /var/log/questvpn.log
0 */6 * * * /path/to/scripts/healthcheck.sh east >> /var/log/questvpn.log
```

---

## Support Resources

- **Main README:** [../README.md](../README.md)
- **Quick Start:** [../QUICKSTART.md](../QUICKSTART.md)
- **Quest Setup:** [QUEST_SIDELOAD.md](QUEST_SIDELOAD.md)
- **Router Setup:** [ROUTER_CLIENT.md](ROUTER_CLIENT.md)
- **Split Tunnel:** [SPLIT_TUNNEL.md](SPLIT_TUNNEL.md)
- **MTU Tuning:** [MTU_TUNING.md](MTU_TUNING.md)
- **Security:** [../SECURITY.md](../SECURITY.md)

---

**Most issues can be resolved by checking the basics: connectivity, configuration, and DNS!**
