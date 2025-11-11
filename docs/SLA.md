# Quest VPN - Service Level Agreement (SLA)

## Service Description
Quest VPN provides secure WireGuard VPN services for Meta Quest devices with DNS filtering and multi-region availability.

## Service Level Objectives (SLOs)

### Availability
- **Target**: 99.9% uptime per month
- **Measurement**: Uptime monitoring via Prometheus/Pingdom
- **Downtime Budget**: 43.8 minutes per month

### Performance
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Connection Establishment | < 2 seconds | Average handshake time |
| DNS Resolution | < 50ms | AdGuard query time (p95) |
| Latency (regional) | < 20ms | Ping time from client |
| Throughput | > 500 Mbps | iperf3 test |

### Reliability
| Metric | Target |
|--------|--------|
| Successful VPN Connections | > 99.5% |
| DNS Query Success Rate | > 99.9% |
| Mean Time Between Failures (MTBF) | > 720 hours |
| Mean Time To Recovery (MTTR) | < 1 hour |

## Support Response Times

### Severity Levels

**Critical (P1)**
- **Definition**: Complete service outage affecting all users
- **Response Time**: 15 minutes
- **Resolution Time**: 1 hour
- **Example**: VPN server completely down

**High (P2)**
- **Definition**: Major functionality impaired affecting multiple users
- **Response Time**: 1 hour
- **Resolution Time**: 4 hours
- **Example**: DNS resolution failing for 50% of requests

**Medium (P3)**
- **Definition**: Moderate impact, workaround available
- **Response Time**: 4 hours
- **Resolution Time**: 1 business day
- **Example**: Single peer connection issues

**Low (P4)**
- **Definition**: Minor issue, cosmetic bug
- **Response Time**: 1 business day
- **Resolution Time**: 1 week
- **Example**: Dashboard display issue

## Scheduled Maintenance

- **Frequency**: Monthly
- **Duration**: Maximum 2 hours
- **Window**: First Sunday of month, 02:00-04:00 UTC
- **Notification**: 7 days advance notice
- **Impact**: Possible service interruption

### Emergency Maintenance
- **Notification**: 2 hours minimum (best effort)
- **Executed**: Only for critical security issues

## Service Credits

### Credit Calculation
For each 1% below SLA target availability:
- **Credit**: 5% of monthly service fee
- **Maximum Credit**: 100% of monthly service fee

### Credit Request Process
1. Submit request within 30 days of incident
2. Provide evidence of downtime
3. Credits applied to next billing cycle

### Exclusions
Credits not available for:
- Scheduled maintenance windows
- Issues caused by client misconfiguration
- Third-party service failures (DNS, routing)
- Force majeure events
- Client-side network issues

## Monitoring & Reporting

### Real-Time Monitoring
- **Status Page**: status.questvpn.com
- **Update Frequency**: Real-time
- **Historical Data**: 90 days

### Monthly Reports
Delivered by 5th business day of following month:
- Availability metrics
- Performance statistics
- Incident summary
- Maintenance history

### Quarterly Business Reviews
- SLA performance review
- Capacity planning
- Feature roadmap
- Risk assessment

## Incident Management

### Notification Channels
1. **Status Page**: Automatic updates
2. **Email**: To registered contacts
3. **Slack**: #vpn-status channel
4. **SMS**: For P1/P2 incidents (opt-in)

### Incident Lifecycle
1. **Detection** (automated monitoring)
2. **Notification** (as per SLA)
3. **Investigation** (root cause analysis)
4. **Resolution** (fix implementation)
5. **Post-Mortem** (within 48 hours)

## Service Exclusions

Services not covered by this SLA:
- Beta features (clearly marked)
- Development/staging environments
- Client-side software (Quest device apps)
- Third-party integrations

## Data Protection

### Backup Schedule
- **Frequency**: Every 6 hours
- **Retention**: 30 days
- **Recovery Point Objective (RPO)**: 6 hours
- **Recovery Time Objective (RTO)**: 1 hour

### Data Residency
- **Primary**: User-specified region (West/East)
- **Backup**: Encrypted, geo-redundant storage
- **Compliance**: GDPR, SOC 2 Type II

## Security Commitments

### Vulnerability Management
- **Scanning**: Daily automated scans
- **Patching**: Critical vulnerabilities within 24 hours
- **Updates**: Security updates within 7 days

### Incident Response
- **Detection**: 24/7 automated monitoring
- **Response Team**: Available within 15 minutes
- **Notification**: Within 24 hours of breach detection

## Review & Updates

- **Review Frequency**: Quarterly
- **Update Process**: 30 days notice for material changes
- **Version Control**: All changes documented

## Contact Information

- **Support Email**: support@questvpn.com
- **Emergency Hotline**: +1-xxx-xxx-xxxx (24/7)
- **Account Manager**: account@questvpn.com
- **Status Page**: https://status.questvpn.com

## Definitions

- **Uptime**: Service is accessible and functional
- **Downtime**: Service is unavailable or non-functional
- **Scheduled Maintenance**: Pre-announced service windows
- **Emergency Maintenance**: Unplanned critical updates
- **Business Day**: Monday-Friday, 9 AM - 5 PM EST, excluding holidays

## Acceptance

By using Quest VPN services, you agree to the terms of this SLA.

**Effective Date**: January 1, 2024
**Version**: 1.0
**Next Review**: April 1, 2024
