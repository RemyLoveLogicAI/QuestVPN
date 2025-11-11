# Quest VPN - Disaster Recovery Plan

## Overview
This document outlines the disaster recovery procedures for Quest VPN infrastructure.

## Recovery Time Objective (RTO)
- **Target RTO**: 1 hour
- **Maximum RTO**: 4 hours

## Recovery Point Objective (RPO)
- **Target RPO**: 1 hour
- **Automated backups**: Every 6 hours
- **Retention**: 30 days

## Disaster Scenarios

### 1. Complete Server Failure

**Detection:**
- Monitoring alerts (Prometheus/Alertmanager)
- Failed health checks
- User reports

**Recovery Steps:**

1. **Provision new server**
   ```bash
   # Deploy to replacement server
   ansible-playbook -i inventory-disaster.ini ansible/deploy.yml
   ```

2. **Restore from backup**
   ```bash
   # Download latest backup from S3
   aws s3 cp s3://backup-bucket/questvpn-backups/latest.tar.gz .
   
   # Restore configuration
   ./backup-restore/restore.sh latest.tar.gz
   ```

3. **Update DNS**
   ```bash
   # Update Cloudflare DNS to new IP
   ./scripts/cf-ddns.sh <region>
   ```

4. **Verify functionality**
   ```bash
   ./scripts/healthcheck.sh <region>
   ```

**Expected Recovery Time**: 45-60 minutes

### 2. Container Failure

**Detection:**
- Container health check failure
- Docker daemon alerts

**Recovery Steps:**

1. **Identify failed container**
   ```bash
   docker ps -a
   docker logs <container-name>
   ```

2. **Restart container**
   ```bash
   cd /opt/questvpn/docker/<region>
   docker compose restart <service-name>
   ```

3. **If restart fails, rebuild**
   ```bash
   docker compose down <service-name>
   docker compose up -d <service-name>
   ```

**Expected Recovery Time**: 5-10 minutes

### 3. Data Corruption

**Detection:**
- Configuration errors
- Invalid peer data
- Service startup failures

**Recovery Steps:**

1. **Stop affected services**
   ```bash
   docker compose down
   ```

2. **Restore from latest known-good backup**
   ```bash
   ./backup-restore/restore.sh <backup-file>
   ```

3. **Verify data integrity**
   ```bash
   docker compose config
   ./validate.sh
   ```

**Expected Recovery Time**: 15-30 minutes

### 4. Network Partition

**Detection:**
- Region unreachable
- Peer connection failures
- Cross-region sync issues

**Recovery Steps:**

1. **Verify network connectivity**
   ```bash
   ping <remote-server>
   traceroute <remote-server>
   ```

2. **Check firewall rules**
   ```bash
   ufw status
   iptables -L -n
   ```

3. **Failover to alternate region**
   ```bash
   # Update DNS to point to working region
   ./scripts/cf-ddns.sh <working-region>
   ```

**Expected Recovery Time**: 10-20 minutes

### 5. Security Breach

**Detection:**
- Intrusion detection alerts
- Unusual peer activity
- fail2ban notifications

**Recovery Steps:**

1. **Immediate isolation**
   ```bash
   # Block all traffic
   ufw default deny incoming
   ufw default deny outgoing
   
   # Stop VPN services
   docker compose down
   ```

2. **Incident analysis**
   ```bash
   # Review logs
   journalctl -u docker -n 1000
   docker compose logs
   grep "failed" /var/log/auth.log
   ```

3. **Revoke compromised peers**
   ```bash
   ./scripts/revoke-peer.sh <peer-name> <region>
   ```

4. **Rotate secrets**
   ```bash
   # Generate new keys
   # Update .env file
   # Redeploy services
   ```

5. **Restore from clean backup**
   ```bash
   ./backup-restore/restore.sh <pre-breach-backup>
   ```

**Expected Recovery Time**: 1-4 hours (depending on breach scope)

## Backup Procedures

### Automated Backups

Cron job on each server:
```bash
# /etc/cron.d/questvpn-backup
0 */6 * * * /opt/questvpn/backup-restore/backup.sh
```

### Manual Backup

```bash
cd /opt/questvpn
./backup-restore/backup.sh
```

### Backup Verification

Monthly backup restoration test:
```bash
# Test restore in staging environment
./backup-restore/restore.sh test-backup.tar.gz
```

## Communication Plan

### Internal Escalation
1. **Level 1**: On-call engineer (via PagerDuty)
2. **Level 2**: Infrastructure team lead
3. **Level 3**: CTO/CISO

### User Communication
- **Status page**: status.questvpn.com
- **Email notifications**: For outages > 15 minutes
- **Social media**: For major incidents

### Templates

**Incident Start:**
```
Subject: [INCIDENT] Quest VPN Service Disruption

We are currently experiencing issues with Quest VPN <region> region.
Impact: Users may experience connection difficulties
ETA: Under investigation
Updates: Every 30 minutes
```

**Incident Resolution:**
```
Subject: [RESOLVED] Quest VPN Service Restored

The Quest VPN service has been fully restored.
Root cause: <brief description>
Duration: <start> to <end>
Post-mortem: Will be published within 48 hours
```

## Testing Schedule

- **Backup restoration**: Monthly
- **Failover drill**: Quarterly
- **Full DR exercise**: Annually
- **Security breach simulation**: Bi-annually

## Contact Information

| Role | Contact | Backup |
|------|---------|--------|
| On-call Engineer | on-call@questvpn.local | +1-xxx-xxx-xxxx |
| Infrastructure Lead | infra-lead@questvpn.local | +1-xxx-xxx-xxxx |
| Security Team | security@questvpn.local | +1-xxx-xxx-xxxx |

## Runbook Locations

- Main runbook: `/opt/questvpn/docs/runbook.md`
- Backup location: S3 bucket `s3://questvpn-docs/runbooks/`
- Offline copy: Physical binder in office

## Post-Incident Review

Within 48 hours of incident resolution:

1. **Timeline reconstruction**
2. **Root cause analysis**
3. **Impact assessment**
4. **Action items identification**
5. **Runbook updates**
6. **Team retrospective**

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-01-01 | DevOps | Initial version |
