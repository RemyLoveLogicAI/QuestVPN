# Changelog

All notable changes to Quest VPN will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete enterprise-grade production infrastructure
- CI/CD pipeline with GitHub Actions
- Comprehensive monitoring stack (Prometheus, Grafana, Alertmanager)
- Centralized logging (Loki + Promtail)
- Automated backup and restore procedures
- Disaster recovery documentation
- Operational runbook
- Service Level Agreement (SLA)
- Security policy documentation
- Architecture decision records (ADRs)
- Change management process
- Integration test suite
- Multi-environment support (production, staging)

### Changed
- Enhanced README with production readiness information
- Updated gitignore for monitoring data

## [1.0.0] - 2024-01-01

### Added
- Initial production release
- Multi-region deployment (West/East)
- WireGuard VPN with wg-easy web interface
- AdGuard Home for DNS filtering
- Unbound for recursive DNS resolution
- Ansible playbook for automated deployment
- SSH hardening and security configuration
- UFW firewall setup
- fail2ban integration
- Utility scripts for peer management
- QR code export for Quest devices
- MTU auto-tuning script
- Health check monitoring
- Cloudflare Dynamic DNS support
- DevContainer configuration
- Comprehensive documentation
  - Quick start guide
  - Quest sideloading instructions
  - Split-tunnel configuration
  - Always-on ADB guide
  - Troubleshooting guide
- Validation script
- Deployment wrapper script

### Security
- Public key SSH authentication only
- Root login disabled
- Encrypted WireGuard tunnels (ChaCha20-Poly1305)
- Private DNS resolution
- Minimal firewall attack surface

## [0.1.0] - 2024-01-01

### Added
- Initial project structure
- Basic Docker Compose configuration
- Placeholder documentation
