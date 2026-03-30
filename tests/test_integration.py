#!/usr/bin/env python3
"""
Integration tests for Quest VPN infrastructure
"""

import subprocess
import os
import pytest


class TestScripts:
    """Test utility scripts"""

    def test_scripts_executable(self):
        """Verify all scripts are executable"""
        scripts = [
            'scripts/gen-peer.sh',
            'scripts/export-peer.sh',
            'scripts/revoke-peer.sh',
            'scripts/mtu-autotune.sh',
            'scripts/healthcheck.sh',
            'scripts/cf-ddns.sh',
            'deploy.sh',
            'validate.sh'
        ]
        for script in scripts:
            assert os.access(script, os.X_OK), f"{script} is not executable"

    def test_script_syntax(self):
        """Test bash script syntax"""
        scripts = [
            'scripts/gen-peer.sh',
            'scripts/export-peer.sh',
            'scripts/revoke-peer.sh',
            'scripts/mtu-autotune.sh',
            'scripts/healthcheck.sh',
            'scripts/cf-ddns.sh',
            'deploy.sh',
            'validate.sh'
        ]
        for script in scripts:
            result = subprocess.run(['bash', '-n', script], capture_output=True)
            assert result.returncode == 0, f"{script} has syntax errors: {result.stderr.decode()}"


class TestDockerCompose:
    """Test Docker Compose configurations"""

    def test_west_compose_valid(self):
        """Validate west region docker-compose.yml"""
        result = subprocess.run(
            ['docker', 'compose', '-f', 'docker/west/docker-compose.yml', 'config'],
            capture_output=True,
            env={**os.environ, 'WG_HOST_WEST': 'test.local', 'WG_PASSWORD': 'test'}
        )
        assert result.returncode == 0, f"West compose invalid: {result.stderr.decode()}"

    def test_east_compose_valid(self):
        """Validate east region docker-compose.yml"""
        result = subprocess.run(
            ['docker', 'compose', '-f', 'docker/east/docker-compose.yml', 'config'],
            capture_output=True,
            env={**os.environ, 'WG_HOST_EAST': 'test.local', 'WG_PASSWORD': 'test'}
        )
        assert result.returncode == 0, f"East compose invalid: {result.stderr.decode()}"


class TestAnsible:
    """Test Ansible playbooks"""

    def test_playbook_syntax(self):
        """Validate Ansible playbook syntax"""
        result = subprocess.run(
            ['ansible-playbook', '--syntax-check', 'ansible/deploy.yml'],
            capture_output=True,
            cwd='ansible'
        )
        assert result.returncode == 0, f"Playbook syntax error: {result.stderr.decode()}"

    def test_inventory_exists(self):
        """Check inventory file exists"""
        assert os.path.exists('ansible/inventory.ini'), "Inventory file missing"


class TestDocumentation:
    """Test documentation completeness"""

    def test_required_docs_exist(self):
        """Verify required documentation files exist"""
        docs = [
            'README.md',
            'CONTRIBUTING.md',
            'LICENSE',
            'docs/quickstart.md',
            'docs/quest-sideload.md',
            'docs/split-tunnel.md',
            'docs/always-on-adb.md',
            'docs/troubleshooting.md'
        ]
        for doc in docs:
            assert os.path.exists(doc), f"{doc} is missing"

    def test_readme_has_content(self):
        """Verify README has substantial content"""
        with open('README.md', 'r') as f:
            content = f.read()
            assert len(content) > 1000, "README is too short"
            assert '# Quest VPN' in content or '# QuestVPN' in content


class TestConfiguration:
    """Test configuration files"""

    def test_env_example_exists(self):
        """Verify .env.example exists"""
        assert os.path.exists('docker/.env.example'), ".env.example missing"

    def test_gitignore_exists(self):
        """Verify .gitignore exists and has VPN entries"""
        assert os.path.exists('.gitignore'), ".gitignore missing"
        with open('.gitignore', 'r') as f:
            content = f.read()
            assert '.env' in content or 'env' in content
            assert 'peers' in content or '*.conf' in content


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
