# Contributing to Quest VPN

Thank you for your interest in contributing to Quest VPN! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Respect different viewpoints and experiences

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/RemyLoveLogicAI/QuestVPN/issues) first
2. Create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Docker version, etc.)
   - Relevant logs or screenshots

### Suggesting Enhancements

1. Check if the feature has been suggested already
2. Create an issue describing:
   - The problem your feature solves
   - Proposed solution
   - Alternative approaches considered
   - Impact on existing functionality

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/QuestVPN.git
   cd QuestVPN
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style
   - Add/update documentation as needed
   - Test your changes thoroughly

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

   Use conventional commit messages:
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `refactor:` Code refactoring
   - `test:` Test updates
   - `chore:` Maintenance tasks

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of changes
   - Reference any related issues
   - Include testing steps

## Development Setup

### Using DevContainer (Recommended)

1. Open repository in VS Code
2. Install "Dev Containers" extension
3. Click "Reopen in Container"
4. Container provisions automatically with all dependencies

### Manual Setup

```bash
# Install dependencies
pip install ansible qrcode[pil]
sudo apt-get install qrencode wireguard-tools docker-compose

# Test deployment locally
cd docker/west
cp ../.env.example ../.env
# Edit .env with test values
docker-compose up -d
```

## Testing

### Test Docker Compose

```bash
cd docker/west
docker-compose config  # Validate syntax
docker-compose up -d   # Start services
docker-compose ps      # Check status
docker-compose logs    # View logs
docker-compose down    # Clean up
```

### Test Ansible Playbook

```bash
cd ansible
# Dry run
ansible-playbook -i inventory.ini deploy.yml --check

# Syntax check
ansible-playbook -i inventory.ini deploy.yml --syntax-check
```

### Test Scripts

```bash
cd scripts
# Check syntax
bash -n gen-peer.sh
bash -n export-peer.sh
# etc.
```

## Documentation

- Update README.md for major changes
- Update relevant docs/ files
- Add inline comments for complex logic
- Include examples for new features

### Documentation Structure

```
docs/
├── quickstart.md          # Getting started guide
├── quest-sideload.md      # Quest installation
├── split-tunnel.md        # Split tunnel config
├── always-on-adb.md       # ADB setup
└── troubleshooting.md     # Common issues
```

## Coding Standards

### Bash Scripts

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -e`
- Quote variables: `"$VAR"`
- Use descriptive names
- Add comments for complex logic
- Make scripts executable: `chmod +x`

### Docker Compose

- Use version 3.8+
- Organize services logically
- Use environment variables for config
- Include restart policies
- Document custom networks

### Ansible Playbooks

- Use descriptive task names
- Organize with tags
- Use handlers for service restarts
- Validate with `--syntax-check`
- Test with `--check` mode

### Documentation

- Use clear, concise language
- Include code examples
- Add screenshots for UI changes
- Keep table of contents updated
- Link between related docs

## Project Structure

```
QuestVPN/
├── .devcontainer/        # DevContainer configuration
├── ansible/              # Deployment playbooks
│   ├── deploy.yml
│   ├── inventory.ini
│   └── ansible.cfg
├── docker/               # Docker Compose configs
│   ├── west/             # West region
│   ├── east/             # East region
│   └── .env.example      # Environment template
├── docs/                 # Documentation
├── peers/                # Peer configurations (gitignored)
├── scripts/              # Utility scripts
│   ├── gen-peer.sh
│   ├── export-peer.sh
│   ├── revoke-peer.sh
│   ├── mtu-autotune.sh
│   ├── healthcheck.sh
│   └── cf-ddns.sh
├── deploy.sh             # Main deployment wrapper
├── README.md             # Main documentation
└── LICENSE               # Apache 2.0 license
```

## Security Guidelines

### Handling Secrets

- Never commit secrets to git
- Use `.env` files for configuration
- Document required environment variables
- Use `.env.example` as template
- Gitignore sensitive files

### Code Security

- Validate user input
- Sanitize file paths
- Use secure defaults
- Document security implications
- Follow principle of least privilege

### Peer Configurations

- Treat as sensitive data
- Never commit to repository
- Implement secure storage
- Provide revocation mechanism
- Document key rotation

## Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Create git tag
4. Create GitHub release
5. Update documentation

## Getting Help

- **Questions**: [GitHub Discussions](https://github.com/RemyLoveLogicAI/QuestVPN/discussions)
- **Bugs**: [GitHub Issues](https://github.com/RemyLoveLogicAI/QuestVPN/issues)
- **Chat**: [Discord/Slack if available]

## Areas for Contribution

### High Priority
- IPv6 support
- Automated testing
- Monitoring/metrics
- Backup/restore scripts
- Additional regions

### Medium Priority
- Web dashboard improvements
- CLI tool for peer management
- Automated peer rotation
- Performance optimizations
- Multi-language documentation

### Good First Issues
- Documentation improvements
- Script error handling
- Code comments
- Example configurations
- Tutorial videos

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing to Quest VPN! 🎉
