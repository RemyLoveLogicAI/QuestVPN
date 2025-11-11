# Always-On ADB over WiFi

## Overview

Enable persistent ADB (Android Debug Bridge) over WiFi on your Meta Quest, allowing wireless debugging and configuration without USB cables.

## Why Always-On ADB?

✅ Wirelessly sideload apps and updates  
✅ Debug and test without cables  
✅ Remote configuration and scripting  
✅ Integration with automation tools  
✅ Easier WireGuard configuration management  

⚠️ **Security Warning**: ADB over WiFi can be a security risk if exposed to untrusted networks. Use only on trusted networks or through VPN.

## Prerequisites

- Meta Quest with Developer Mode enabled
- USB cable (for initial setup)
- Computer with ADB tools installed
- Quest and computer on same network

## Initial Setup

### Step 1: Enable ADB over WiFi

Connect your Quest via USB and enable wireless debugging:

```bash
# Connect via USB
adb devices

# Enable TCP/IP on port 5555
adb tcpip 5555

# Disconnect USB cable
```

### Step 2: Find Quest IP Address

#### Method A: From Quest Settings
1. Put on your Quest
2. Go to Settings → Wi-Fi
3. Click on your connected network
4. Note the IP address (e.g., 192.168.1.100)

#### Method B: Via ADB (while USB connected)
```bash
adb shell ip addr show wlan0 | grep inet
```

### Step 3: Connect Wirelessly

```bash
# Connect to Quest over WiFi
adb connect 192.168.1.100:5555

# Verify connection
adb devices
```

You should see:
```
192.168.1.100:5555    device
```

## Making It Persistent

ADB over WiFi resets after Quest reboots. Here are methods to make it persistent:

### Method 1: Systemd Service (Quest with Root)

If you have root access, create a systemd service:

```bash
# Connect via ADB
adb shell

# Create service file
su
cat > /system/etc/systemd/system/adb-wifi.service <<EOF
[Unit]
Description=ADB over WiFi
After=network.target

[Service]
Type=oneshot
ExecStart=/system/bin/setprop service.adb.tcp.port 5555
ExecStart=/system/bin/stop adbd
ExecStart=/system/bin/start adbd
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl enable adb-wifi
systemctl start adb-wifi
```

### Method 2: Init Script (Alternative)

Create an init script that runs on boot:

```bash
adb shell
su

# Create init script
cat > /data/local/userinit.sh <<EOF
#!/system/bin/sh
setprop service.adb.tcp.port 5555
stop adbd
start adbd
EOF

chmod 755 /data/local/userinit.sh
```

### Method 3: Automated Re-enable Script

If you can't modify system files, create a script to quickly re-enable after reboot:

```bash
#!/bin/bash
# save as enable-quest-adb.sh

QUEST_IP="192.168.1.100"

echo "Connecting to Quest via USB to enable WiFi ADB..."

# Wait for USB connection
adb wait-for-device

# Enable TCP/IP
adb tcpip 5555

echo "Waiting for Quest to switch to WiFi mode..."
sleep 3

# Connect via WiFi
adb connect $QUEST_IP:5555

echo "Connected! You can disconnect USB now."
adb devices
```

Run this script after each Quest reboot.

### Method 4: Tasker/Automation App (Non-Root)

Use an automation app on Quest (sideload Tasker):

1. Sideload Tasker APK
2. Create profile: Event → System → Boot
3. Add task: Run Shell → `setprop service.adb.tcp.port 5555 && stop adbd && start adbd`
4. Requires Tasker to have appropriate permissions

## Integration with Quest VPN

### Secure Remote Access via VPN

Access your Quest's ADB remotely through VPN:

1. Configure Quest with WireGuard VPN
2. Enable ADB over WiFi
3. Connect to VPN from remote computer
4. Access Quest via its VPN IP (10.2.0.X:5555)

```bash
# From remote computer connected to same VPN
adb connect 10.2.0.50:5555
```

**Benefit**: Secure remote management from anywhere!

### Local Network + VPN Split Tunnel

Keep local ADB access while routing other traffic through VPN:

1. Configure split-tunnel (see [split-tunnel.md](split-tunnel.md))
2. Exclude local network from VPN routing
3. ADB works on local IP, apps use VPN

## Managing WireGuard via ADB

### Push Configuration Files

```bash
# Push new WireGuard config
adb push myquest.conf /sdcard/Download/

# Import via command line
adb shell am start -a android.intent.action.VIEW \
  -d file:///sdcard/Download/myquest.conf \
  -t application/x-wireguard-config
```

