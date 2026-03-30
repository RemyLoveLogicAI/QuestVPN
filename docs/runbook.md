# Quest VPN - Operational Runbook

## Table of Contents
1. [Service Architecture](#service-architecture)
2. [Common Operations](#common-operations)
3. [Troubleshooting](#troubleshooting)
4. [Monitoring](#monitoring)
5. [Maintenance Procedures](#maintenance-procedures)

## Service Architecture

### Components
- **WireGuard (wg-easy)**: VPN server with web UI (ports 51820/udp, 443/tcp)
- **AdGuard Home**: DNS filtering and ad-blocking (ports 53/tcp+udp, 3000/tcp)
- **Unbound**: Recursive DNS resolver
- **Prometheus**: Metrics collection (port 9090)
- **Grafana**: Metrics visualization (port 3001)
- **Alertmanager**: Alert routing (port 9093)

### Network Topology
```
Internet → WireGuard (10.2.0.1) → AdGuard (10.2.0.2) → Unbound (10.2.0.3) → Root DNS
```

## Common Operations

### Start Services
```bash
# All regions
./deploy.sh all

# Specific region
cd /opt/questvpn/docker/<region>
docker compose up -d
```

### Stop Services
```bash
cd /opt/questvpn/docker/<region>
docker compose down
```

### Restart Services
```bash
cd /opt/questvpn/docker/<region>
docker compose restart
```

### View Logs
```bash
# All logs
docker compose logs -f

# Specific service
docker compose logs -f <service-name>

# Last 100 lines
docker compose logs --tail=100 <service-name>
```

### Add New Peer
```bash
cd /opt/questvpn/scripts
./gen-peer.sh <peer-name> <region>
./export-peer.sh <peer-name>
```

### Revoke Peer
```bash
cd /opt/questvpn/scripts
./revoke-peer.sh <peer-name> <region>
```

### Health Check
```bash
/opt/questvpn/scripts/healthcheck.sh <region>
```

### Update DNS (DDNS)
```bash
/opt/questvpn/scripts/cf-ddns.sh <region>
```

### MTU Optimization
```bash
/opt/questvpn/scripts/mtu-autotune.sh wg0 <region>
```

## Troubleshooting

### VPN Connection Issues

**Symptom**: Clients cannot connect to VPN

**Diagnosis:**
```bash
# Check if WireGuard is running
docker ps | grep wg-easy

# Check WireGuard status
docker exec wg-easy-<region> wg show

# Check firewall
ufw status
```

**Resolution:**
1. Verify port 51820/udp is open
2. Check WireGuard configuration
3. Restart WireGuard container
4. Check server logs

### DNS Resolution Failure

**Symptom**: No DNS resolution through VPN

**Diagnosis:**
```bash
# Check AdGuard status
docker exec adguard-<region> wget -q --spider http://localhost:3000

# Check Unbound status
docker exec unbound-<region> unbound-control status

# Test DNS query
docker exec adguard-<region> nslookup google.com 10.2.0.3
```

**Resolution:**
1. Restart AdGuard: `docker compose restart adguard`
2. Restart Unbound: `docker compose restart unbound`
3. Check Unbound configuration
4. Verify upstream DNS connectivity

### High CPU/Memory Usage

**Diagnosis:**
```bash
# Check resource usage
docker stats

# Check host resources
top
free -h
df -h
```

**Resolution:**
1. Identify resource-heavy container
2. Check for peer connection storms
3. Review logs for errors
4. Consider scaling up resources

### Container Won't Start

**Diagnosis:**
```bash
# Check container logs
docker logs <container-name>

# Check Docker daemon
systemctl status docker

# Verify configuration
docker compose config
```

**Resolution:**
1. Fix configuration errors
2. Check port conflicts
3. Verify file permissions
4. Restart Docker daemon if needed

## Monitoring

### Access Monitoring Dashboards

**Prometheus**: http://<server>:9090
**Grafana**: http://<server>:3001 (admin/admin)
**Alertmanager**: http://<server>:9093

### Key Metrics to Monitor

- **VPN Active Connections**: WireGuard peer count
- **DNS Query Rate**: AdGuard queries per second
- **CPU Usage**: Should be < 70%
- **Memory Usage**: Should be < 80%
- **Disk Usage**: Should be < 80%
- **Network Traffic**: Bandwidth utilization

### Alert Thresholds

| Alert | Threshold | Severity |
|-------|-----------|----------|
| VPN Server Down | 2 minutes | Critical |
| High CPU | > 80% for 5 min | Warning |
| High Memory | > 85% for 5 min | Warning |
| Low Disk Space | < 15% | Warning |
| DNS Query Failures | > 5% for 5 min | Warning |

## Maintenance Procedures

### Planned Maintenance

1. **Announce maintenance window** (24-48 hours notice)
2. **Create backup**
   ```bash
   /opt/questvpn/backup-restore/backup.sh
   ```
3. **Perform maintenance**
4. **Verify services**
   ```bash
   /opt/questvpn/scripts/healthcheck.sh <region>
   ```
5. **Confirm restoration**

### Rolling Updates

```bash
# Update one region at a time
cd /opt/questvpn/docker/west
docker compose pull
docker compose up -d

# Wait and verify
sleep 60
/opt/questvpn/scripts/healthcheck.sh west

# Repeat for east
cd /opt/questvpn/docker/east
docker compose pull
docker compose up -d
```

### Certificate Renewal (Let's Encrypt)

```bash
# Renew certificates
certbot renew

# Reload services
docker compose restart wg-easy
```

### Log Rotation

```bash
# Configure log rotation
cat > /etc/logrotate.d/questvpn <<EOF
/var/log/questvpn/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
EOF
```

### Database Maintenance

```bash
# Vacuum AdGuard database
docker exec adguard-<region> sqlite3 /opt/adguardhome/work/data/querylog.db "VACUUM;"

# Optimize Prometheus storage
docker exec prometheus promtool tsdb analyze /prometheus
```

### Security Updates

```bash
# Update system packages
apt update && apt upgrade -y

# Update Docker images
cd /opt/questvpn/docker/<region>
docker compose pull
docker compose up -d

# Restart services
docker compose restart
```

## Emergency Procedures

### Immediate Service Shutdown

```bash
# Stop all VPN services
cd /opt/questvpn/docker/west && docker compose down
cd /opt/questvpn/docker/east && docker compose down

# Block all VPN traffic
ufw delete allow 51820/udp
```

### Emergency Peer Revocation

```bash
# Revoke all peers immediately
docker exec wg-easy-<region> wg set wg0 peer <public-key> remove

# Or restart with empty peer list
docker compose down
# Remove peer configs
# docker compose up -d
```

### Restore from Backup

```bash
# Stop services
docker compose down

# Restore backup
/opt/questvpn/backup-restore/restore.sh <backup-file>

# Verify
/opt/questvpn/scripts/healthcheck.sh <region>
```

## Escalation Path

| Level | Contact | Response Time |
|-------|---------|---------------|
| L1 | On-call Engineer | 15 minutes |
| L2 | Infrastructure Lead | 30 minutes |
| L3 | CTO/CISO | 1 hour |

## Quick Reference Commands

```bash
# Status check
docker ps
docker compose ps

# Resource usage
docker stats --no-stream

# Live logs
docker compose logs -f --tail=50

# Service health
curl http://localhost:3000/control/status  # AdGuard
docker exec wg-easy-west wg show           # WireGuard

# Network connectivity
ping 10.2.0.1  # WireGuard
ping 10.2.0.2  # AdGuard
ping 10.2.0.3  # Unbound
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01-01 | Initial runbook |
