# Meta Quest WireGuard Sideload Guide

## Overview

This guide walks you through installing WireGuard on your Meta Quest device using sideloading, since WireGuard is not available on the official Quest store.

## Prerequisites

- Meta Quest headset (Quest 1, 2, 3, or Pro)
- Computer with USB cable
- Developer mode enabled on Quest
- WireGuard APK for Android
- Either SideQuest or WebADB

## Method 1: SideQuest (Recommended for Beginners)

### Step 1: Enable Developer Mode

1. Open the Meta Quest mobile app
2. Go to Menu → Devices → Select your headset
3. Tap "Developer Mode" and toggle it ON
4. You may need to create a developer account at developer.oculus.com

### Step 2: Install SideQuest

1. Download SideQuest from https://sidequestvr.com/
2. Install and run SideQuest on your computer
3. Connect your Quest to your computer via USB
4. Put on your headset and approve the USB debugging prompt

### Step 3: Download WireGuard APK

1. Download the WireGuard APK from:
   - Official: https://download.wireguard.com/android-client/
   - F-Droid: https://f-droid.org/packages/com.wireguard.android/
2. Choose the latest stable release (e.g., `wireguard-amd64-*.apk` or `wireguard-arm64-*.apk`)
3. For Quest, use the **arm64-v8a** variant

### Step 4: Sideload with SideQuest

1. Open SideQuest
2. Click the "Install APK" button (folder icon in top right)
3. Select the WireGuard APK you downloaded
4. Wait for installation to complete
5. WireGuard will appear in "Unknown Sources" in your Quest library

## Method 2: WebADB (No Software Installation)

### Step 1: Enable Developer Mode

Same as Method 1, Step 1

### Step 2: Connect via WebADB

1. Visit https://app.webadb.com/ in Chrome or Edge (Chromium-based browser required)
2. Connect your Quest via USB
3. Click "Add Device" and select your Quest
4. Approve USB debugging on your headset

### Step 3: Install WireGuard

1. Download WireGuard APK (arm64-v8a variant)
2. In WebADB, go to "Apps" tab
3. Click "Install APK"
4. Select the WireGuard APK
5. Wait for installation to complete

## Method 3: ADB Command Line (Advanced)

### Prerequisites
- ADB tools installed on your computer
- USB debugging enabled on Quest

### Steps

```bash
# Download WireGuard APK
wget https://download.wireguard.com/android-client/com.wireguard.android-[version].apk

# Connect Quest and verify
adb devices

# Install APK
adb install com.wireguard.android-[version].apk

# Launch WireGuard
adb shell am start -n com.wireguard.android/.activity.MainActivity
```

## Configuring WireGuard on Quest

### Option A: Import via QR Code (Easiest)

1. Generate QR code on your server:
   ```bash
   /opt/questvpn/scripts/export-peer.sh my-quest-1
   ```

2. Display the QR code on your computer screen

3. In Quest:
   - Launch WireGuard from "Unknown Sources"
   - Tap the "+" button
   - Select "Scan from QR code"
   - Look at your computer screen to scan the QR code
   - Name your tunnel and save

### Option B: Manual Configuration

1. Transfer the `.conf` file to Quest:
   ```bash
   adb push /opt/questvpn/peers/my-quest-1.conf /sdcard/Download/
   ```

2. In Quest:
   - Launch WireGuard
   - Tap "+" → "Create from file or archive"
   - Navigate to Downloads and select your `.conf` file

### Option C: Manual Entry

If you prefer to type the configuration:

1. Launch WireGuard on Quest
2. Tap "+" → "Create from scratch"
3. Enter the configuration from your peer `.conf` file:

```
[Interface]
PrivateKey = <your-private-key>
Address = 10.2.0.X/32
DNS = 10.2.0.2

[Peer]
PublicKey = <server-public-key>
Endpoint = vpn-west.example.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## Testing the Connection

1. Enable the WireGuard tunnel in the app
2. You should see a "handshake" timestamp
3. Test connectivity:
   - Open Quest Browser
   - Visit https://www.whatismyip.com/
   - Verify your IP matches your VPN server

## Performance Tips

1. **MTU Optimization**: Run `mtu-autotune.sh` on your server for optimal packet size
2. **Choose Nearest Region**: Use west/east region based on your location
3. **Always-On**: Enable "Always-On VPN" in WireGuard settings
4. **Exclude Local**: Use split-tunneling to exclude local network traffic

## Troubleshooting

### WireGuard Not Appearing in Library

- Check "Unknown Sources" in your Quest library (not main Apps)
- Try restarting your Quest headset

### APK Installation Failed

- Ensure you downloaded the arm64-v8a variant
- Check that developer mode is enabled
- Try re-approving USB debugging

### Connection Timeout

- Verify firewall allows UDP 51820
- Check server is running: `docker ps`
- Verify endpoint address in config

### No Internet Access

- Check DNS setting (should be 10.2.0.2)
- Verify AdGuard Home is running
- Test with alternative DNS: 1.1.1.1

## Updating WireGuard

To update WireGuard to a newer version:

1. Download the new APK
2. Sideload it using the same method (it will upgrade)
3. Your configurations will be preserved

## Uninstalling

From Quest:
- Settings → Apps → Unknown Sources → WireGuard → Uninstall

Or via ADB:
```bash
adb uninstall com.wireguard.android
```

## Security Notes

- ✅ WireGuard uses ChaCha20-Poly1305 encryption
- ✅ All traffic is encrypted through the VPN tunnel
- ✅ DNS queries are protected via AdGuard Home
- ⚠️ Sideloading requires developer mode (accept security implications)
- ⚠️ Only download WireGuard from official sources

## Next Steps

- [Split Tunnel Configuration](split-tunnel.md) - Route only specific apps through VPN
- [Always-On ADB](always-on-adb.md) - Enable wireless ADB for easier management
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
