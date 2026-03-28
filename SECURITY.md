# Security Guidelines

This document outlines security best practices for deploying and maintaining your WireGuard VPN infrastructure.

## Overview

Security is a top priority for this project. The infrastructure is designed with defense-in-depth principles:

- **Network isolation:** WireGuard overlay network (10.2.0.0/24) isolated from host
- **Least privilege:** Minimal open ports, strict firewall rules
- **Defense layers:** UFW firewall, fail2ban, SSH hardening
- **Encrypted DNS:** All DNS queries stay within encrypted tunnel
- **Regular updates:** Automated security patching
- **Minimal logging:** Reduced attack surface and privacy protection

## Pre-Deployment Security

### SSH Key Management

**Generate strong SSH keys:**
```bash
# Ed25519 (recommended)
ssh-keygen -t ed25519 -C "questvpn-admin"

# Or RSA 4096
ssh-keygen -t rsa -b 4096 -C "questvpn-admin"
```

**Protect private keys:**
```bash
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Use SSH agent:**
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Never:**
- Share private keys
- Commit keys to repositories
- Use same key for multiple purposes
- Use password-based SSH authentication

### Secrets Management

**Environment files:**
- Never commit `.env.west` or `.env.east` to version control
- Use strong, unique passwords (20+ characters)
- Rotate credentials quarterly

**Generate strong passwords:**
```bash
# Random password (20 characters)
openssl rand -base64 20

# Or use password manager
```

**Required secrets:**
```bash
WG_DASHBOARD_PASS=<strong-unique-password>
ADGUARD_ADMIN_PASS=<strong-unique-password>
CF_API_TOKEN=<limited-scope-token>  # if using Cloudflare
```

### Hetzner Cloud Security

**Firewall configuration:**
1. Enable Hetzner Cloud Firewall for each server
2. Default: Deny all inbound
3. Allow only:
   - 22/tcp (SSH) from trusted IPs
   - 51820/udp (WireGuard) from 0.0.0.0/0
   - 443/udp (WireGuard alt) from 0.0.0.0/0
   - 51821/tcp (WG dashboard) from trusted IPs
   - 3000/tcp (AdGuard setup) from trusted IPs - REMOVE after setup

**Snapshot policy:**
- Create snapshots before major changes
- Encrypt snapshots
- Retain for 30 days
- Test restoration procedure

## Post-Deployment Hardening

### SSH Hardening

The Ansible playbook applies these by default:

```yaml
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
```

**Verify SSH configuration:**
```bash
ssh root@<server-ip> "sshd -T | grep -E 'permitrootlogin|passwordauthentication|pubkeyauthentication'"
```

Expected output:
```
permitrootlogin no
passwordauthentication no
pubkeyauthentication yes
```

**Optional: Change SSH port** (security through obscurity)
```bash
# Edit /etc/ssh/sshd_config
Port 2222

# Update UFW
ufw allow 2222/tcp
ufw delete allow 22/tcp
ufw reload

# Restart SSH
systemctl restart sshd

# Update Ansible inventory
ansible_port=2222
```

### Firewall Configuration

**UFW default policy:**
```bash
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed
```

**Allowed ports:**
```bash
# SSH (limit to prevent brute force)
ufw limit 22/tcp comment 'SSH'

# WireGuard
ufw allow 51820/udp comment 'WireGuard primary'
ufw allow 443/udp comment 'WireGuard alternate'

# WireGuard dashboard (restrict to VPN network)
ufw allow from 10.2.0.0/24 to any port 51821 proto tcp comment 'WG dashboard (VPN only)'

# AdGuard Home (internal only)
ufw allow from 10.2.0.0/24 to any port 3000 proto tcp comment 'AdGuard setup (VPN only)'
ufw allow from 10.2.0.0/24 to any port 53 proto udp comment 'AdGuard DNS (VPN only)'

