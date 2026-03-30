# Peers Directory

This directory stores WireGuard peer configurations and QR codes.

## Structure

```
peers/
├── README.md          # This file
├── .gitkeep          # Keep directory in git
├── revoked/          # Archived revoked peer configs
└── *.conf            # Peer configuration files (generated)
└── *.png             # QR code exports (generated)
```

## Usage

### Generate a New Peer

```bash
cd /opt/questvpn/scripts
./gen-peer.sh <peer-name> <region>
```

Example:
```bash
./gen-peer.sh my-quest-1 west
```

This creates:
- `/opt/questvpn/peers/my-quest-1.conf` - WireGuard configuration file

### Export QR Code

```bash
./export-peer.sh <peer-name>
```

This creates:
- `/opt/questvpn/peers/my-quest-1.png` - QR code for easy import

### Revoke a Peer

```bash
./revoke-peer.sh <peer-name> <region>
```

This moves the peer config and QR code to `peers/revoked/` directory.

## Security Notes

⚠️ **Important**: Peer configuration files contain private keys and should be treated as sensitive data.

- Do NOT commit `.conf` or `.png` files to version control
- Do NOT share peer configurations publicly
- Store backups securely
- Revoke peers that are no longer in use

## File Format

Each peer configuration file follows the WireGuard format:

```ini
[Interface]
PrivateKey = <private-key>
Address = 10.2.0.X/32
DNS = 10.2.0.2

[Peer]
PublicKey = <server-public-key>
PresharedKey = <preshared-key>
Endpoint = vpn-server.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## Importing to Meta Quest

### Method 1: QR Code (Recommended)

1. Generate QR code with `export-peer.sh`
2. Transfer PNG to your computer
3. Open WireGuard app on Quest
4. Select "Scan from QR code"
5. Display QR code on screen and scan

### Method 2: File Transfer

1. Transfer `.conf` file to Quest via ADB:
   ```bash
   adb push my-quest-1.conf /sdcard/Download/
   ```
2. Open WireGuard app on Quest
3. Select "Import from file or archive"
4. Navigate to Downloads and select the `.conf` file

### Method 3: Manual Entry

1. Open the `.conf` file on your computer
2. In WireGuard app on Quest, select "Create from scratch"
3. Manually enter each field from the configuration

## Troubleshooting

### Peer Not Connecting

1. Verify peer is added to server:
   ```bash
   docker exec wg-easy-west wg show
   ```

2. Check if public key matches:
   ```bash
   grep PublicKey peers/my-quest-1.conf
   ```

3. Regenerate if needed:
   ```bash
   ./revoke-peer.sh my-quest-1 west
   ./gen-peer.sh my-quest-1-new west
   ```

### QR Code Won't Scan

- Ensure QR code is clear and well-lit
- Try displaying at full screen
- Increase screen brightness
- Generate a new QR code

## Peer Naming Conventions

Recommended naming patterns:

- `quest-<username>-<number>` - e.g., `quest-john-1`
- `<location>-<device>-<number>` - e.g., `home-quest2-1`
- `<purpose>-<identifier>` - e.g., `gaming-headset-1`

Choose consistent, descriptive names for easy management.

## Backup and Recovery

### Backup All Peers

```bash
# Create backup archive
tar -czf peers-backup-$(date +%Y%m%d).tar.gz /opt/questvpn/peers/

# Copy to secure location
scp peers-backup-*.tar.gz user@backup-server:/backups/
```

### Restore from Backup

```bash
# Extract backup
tar -xzf peers-backup-20240101.tar.gz -C /opt/questvpn/

# Verify files
ls -la /opt/questvpn/peers/
```

## Automation

### Auto-expire Old Peers

Create a cron job to archive peers older than 90 days:

```bash
# /etc/cron.weekly/cleanup-old-peers
#!/bin/bash
find /opt/questvpn/peers -name "*.conf" -mtime +90 -exec mv {} /opt/questvpn/peers/revoked/ \;
```

### Monitor Peer Count

```bash
# Check number of active peers
ls -1 /opt/questvpn/peers/*.conf 2>/dev/null | wc -l

# Check number of revoked peers
ls -1 /opt/questvpn/peers/revoked/*.conf 2>/dev/null | wc -l
```

## Best Practices

✅ Generate unique peer for each device
✅ Use descriptive names
✅ Keep backup of configurations
✅ Revoke unused peers promptly
✅ Rotate peers periodically (every 6-12 months)
✅ Document peer assignments

❌ Don't share peers between devices
❌ Don't commit configs to public repositories
❌ Don't leave test/temporary peers active
❌ Don't use default/predictable names
