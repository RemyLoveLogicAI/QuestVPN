# Always-On VPN Configuration via ADB

Enable always-on VPN mode on Meta Quest using ADB commands.

## ⚠️ Important Warnings

- **Firmware dependent:** Not all Quest firmware versions support always-on VPN
- **Experimental:** This feature is not officially supported by Meta
- **Risk:** May cause connectivity issues if VPN server is unreachable
- **Requires:** Developer mode and ADB access

## Prerequisites

- Meta Quest with Developer Mode enabled
- ADB installed on computer
- USB cable or wireless ADB connection
- WireGuard already configured on Quest

## Supported Firmware

**Known to work:**
- Quest OS v57 and newer (2023+)

**Known issues:**
- Some Quest 2 firmware versions lack VPN lockdown support
- Quest 1 support varies

**Check your version:**
1. Quest Settings → System → About
2. Note your software version

## Step 1: Enable ADB Connection

### Via USB

```bash
# Connect Quest via USB cable
# Allow USB debugging on Quest headset

# Verify connection
adb devices

# Should show:
# 1WMHH1234ABCD    device
```

### Via Wireless ADB (Optional)

```bash
# Get Quest IP address
# Quest Settings → Wi-Fi → Current Network → Advanced

# Connect wirelessly
adb connect <quest-ip>:5555

# Example:
adb connect 192.168.1.100:5555

# Verify
adb devices
```

## Step 2: Identify WireGuard Package

```bash
# List WireGuard tunnels
adb shell pm list packages | grep wireguard

# Output:
# package:com.wireguard.android
```

## Step 3: Enable Always-On VPN

### Command

```bash
# Enable Always-On for WireGuard
adb shell settings put secure vpn_always_on com.wireguard.android

# Verify setting
adb shell settings get secure vpn_always_on

# Should output:
# com.wireguard.android
```

### What This Does

- **Automatic reconnection:** VPN reconnects if disconnected
- **No manual toggle:** VPN starts on boot
- **Fallback:** May allow traffic if VPN fails (depends on lockdown)

## Step 4: Enable VPN Lockdown (Kill Switch)

### Command

```bash
# Enable VPN lockdown
adb shell settings put secure vpn_lockdown 1

# Verify setting
adb shell settings get secure vpn_lockdown

# Should output:
# 1
```

### What This Does

- **Block non-VPN traffic:** No internet if VPN disconnects
- **True kill switch:** Prevents leaks
- **Warning:** If VPN server is down, no internet access

## Step 5: Set Default Tunnel

WireGuard needs to know which tunnel to use automatically.

```bash
# Open WireGuard app on Quest
# Note the tunnel name (e.g., "Quest West")

# There's no direct ADB command to set default tunnel
# You must:
# 1. Open WireGuard app
# 2. Enable desired tunnel
# 3. Always-On will use the last connected tunnel
```

## Step 6: Test Configuration

### Reboot Quest

```bash
# Reboot via ADB
adb reboot

# Or use Quest UI:
# Hold power button → Restart
```

### Verify After Reboot

1. Put on Quest headset
2. Open WireGuard app
3. Should show **Connected** automatically
4. Check public IP: `https://ifconfig.me/`

## Disable Always-On VPN

### If You Need to Disable

```bash
# Disable VPN lockdown first
adb shell settings put secure vpn_lockdown 0

# Then disable Always-On
adb shell settings delete secure vpn_always_on

# Verify
adb shell settings get secure vpn_always_on

# Should output: null
```

## Troubleshooting

### Quest Has No Internet After Enabling

**Issue:** Lockdown enabled but VPN can't connect

**Solution 1: Disable lockdown temporarily**
```bash
adb shell settings put secure vpn_lockdown 0
```

**Solution 2: Fix VPN config**
- Check server is reachable
- Verify credentials
- Test manual connection first

### Always-On Not Working

**Issue:** VPN doesn't reconnect automatically

**Check 1: Verify setting**
```bash
adb shell settings get secure vpn_always_on
# Should output: com.wireguard.android
```

**Check 2: Firmware support**
- Some firmware versions don't support this
- Try updating Quest OS