# Unbound (internal only)
ufw allow from 10.2.0.0/24 to any port 53 proto udp comment 'Unbound DNS (VPN only)'
```

**Remove public AdGuard access after initial setup:**
```bash
ufw delete allow 3000/tcp
ufw reload
```

**Verify rules:**
```bash
ufw status numbered
```

### fail2ban Configuration

**Jails enabled:**
- `sshd`: Ban after 5 failed SSH attempts (10 min)
- `sshd-ddos`: Prevent SSH connection flooding

**Check bans:**
```bash
fail2ban-client status sshd
```

**Unban IP if needed:**
```bash
fail2ban-client set sshd unbanip <ip-address>
```

### Docker Security

**Daemon hardening applied:**
```json
{
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**Container isolation:**
- Containers run on isolated bridge network `wg_net`
- No host network mode
- Read-only filesystems where possible
- Capabilities dropped

**Verify:**
```bash
docker info | grep -A 5 "Security Options"
```

### DNS Privacy

**Configuration:**
```
Client → WireGuard (encrypted) → AdGuard Home (10.2.0.2) → Unbound (10.2.0.3) → Root DNS
```

**AdGuard Home hardening:**
1. Access only via VPN (10.2.0.0/24)
2. Enable DNSSEC validation
3. Enable HTTPS/TLS for web interface
4. Disable statistics after debugging
5. Upstream only to Unbound (10.2.0.3:53)

**Unbound hardening:**
- DNSSEC validation mandatory
- QNAME minimization enabled
- Prefetch enabled for performance
- No forwarding to public resolvers

**Verify DNS privacy:**
```bash
# From peer device
dig @10.2.0.2 example.com
dig @10.2.0.2 dnssec.works  # should return SERVFAIL if DNSSEC broken
```

## Peer Management Security

### Peer Generation

**Key management:**
- Private keys never leave peer device
- Public keys stored in WireGuard server config
- Pre-shared keys (PSK) for quantum resistance (optional)

**Peer isolation:**
- Each peer gets unique /32 address
- No peer-to-peer communication by default
- All traffic routed through gateway

**Naming conventions:**
```bash
# Good: Descriptive, no PII
./scripts/gen-peer.sh quest-device-1 both full
./scripts/gen-peer.sh router-home west full

# Bad: Contains PII
./scripts/gen-peer.sh john-smith-quest both full
```

### Peer Revocation

**Revoke compromised peers immediately:**
```bash
./scripts/revoke-peer.sh <peer-name> both
```

**What happens:**
1. Peer removed from WireGuard server config
2. Config files moved to `peers/revoked/`
3. Server restarted to apply changes
4. Peer can no longer connect

**Verify revocation:**
```bash
ssh root@<server-ip> "wg show"
# Should not list revoked peer
```

### Rotation Policy

**Recommended rotation schedule:**
- Peer keys: Annually or on compromise
- Server keys: Quarterly
- Passwords: Quarterly
- SSH keys: Biannually

**Server key rotation:**
```bash
# WARNING: Will disconnect all peers temporarily
./scripts/rotate-keys.sh west
./scripts/rotate-keys.sh east

# Re-generate all peer configs with new server public key
./scripts/gen-peer.sh <peer-name> both full
```

## Network Security

### IP Address Allocation

**Overlay network:** 10.2.0.0/24
- Gateway: 10.2.0.1 (WireGuard server)
- DNS: 10.2.0.2 (AdGuard Home)
- Recursive DNS: 10.2.0.3 (Unbound)
- Peers: 10.2.0.10 - 10.2.0.254

**Why private range:**
- RFC1918 prevents routing conflicts
- Isolated from public internet
- NAT traversal handled by WireGuard

### NAT and Forwarding

**IP forwarding required:**
```bash
# Check if enabled
sysctl net.ipv4.ip_forward
# Should return: net.ipv4.ip_forward = 1
```

**iptables rules:**
```bash
# NAT for VPN traffic
iptables -t nat -A POSTROUTING -s 10.2.0.0/24 -o eth0 -j MASQUERADE

# Allow forwarding for established connections
iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

Applied automatically by Docker and WireGuard.

### MTU and Fragmentation

**Why MTU matters:**
- Incorrect MTU causes packet fragmentation
- Fragmentation can leak metadata
- Performance degradation

**Optimal MTU:**
```bash
# Auto-detected per peer (1280-1420)
./scripts/mtu-autotune.sh <peer-name> <region>
```

**Manual check:**
```bash
# From peer device, ping VPN gateway with DF bit
ping -M do -s 1400 -c 3 10.2.0.1
# Reduce size until no fragmentation
```

## Monitoring and Logging

### Log Management

**Minimal logging principle:**
- WireGuard: Handshake timestamps only
- AdGuard: Query logs disabled after setup
- Unbound: Minimal logging
- SSH: Failed attempts only (fail2ban)

**Log rotation:**
```yaml
# /etc/logrotate.d/wireguard
/var/log/wireguard/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root adm
}
```

### Health Monitoring

**Automated checks:**
```bash
# Add to crontab
0 */6 * * * /opt/questvpn/scripts/healthcheck.sh west >> /var/log/healthcheck.log 2>&1
0 */6 * * * /opt/questvpn/scripts/healthcheck.sh east >> /var/log/healthcheck.log 2>&1
```

**Checks performed:**
- Docker containers running
- WireGuard interface up
- DNS resolution working (AdGuard → Unbound)
- Peer handshakes active
- Disk space available

**Alerts (optional):**
```bash
# Send to Slack/Discord/Email on failure
# Configure webhook in healthcheck.sh
```

### Intrusion Detection

**Check for suspicious activity:**
```bash
# SSH brute force attempts
cat /var/log/auth.log | grep "Failed password"

