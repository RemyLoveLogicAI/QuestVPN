# Troubleshooting Guide

## Common Issues and Solutions

### WireGuard Connection Issues

#### Problem: Can't Connect to VPN

**Symptoms:**
- Tunnel shows "inactive" or "connecting..."
- No handshake timestamp
- No internet access

**Solutions:**

1. **Check server is running:**
   ```bash
   ssh user@vpn-server
   docker ps
   ```
   Ensure `wg-easy-west` or `wg-easy-east` is running.

2. **Verify endpoint is reachable:**
   ```bash
   # From Quest via ADB
   adb shell ping vpn-west.example.com
   ```

3. **Check firewall:**
   ```bash
   # On server
   sudo ufw status
   # Ensure port 51820/udp is allowed
   ```

4. **Verify peer is added:**
   ```bash
   # On server
   docker exec wg-easy-west wg show
   # Look for your peer's public key
   ```

5. **Regenerate peer config:**
   ```bash
   /opt/questvpn/scripts/revoke-peer.sh old-config west
   /opt/questvpn/scripts/gen-peer.sh new-config west
   /opt/questvpn/scripts/export-peer.sh new-config
   ```

#### Problem: Connection Drops Frequently

**Solutions:**

1. **Adjust PersistentKeepalive:**
   Edit your config file, change to a lower value:
   ```
   PersistentKeepalive = 15
   ```

2. **Check MTU:**
   ```bash
   # On server
   /opt/questvpn/scripts/mtu-autotune.sh wg0 west
   ```
   Update your client config with the optimal MTU.

3. **Network stability:**
   - Switch from WiFi 5GHz to 2.4GHz (better range)
   - Move closer to WiFi router
   - Check for interference

#### Problem: Slow Performance

**Solutions:**

1. **Run MTU auto-tune:**
   ```bash
   /opt/questvpn/scripts/mtu-autotune.sh wg0 west
   ```

2. **Check server load:**
   ```bash
   /opt/questvpn/scripts/healthcheck.sh west
   ```

3. **Try different region:**
   - If using west, try east (or vice versa)
   - Choose region closest to your physical location

4. **Reduce encryption overhead:**
   Not recommended, but if desperate:
   ```
   # In peer config, remove PersistentKeepalive
   # Only for testing
   ```

5. **Use split-tunnel:**
   See [split-tunnel.md](split-tunnel.md) to route only necessary traffic through VPN.

### DNS and AdGuard Issues

#### Problem: No DNS Resolution

**Symptoms:**
- Can ping IPs but not domain names
- Websites don't load
- "DNS probe failed" errors

**Solutions:**

1. **Check DNS in WireGuard config:**
   ```
   DNS = 10.2.0.2
   ```
   Should point to AdGuard container.

2. **Verify AdGuard is running:**
   ```bash
   docker ps | grep adguard
   ```

3. **Check AdGuard status:**
   ```bash
   docker exec adguard-west wget -q --spider http://localhost:3000
   echo $?  # Should be 0
   ```

4. **Test DNS directly:**
   ```bash
   # From Quest
   adb shell nslookup google.com 10.2.0.2
   ```

5. **Fallback DNS:**
   Temporarily use public DNS:
   ```
   DNS = 10.2.0.2, 1.1.1.1
   ```

#### Problem: AdGuard Web UI Not Accessible

**Solutions:**

1. **Check port forwarding:**
   ```bash
   curl -I http://vpn-server:3000
   ```

2. **Check firewall:**
   ```bash
   sudo ufw allow 3000/tcp
   ```

3. **Check container logs:**
   ```bash
   docker logs adguard-west
   ```

4. **Restart container:**
   ```bash
   cd /opt/questvpn/docker
   docker-compose restart adguard
   ```

#### Problem: Ads Still Showing

**Solutions:**

