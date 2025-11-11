#!/bin/bash
# Restore script for Quest VPN backups

set -e

BACKUP_FILE="${1}"
BACKUP_DIR="${BACKUP_DIR:-/opt/questvpn/backups}"
RESTORE_DIR="${RESTORE_DIR:-/opt/questvpn}"

if [ -z "${BACKUP_FILE}" ]; then
    echo "Usage: $0 <backup-file.tar.gz>"
    echo ""
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/questvpn_backup_*.tar.gz 2>/dev/null || echo "  No backups found"
    exit 1
fi

# Check if backup file exists
if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    echo "Error: Backup file not found: ${BACKUP_DIR}/${BACKUP_FILE}"
    exit 1
fi

# Verify checksum if available
if [ -f "${BACKUP_DIR}/${BACKUP_FILE}.sha256" ]; then
    echo "Verifying backup checksum..."
    cd "${BACKUP_DIR}"
    sha256sum -c "${BACKUP_FILE}.sha256" || {
        echo "Error: Checksum verification failed!"
        exit 1
    }
    cd - > /dev/null
    echo "Checksum verified successfully"
fi

echo "=== Quest VPN Restore ==="
echo "Backup file: ${BACKUP_FILE}"
echo "Restore directory: ${RESTORE_DIR}"
echo ""

# Confirm restore
read -p "This will stop all VPN services and restore from backup. Continue? (yes/no): " confirm
if [ "${confirm}" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Create restore staging area
STAGING_DIR=$(mktemp -d)
trap "rm -rf ${STAGING_DIR}" EXIT

# Extract backup
echo "Extracting backup..."
tar -xzf "${BACKUP_DIR}/${BACKUP_FILE}" -C "${STAGING_DIR}"

# Show backup metadata
if [ -f "${STAGING_DIR}/backup_metadata.txt" ]; then
    echo ""
    echo "=== Backup Metadata ==="
    cat "${STAGING_DIR}/backup_metadata.txt"
    echo "======================="
    echo ""
fi

# Stop running services
echo "Stopping VPN services..."
cd "${RESTORE_DIR}/docker/west" && docker compose down 2>/dev/null || true
cd "${RESTORE_DIR}/docker/east" && docker compose down 2>/dev/null || true

# Restore WireGuard configurations
if [ -d "${STAGING_DIR}/wireguard" ]; then
    echo "Restoring WireGuard configurations..."
    # Note: Container must be started to copy files
    cd "${RESTORE_DIR}/docker/west" && docker compose up -d wg-easy 2>/dev/null || true
    cd "${RESTORE_DIR}/docker/east" && docker compose up -d wg-easy 2>/dev/null || true
    sleep 5
    
    [ -d "${STAGING_DIR}/wireguard/west" ] && docker cp "${STAGING_DIR}/wireguard/west" wg-easy-west:/etc/wireguard || true
    [ -d "${STAGING_DIR}/wireguard/east" ] && docker cp "${STAGING_DIR}/wireguard/east" wg-easy-east:/etc/wireguard || true
fi

# Restore AdGuard Home configurations
if [ -d "${STAGING_DIR}/adguard" ]; then
    echo "Restoring AdGuard Home configurations..."
    cd "${RESTORE_DIR}/docker/west" && docker compose up -d adguard 2>/dev/null || true
    cd "${RESTORE_DIR}/docker/east" && docker compose up -d adguard 2>/dev/null || true
    sleep 5
    
    [ -d "${STAGING_DIR}/adguard/west-conf" ] && docker cp "${STAGING_DIR}/adguard/west-conf" adguard-west:/opt/adguardhome/conf || true
    [ -d "${STAGING_DIR}/adguard/east-conf" ] && docker cp "${STAGING_DIR}/adguard/east-conf" adguard-east:/opt/adguardhome/conf || true
fi

# Restore Unbound configurations
if [ -d "${STAGING_DIR}/unbound" ]; then
    echo "Restoring Unbound configurations..."
    [ -d "${STAGING_DIR}/unbound/west" ] && cp -r "${STAGING_DIR}/unbound/west"/* "${RESTORE_DIR}/docker/west/unbound/" || true
    [ -d "${STAGING_DIR}/unbound/east" ] && cp -r "${STAGING_DIR}/unbound/east"/* "${RESTORE_DIR}/docker/east/unbound/" || true
fi

# Restore peer configurations
if [ -d "${STAGING_DIR}/peers" ]; then
    echo "Restoring peer configurations..."
    mkdir -p "${RESTORE_DIR}/peers"
    cp -r "${STAGING_DIR}/peers"/* "${RESTORE_DIR}/peers/" || true
fi

# Restart all services
echo "Restarting all services..."
cd "${RESTORE_DIR}/docker/west" && docker compose restart
cd "${RESTORE_DIR}/docker/east" && docker compose restart

# Verify services are running
echo ""
echo "Verifying service status..."
sleep 10
docker ps --filter "name=wg-easy" --filter "name=adguard" --filter "name=unbound"

echo ""
echo "=== Restore Complete ==="
echo "All services have been restored from backup"
echo "Please verify functionality with: ${RESTORE_DIR}/scripts/healthcheck.sh"