### Enable/Disable VPN

```bash
# Enable WireGuard tunnel
adb shell am start -n com.wireguard.android/.activity.MainActivity

# Via intent (if tunnel named "quest-vpn")
adb shell am broadcast -a com.wireguard.android.action.SET_TUNNEL_UP \
  --es tunnel quest-vpn
```

### Check VPN Status

```bash
# Get WireGuard status
adb shell wg show
```

## Useful ADB Commands for Quest

### Package Management

```bash
# List installed packages
adb shell pm list packages

# Install APK
adb install app.apk

# Uninstall app
adb uninstall com.example.app
```

### System Information

```bash
# Battery status
adb shell dumpsys battery

# Network status
adb shell ip addr show

# Running services
adb shell dumpsys activity services
```

### File Operations

```bash
# Pull files from Quest
adb pull /sdcard/Download/file.txt ./

# Push files to Quest
adb push file.txt /sdcard/Download/

# List directory
adb shell ls -la /sdcard/
```

### Debugging

```bash
# View logs (filter for WireGuard)
adb logcat | grep WireGuard

# Screen capture
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png
```

## Security Best Practices

### 1. Use Only on Trusted Networks

Never enable ADB over WiFi on public WiFi without additional security:
```bash
# Disable when not needed
adb -s 192.168.1.100:5555 usb
```

### 2. Firewall ADB Port

On your router, block port 5555 from WAN:
```
# UFW on Linux router
ufw deny from any to any port 5555
ufw allow from 192.168.1.0/24 to any port 5555
```

### 3. Use VPN Tunnel for Remote Access

Always access ADB remotely through VPN, never expose port 5555 to internet:
```bash
# Don't do this:
# adb connect public-ip:5555

# Do this instead:
# Connect to VPN first, then:
adb connect 10.2.0.50:5555
```

### 4. Monitor Connections

Regularly check for unauthorized connections:
```bash
adb shell netstat -tn | grep :5555
```

## Troubleshooting

### Connection Refused

```bash
# Re-enable ADB via USB
adb usb
adb tcpip 5555
adb connect <quest-ip>:5555
```

### Quest IP Changed

```bash
# Find new IP
adb shell ip addr show wlan0 | grep inet

# Or check router DHCP leases
```

### Multiple Devices Conflict

```bash
# List all devices
adb devices

# Specify device
adb -s 192.168.1.100:5555 shell
```

### Connection Drops Frequently

- Check WiFi signal strength
- Disable WiFi power saving on Quest
- Use static IP for Quest (configure in router)

### Works After Boot, Then Stops

- ADB TCP mode resets after sleep/reboot
- Use persistent methods above
- Or create quick re-enable script

## Alternative: Wireless Debugging (Android 11+)

Quest OS (based on Android) may support newer wireless debugging:

```bash
# Check if available
adb shell pm list features | grep wireless

# If available, use pairing
adb pair <quest-ip>:<pairing-port>
```

## Automation Scripts

### Auto-Connect on Quest Power On

```bash
#!/bin/bash
# auto-connect-quest.sh

QUEST_IP="192.168.1.100"

while true; do
  if ! adb devices | grep -q "$QUEST_IP"; then
    echo "Quest not connected, attempting to connect..."
    adb connect $QUEST_IP:5555 2>/dev/null
  fi
  sleep 30
done
```

Run in background:
```bash
chmod +x auto-connect-quest.sh
nohup ./auto-connect-quest.sh &
```

### Push WireGuard Config and Enable

```bash
#!/bin/bash
# deploy-wireguard.sh

QUEST_IP="192.168.1.100"
CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
  echo "Usage: $0 <config-file.conf>"
  exit 1
fi

# Connect to Quest
adb connect $QUEST_IP:5555

# Push config
adb push "$CONFIG_FILE" /sdcard/Download/

# Import into WireGuard
CONFIG_NAME=$(basename "$CONFIG_FILE" .conf)
adb shell am start -a android.intent.action.VIEW \
  -d file:///sdcard/Download/$(basename "$CONFIG_FILE") \
  -t application/x-wireguard-config

echo "Config deployed! Import it in WireGuard app."
```

## Next Steps

- [Split Tunnel Configuration](split-tunnel.md) - Optimize routing
- [Troubleshooting](troubleshooting.md) - Common issues
- [Quest Sideload Guide](quest-sideload.md) - Install WireGuard