1. **Configure AdGuard upstream DNS:**
   - Open AdGuard UI (http://vpn-server:3000)
   - Settings → DNS Settings
   - Upstream DNS: `10.2.0.3` (Unbound)
   - Bootstrap DNS: `1.1.1.1`

2. **Update blocklists:**
   - Filters → DNS Blocklists
   - Add popular lists (AdGuard DNS filter, EasyList)
   - Update filters

3. **Verify DNS is being used:**
   ```bash
   adb shell nslookup doubleclick.net 10.2.0.2
   # Should return 0.0.0.0 if blocked
   ```

### Quest Sideloading Issues

#### Problem: APK Installation Failed

**Solutions:**

1. **Check developer mode:**
   - Quest mobile app → Devices → Developer Mode → ON
   - May require developer account at developer.oculus.com

2. **Re-approve USB debugging:**
   - Disconnect and reconnect USB
   - Check for approval prompt in headset

3. **Try different APK variant:**
   - Download arm64-v8a instead of armeabi-v7a
   - Or vice versa

4. **Clear ADB cache:**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

#### Problem: WireGuard Not in Library

**Solutions:**

1. **Check Unknown Sources:**
   - Library → Select dropdown (top right)
   - Choose "Unknown Sources"
   - WireGuard should appear here

2. **Reinstall:**
   ```bash
   adb uninstall com.wireguard.android
   adb install wireguard.apk
   ```

### Ansible Deployment Issues

#### Problem: Ansible Playbook Fails

**Solutions:**

1. **Check SSH connectivity:**
   ```bash
   ansible all -i inventory.ini -m ping
   ```

2. **Verify Python on remote:**
   ```bash
   ssh user@vpn-server python3 --version
   ```

3. **Run with verbose output:**
   ```bash
   ansible-playbook -i inventory.ini deploy.yml -vvv
   ```

4. **Check sudo permissions:**
   ```bash
   ssh user@vpn-server sudo -v
   ```

#### Problem: Docker Compose Won't Start

**Solutions:**

1. **Check Docker service:**
   ```bash
   sudo systemctl status docker
   sudo systemctl start docker
   ```

2. **Verify .env file:**
   ```bash
   cat /opt/questvpn/docker/.env
   # Ensure all variables are set
   ```

3. **Check logs:**
   ```bash
   cd /opt/questvpn/docker
   docker-compose logs
   ```

4. **Recreate containers:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Firewall and Security Issues

#### Problem: UFW Blocks Legitimate Traffic

**Solutions:**

1. **Check UFW rules:**
   ```bash
   sudo ufw status numbered
   ```

2. **Add missing rules:**
   ```bash
   sudo ufw allow 51820/udp  # WireGuard
   sudo ufw allow 443/tcp    # wg-easy UI
   sudo ufw allow 22/tcp     # SSH
   ```

3. **Check rule order:**
   ```bash
   # Delete incorrect rule
   sudo ufw delete <rule-number>
   # Re-add in correct order
   ```

#### Problem: fail2ban Blocks Legitimate IPs

**Solutions:**

1. **Check banned IPs:**
   ```bash
   sudo fail2ban-client status sshd
   ```

2. **Unban IP:**
   ```bash
   sudo fail2ban-client set sshd unbanip <ip-address>
   ```

3. **Whitelist IP:**
   ```bash
   # Edit /etc/fail2ban/jail.local
   [DEFAULT]
   ignoreip = 127.0.0.1/8 ::1 <your-ip>
   
   sudo systemctl restart fail2ban
   ```

### Network and Connectivity Issues

#### Problem: Can't Reach VPN Server

**Solutions:**

1. **Verify server is online:**
   ```bash
   ping vpn-west.example.com
   ```

2. **Check DNS resolution:**
   ```bash
   nslookup vpn-west.example.com
   ```

3. **Update DDNS if using dynamic IP:**
   ```bash
   /opt/questvpn/scripts/cf-ddns.sh west
   ```

4. **Check ISP blocking:**
   - Try different port (configure in docker-compose.yml)
   - Use TCP instead of UDP (less ideal)

#### Problem: Split Tunnel Not Working

**Solutions:**

1. **Verify AllowedIPs:**
   ```bash
   # Check current config
   adb shell wg show wg0
   ```

2. **Test routing:**
   ```bash
   # Should show VPN IP
   adb shell curl https://ipinfo.io/ip
   
   # If excluding local, should show real IP when accessing local device
   ping 192.168.1.1
   ```

3. **Recalculate split-tunnel IPs:**
   Use https://www.procustodibus.com/blog/2021/03/wireguard-allowedips-calculator/

### ADB Over WiFi Issues

#### Problem: Can't Connect via WiFi

**Solutions:**

1. **Re-enable TCP mode:**
   ```bash
   # Connect via USB first
   adb usb
   adb tcpip 5555
   adb connect <quest-ip>:5555
   ```

2. **Check Quest IP:**
   ```bash
   # Quest Settings → WiFi → Connected network → Advanced
   # Or via USB:
   adb shell ip addr show wlan0
   ```

3. **Verify network connectivity:**
   ```bash
   ping <quest-ip>
   ```

4. **Check firewall on computer:**
   ```bash
   # Linux
   sudo ufw allow from <quest-ip> to any port 5037
   
   # Windows
   # Add firewall rule for ADB (port 5037)
   ```

### Performance Optimization

#### Problem: High Latency

**Solutions:**

1. **Check server location:**
   - Use region closest to you
   - Consider deploying additional region

2. **Optimize MTU:**
   ```bash
   /opt/questvpn/scripts/mtu-autotune.sh wg0 west
   ```

3. **Reduce keepalive:**
   ```
   PersistentKeepalive = 25
   # Try 20 or 15
   ```

4. **Check server resources:**
   ```bash
   /opt/questvpn/scripts/healthcheck.sh west
   ```

#### Problem: High Bandwidth Usage

**Solutions:**

1. **Use split-tunnel:**
   Only route necessary traffic through VPN.

2. **Disable PersistentKeepalive:**
   ```
   # Remove this line from config
   PersistentKeepalive = 25
   ```
   Note: May cause connection drops if behind NAT.

3. **Optimize AdGuard:**
   - Disable query logging
   - Reduce blocklist size

## Getting Help

### Collect Debug Information

Before asking for help, gather this information:

```bash
# Server side
/opt/questvpn/scripts/healthcheck.sh west > healthcheck.log

docker-compose logs > docker-logs.txt

sudo dmesg | grep wireguard > kernel-logs.txt

# Client side (Quest via ADB)
adb shell wg show > client-wg-status.txt

adb logcat -d | grep -i wireguard > client-logs.txt
```

### Support Channels

- **GitHub Issues**: https://github.com/RemyLoveLogicAI/QuestVPN/issues
- **Discussions**: https://github.com/RemyLoveLogicAI/QuestVPN/discussions
- **WireGuard Docs**: https://www.wireguard.com/quickstart/

### Additional Resources

- [Quickstart Guide](quickstart.md)
- [Quest Sideload Guide](quest-sideload.md)
- [Split Tunnel Configuration](split-tunnel.md)
- [Always-On ADB](always-on-adb.md)

## Diagnostic Commands

### Server Diagnostics

```bash
# Check all services
docker ps

# Check WireGuard peers
docker exec wg-easy-west wg show

# Check network
ip addr show
ip route

# Check firewall
sudo ufw status verbose

# Check fail2ban
sudo fail2ban-client status

# Check system resources
top
df -h
free -h
```

### Client Diagnostics (Quest)

```bash
# Via ADB
adb shell wg show
adb shell ip addr
adb shell ip route
adb shell ping 10.2.0.2
adb shell nslookup google.com 10.2.0.2
```

## Emergency Recovery

### Server Not Responding

```bash
# Hard reset containers
cd /opt/questvpn/docker
docker-compose down
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Lost Access to Server

```bash
# If locked out by fail2ban/ufw
# Access via cloud provider console
# Or reboot server via control panel
```

### Reset WireGuard Configuration

```bash
# Backup first
cp -r /opt/questvpn/docker/wg-easy /opt/questvpn/docker/wg-easy.backup

# Remove and regenerate
docker-compose down
rm -rf /opt/questvpn/docker/wg-easy
docker-compose up -d

# Regenerate all peer configs
```
