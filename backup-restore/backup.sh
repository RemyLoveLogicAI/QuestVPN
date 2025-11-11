#!/bin/bash
# Automated backup script for Quest VPN

set -e

BACKUP_DIR="${BACKUP_DIR:-/opt/questvpn/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="questvpn_backup_${TIMESTAMP}"

echo "=== Quest VPN Backup - ${TIMESTAMP} ==="

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Create temporary backup staging area
STAGING_DIR=$(mktemp -d)
trap "rm -rf ${STAGING_DIR}" EXIT

echo "Staging directory: ${STAGING_DIR}"

# Backup WireGuard configurations
echo "Backing up WireGuard configurations..."
mkdir -p "${STAGING_DIR}/wireguard"
docker cp wg-easy-west:/etc/wireguard "${STAGING_DIR}/wireguard/west" 2>/dev/null || echo "West region not running"
docker cp wg-easy-east:/etc/wireguard "${STAGING_DIR}/wireguard/east" 2>/dev/null || echo "East region not running"

# Backup AdGuard Home configurations
echo "Backing up AdGuard Home configurations..."
mkdir -p "${STAGING_DIR}/adguard"
docker cp adguard-west:/opt/adguardhome/conf "${STAGING_DIR}/adguard/west-conf" 2>/dev/null || echo "AdGuard west conf not found"
docker cp adguard-east:/opt/adguardhome/conf "${STAGING_DIR}/adguard/east-conf" 2>/dev/null || echo "AdGuard east conf not found"

# Backup Unbound configurations
echo "Backing up Unbound configurations..."
mkdir -p "${STAGING_DIR}/unbound"
cp -r /opt/questvpn/docker/west/unbound "${STAGING_DIR}/unbound/west" 2>/dev/null || true
cp -r /opt/questvpn/docker/east/unbound "${STAGING_DIR}/unbound/east" 2>/dev/null || true

# Backup peer configurations
echo "Backing up peer configurations..."
mkdir -p "${STAGING_DIR}/peers"
cp -r /opt/questvpn/peers/* "${STAGING_DIR}/peers/" 2>/dev/null || echo "No peers to backup"

# Backup environment configuration (excluding secrets)
echo "Backing up environment configuration..."
if [ -f /opt/questvpn/docker/.env ]; then
    # Sanitize .env by removing sensitive values
    sed 's/=.*/=REDACTED/' /opt/questvpn/docker/.env > "${STAGING_DIR}/.env.template"
fi

# Backup Ansible inventory
echo "Backing up Ansible inventory..."
mkdir -p "${STAGING_DIR}/ansible"
cp /opt/questvpn/ansible/inventory.ini "${STAGING_DIR}/ansible/" 2>/dev/null || true

# Create metadata file
cat > "${STAGING_DIR}/backup_metadata.txt" <<EOF
Backup Date: $(date)
Hostname: $(hostname)
Backup Script Version: 1.0
Docker Version: $(docker --version)
Containers Backed Up:
$(docker ps --format "  - {{.Names}} ({{.Status}})")
EOF

# Create compressed archive
echo "Creating backup archive..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${STAGING_DIR}" .

# Create checksum
sha256sum "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" > "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.sha256"

# Encrypt backup (optional - requires GPG key)
if [ -n "${BACKUP_GPG_KEY}" ]; then
    echo "Encrypting backup..."
    gpg --encrypt --recipient "${BACKUP_GPG_KEY}" "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    rm "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo "Encrypted backup: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.gpg"
fi

# Clean up old backups
echo "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name "questvpn_backup_*.tar.gz*" -type f -mtime +${RETENTION_DAYS} -delete

# Upload to remote storage (optional)
if [ -n "${BACKUP_S3_BUCKET}" ]; then
    echo "Uploading to S3..."
    aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "s3://${BACKUP_S3_BUCKET}/questvpn-backups/" || echo "S3 upload failed"
fi

echo ""
echo "=== Backup Complete ==="
echo "Backup file: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
echo "Checksum: $(cat "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.sha256")"
echo ""
echo "To restore this backup, run:"
echo "  ./restore.sh ${BACKUP_NAME}.tar.gz"