# fail2ban bans
fail2ban-client status sshd

# Unusual peer connections
wg show wg0 | grep "latest handshake"

# Large data transfers
wg show wg0 | grep "transfer"
```

## Incident Response

### Suspected Compromise

**Immediate actions:**

1. **Isolate affected peer:**
   ```bash
   ./scripts/revoke-peer.sh <compromised-peer> both
   ```

2. **Review logs:**
   ```bash
   ssh root@<server-ip> "journalctl -u docker-compose@wg -n 100"
   ssh root@<server-ip> "journalctl -u sshd -n 100"
   ```

3. **Check connected peers:**
   ```bash
   ssh root@<server-ip> "wg show"
   ```

4. **Rotate server keys:**
   ```bash
   ./scripts/rotate-keys.sh west
   ./scripts/rotate-keys.sh east
   ```

5. **Change all passwords:**
   - SSH key passphrase
   - WireGuard dashboard
   - AdGuard Home admin

6. **Review firewall rules:**
   ```bash
   ssh root@<server-ip> "ufw status numbered"
   ```

### Server Compromise

**If server is compromised:**

1. **Take snapshot immediately** (for forensics)
2. **Disconnect from network:**
   ```bash
   ufw deny from any to any
   ```
3. **Audit all access:**
   ```bash
   last -a
   lastlog
   ```
4. **Rebuild from scratch:**
   - Deploy new server
   - New SSH keys
   - New WireGuard keys
   - Re-run Ansible playbook
5. **Notify peers** to update configs

### Data Breach

**What data could be exposed:**
- Peer public keys (not sensitive)
- Connection timestamps
- Data transfer amounts
- IP addresses (peers and server)

**What is protected:**
- Peer private keys (on device only)
- Traffic content (encrypted)
- DNS queries (encrypted in tunnel)
- Peer-to-peer visibility (isolated)

## Compliance and Privacy

### Data Retention

**What we store:**
- Peer public keys (required for operation)
- Connection metadata (optional, can disable)
- DNS query logs (disabled after setup)

**What we don't store:**
- Browsing history
- Unencrypted traffic
- Peer IP addresses (outside connection logs)

**Disable all logging:**
```bash
# AdGuard: Settings → General → Query logs → Disable
# Unbound: verbosity: 0 in unbound.conf
# WireGuard: No additional logging beyond handshakes
```

### GDPR Compliance (EU)

If operating in EU:
- Document data processing activities
- Ensure peer consent for logging
- Provide data export mechanism
- Honor deletion requests (revoke peer)
- Encrypt data at rest (done via WireGuard)

### Audit Trail

**What to audit:**
- Peer creation dates
- Peer revocation dates
- Server key rotations
- Configuration changes
- Failed connection attempts

**Audit log location:**
```bash
# Centralized audit log
/var/log/questvpn/audit.log
```

## Security Checklist

### Initial Deployment
- [ ] Strong SSH keys generated
- [ ] All `.env` files use strong passwords
- [ ] SSH key-only authentication enabled
- [ ] UFW firewall configured
- [ ] fail2ban active
- [ ] Docker daemon hardened
- [ ] AdGuard upstream set to Unbound only
- [ ] Unbound DNSSEC validation enabled
- [ ] AdGuard port 3000 restricted after setup

### Monthly Maintenance
- [ ] Review peer list, revoke unused
- [ ] Check fail2ban logs
- [ ] Verify DNS chain (healthcheck.sh)
- [ ] Review firewall rules
- [ ] Check disk space
- [ ] Update server packages

### Quarterly Tasks
- [ ] Rotate passwords (WireGuard dashboard, AdGuard)
- [ ] Rotate server keys
- [ ] Review SSH keys and authorized_keys
- [ ] Test backup restoration
- [ ] Audit access logs

### Annual Tasks
- [ ] Rotate peer keys (re-generate configs)
- [ ] Rotate SSH keys
- [ ] Review and update security policies
- [ ] Penetration testing (optional)

## Reporting Vulnerabilities

If you discover a security vulnerability:

1. **Do not** open a public issue
2. Email: security@example.com (configure your contact)
3. Include:
   - Detailed description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if known)
4. Allow 90 days for patch before disclosure

## Additional Resources

- [WireGuard Security Whitepaper](https://www.wireguard.com/papers/wireguard.pdf)
- [OWASP VPN Security](https://owasp.org/www-community/vulnerabilities/)
- [NIST Cryptographic Standards](https://csrc.nist.gov/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

---

**Security is a continuous process, not a one-time setup. Stay vigilant!**