**Check 3: Battery optimization**
```bash
# Disable battery optimization for WireGuard
adb shell dumpsys deviceidle whitelist +com.wireguard.android
```

### VPN Connects But Apps Don't Work

**Issue:** VPN connected, but internet fails

**Check DNS:**
- Ensure DNS is set to 10.2.0.2 in tunnel config
- Run healthcheck: `./scripts/healthcheck.sh west`

### Cannot Disable Always-On

**Issue:** Settings command fails

**Solution: Reset via UI**
1. Quest Settings → Apps → WireGuard
2. Storage → Clear Data
3. Reinstall WireGuard
4. Reconfigure tunnels

## Advanced Configuration

### Per-App Always-On

WireGuard for Android doesn't support per-app always-on natively. Use split tunneling instead:

1. Enable Always-On for all apps
2. Use App-level exclusions in WireGuard config

### Multiple Tunnels

**Limitation:** Always-On uses the last connected tunnel only.

**Workaround:**
- Use automation apps (Tasker + ADB commands)
- Or manually switch tunnels when needed

### Scheduled Always-On

**Concept:** Enable Always-On only at certain times

**Implementation:**
- Requires automation app with ADB capabilities
- Or custom cron job on a computer

**Example Tasker profile:**
```
Profile: Work Hours
Time: 9:00 AM to 5:00 PM

Task: Enable VPN
- Run shell: settings put secure vpn_always_on com.wireguard.android
- Run shell: settings put secure vpn_lockdown 1

Exit Task: Disable VPN
- Run shell: settings put secure vpn_lockdown 0
- Run shell: settings delete secure vpn_always_on
```

## Firmware-Specific Notes

### Quest 2

- **v57+:** Always-On works
- **v50-56:** Mixed results
- **v49 and older:** Not supported

### Quest 3 / Quest Pro

- **v60+:** Full support
- **Lockdown:** Works reliably

### Quest 1

- **End of life:** Limited support
- **Always-On:** May work, lockdown often fails

## Best Practices

1. **Test without lockdown first**
   - Enable Always-On
   - Don't enable lockdown yet
   - Verify auto-reconnection works

2. **Have fallback**
   - Know how to disable via ADB
   - Keep USB cable handy
   - Document your config

3. **Monitor connection**
   - Check WireGuard app periodically
   - Verify VPN is actually connected

4. **Update regularly**
   - Keep Quest OS updated
   - Update WireGuard app
   - May fix bugs

## When to Use Always-On

**Good use cases:**
- Maximum privacy (public Wi-Fi, travel)
- Parental controls (force VPN for kids)
- Corporate deployment

**Bad use cases:**
- Unstable VPN server
- Unreliable internet connection
- Need frequent region switching

## Alternatives to Always-On

If Always-On doesn't work or isn't suitable:

### Option 1: Manual Connection
- Open WireGuard app on boot
- Toggle VPN on
- Simple and reliable

### Option 2: Router VPN
- Use GL.iNet router as VPN client
- Quest automatically uses VPN via Wi-Fi
- See [ROUTER_CLIENT.md](ROUTER_CLIENT.md)

### Option 3: Automation App
- Use Tasker or similar
- Auto-toggle VPN based on triggers
- More flexible but complex

## Monitoring Always-On Status

### Check Current Status

```bash
# Check Always-On setting
adb shell settings get secure vpn_always_on

# Check lockdown setting
adb shell settings get secure vpn_lockdown

# Check active VPN connection
adb shell dumpsys connectivity | grep -i vpn
```

### Create Status Script

```bash
#!/bin/bash
# check-vpn-status.sh

echo "Always-On VPN Status:"
echo "  Package: $(adb shell settings get secure vpn_always_on)"
echo "  Lockdown: $(adb shell settings get secure vpn_lockdown)"
echo ""
echo "Active Connection:"
adb shell dumpsys connectivity | grep -i vpn
```

## Support

- **Quest setup:** [QUEST_SIDELOAD.md](QUEST_SIDELOAD.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Router alternative:** [ROUTER_CLIENT.md](ROUTER_CLIENT.md)

## Disclaimer

This feature is not officially supported by Meta. Use at your own risk. Always have a way to disable if issues occur.

---

**Enjoy automatic VPN protection on your Quest!**
