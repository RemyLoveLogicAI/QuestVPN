# Quest VPN - Architecture Decision Records

## ADR-001: Use WireGuard for VPN Protocol

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need to select a VPN protocol for Quest devices that provides:
- Strong security
- High performance
- Low latency
- Modern cryptography
- Cross-platform support

### Decision
Use WireGuard as the VPN protocol.

### Rationale
- Modern cryptography (ChaCha20, Poly1305)
- Minimal attack surface (4,000 lines vs OpenVPN's 100,000+)
- Superior performance (lower CPU usage, higher throughput)
- Native Quest/Android support
- Active development and security audits
- Simpler configuration than IPSec/OpenVPN

### Consequences
- Requires kernel module or userspace implementation
- Less mature ecosystem than OpenVPN
- Fewer enterprise features (but sufficient for our needs)
- Better performance and security posture

---

## ADR-002: Multi-Region Deployment

**Date**: 2024-01-01
**Status**: Accepted

### Context
Users are geographically distributed. Need to minimize latency and provide redundancy.

### Decision
Deploy in two regions: West (Americas) and East (Europe/Asia).

### Rationale
- Reduced latency for global users
- Geographic redundancy
- Load distribution
- Compliance with data residency requirements
- Failover capability

### Consequences
- Increased operational complexity
- Higher infrastructure costs
- Need for region-aware peer assignment
- Benefit: Better user experience, higher availability

---

## ADR-003: Use AdGuard Home + Unbound for DNS

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need DNS resolution with:
- Ad blocking
- Privacy protection
- DNSSEC validation
- Recursive resolution

### Decision
Use AdGuard Home for filtering + Unbound for recursive DNS.

### Rationale
- AdGuard Home: User-friendly, powerful filtering, web UI
- Unbound: DNSSEC validation, privacy-focused, no upstream tracking
- Separation of concerns (filtering vs resolution)
- Better privacy than forwarding to public DNS

### Consequences
- Two components to maintain
- Slightly more complex configuration
- Benefit: Enhanced privacy and security

---

## ADR-004: Docker Compose for Service Orchestration

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need simple, reproducible deployment of multiple services.

### Decision
Use Docker Compose instead of Kubernetes.

### Rationale
- Simpler for small-scale deployment
- Lower resource overhead
- Easier to understand and maintain
- Sufficient for our scale (< 1000 peers per region)
- Faster deployment and iteration

### Consequences
- Less sophisticated orchestration features
- Manual scaling required
- Limited built-in HA features
- Acceptable trade-off for simplicity

---

## ADR-005: Ansible for Infrastructure as Code

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need automated, repeatable infrastructure deployment.

### Decision
Use Ansible for infrastructure automation.

### Rationale
- Agentless (SSH-based)
- Readable YAML syntax
- Large ecosystem of modules
- Good for configuration management
- Supports our use case well

### Consequences
- Sequential execution (slower than parallel tools)
- Less infrastructure validation than Terraform
- Benefit: Simpler setup, good for our scale

---

## ADR-006: Prometheus + Grafana for Monitoring

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need comprehensive monitoring and alerting.

### Decision
Use Prometheus for metrics collection, Grafana for visualization, Alertmanager for alerts.

### Rationale
- Industry standard for container monitoring
- Excellent Docker integration
- Powerful query language (PromQL)
- Active community
- Grafana provides excellent dashboards

### Consequences
- Pull-based model (needs network access)
- Time-series storage considerations
- Learning curve for PromQL
- Benefit: Powerful, flexible monitoring

---

## ADR-007: Centralized Logging with Loki

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need centralized log aggregation and search.

### Decision
Use Loki for log aggregation with Promtail as shipper.

### Rationale
- Integrates seamlessly with Grafana
- Lower resource usage than Elasticsearch
- Label-based indexing (like Prometheus)
- Good Docker/container support
- Cost-effective

### Consequences
- Less full-text search capability than Elasticsearch
- Newer, less mature
- Benefit: Lower operational overhead

---

## ADR-008: Automated Backups to S3

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need reliable, automated backup solution with off-site storage.

### Decision
Automated backups every 6 hours to S3-compatible storage.

### Rationale
- Geographic redundancy
- Versioning support
- Cost-effective
- Industry standard
- Easy integration

### Consequences
- Dependency on cloud provider
- Data transfer costs
- Benefit: Reliable disaster recovery

---

## ADR-009: Security: SSH Key Only, No Root

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need strong authentication and access control.

### Decision
- SSH public key authentication only
- Root login disabled
- fail2ban for brute-force protection

### Rationale
- Password-based auth vulnerable to brute-force
- SSH keys more secure
- Disabling root reduces attack surface
- fail2ban adds defense in depth

### Consequences
- Requires key distribution
- No password recovery option
- Benefit: Significantly improved security

---

## ADR-010: GitHub Actions for CI/CD

**Date**: 2024-01-01
**Status**: Accepted

### Context
Need automated testing and deployment pipeline.

### Decision
Use GitHub Actions for CI/CD.

### Rationale
- Integrated with GitHub
- Free for public repositories
- Good Docker support
- Large marketplace of actions
- Sufficient for our needs

### Consequences
- Vendor lock-in to GitHub
- Limited to GitHub-hosted or self-hosted runners
- Benefit: Simple, integrated workflow

---

## Template for New ADRs

```markdown
## ADR-XXX: [Title]

**Date**: YYYY-MM-DD
**Status**: [Proposed|Accepted|Deprecated|Superseded]

### Context
[What is the issue we're addressing?]

### Decision
[What we decided to do]

### Rationale
[Why we made this decision]

### Consequences
[What are the positive and negative outcomes?]
```
