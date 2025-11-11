# Meta Quest WireGuard Sideloading Guide

This guide walks you through installing the WireGuard app on your Meta Quest device and configuring your VPN profiles.

## Prerequisites

- Meta Quest 2, 3, or Pro
- Meta Quest mobile app (iOS or Android)
- Computer with USB-C cable
- Developer Mode enabled on Quest

## Step 1: Enable Developer Mode

### Via Meta Quest Mobile App

1. Open the **Meta Quest** mobile app
2. Tap **Menu** (bottom right)
3. Select **Devices** → Select your Quest headset
4. Tap **Headset Settings**
5. Scroll down to **Developer Mode**
6. Toggle **Developer Mode** to ON
7. Accept the developer agreement if prompted

**Note:** You may need to create or join a developer organization at [Meta Developer](https://developer.oculus.com/)

### Verify Developer Mode

Put on your headset:
1. Go to **Settings** → **System** → **Developer**
2. You should see developer options available

## Step 2: Enable USB Debugging

1. Connect Quest to computer via USB-C cable
2. Put on your headset
3. You'll see a prompt: **Allow USB debugging?**
4. Check **Always allow from this computer**
5. Tap **OK**

## Step 3: Install WireGuard App

### Method A: SideQuest (Recommended)

**Install SideQuest:**

1. Download from [SideQuestvr.com](https://sidequestvr.com/)
2. Install on your computer (Windows, Mac, or Linux)
3. Launch SideQuest

**Connect Quest:**

1. Connect Quest to computer via USB
2. SideQuest should show "Connected" in top-left corner
3. If not, check USB debugging is allowed

**Install WireGuard:**

1. Download WireGuard Android APK:
   ```bash
   wget https://download.wireguard.com/android-client/com.wireguard.android-latest.apk
   ```

2. In SideQuest, click the folder icon (top-right)
3. Navigate to downloaded APK file
4. Click **Open** - installation will begin
5. Wait for "Successfully installed" message

**Verify Installation:**

1. Put on Quest headset
2. Open **App Library**
3. Click **All** dropdown → Select **Unknown Sources**
4. You should see **WireGuard** app

### Method B: WebADB (Browser-Based)

**Requirements:**
- Chrome or Edge browser (other browsers may not work)
- USB cable connection

**Steps:**

1. Visit [app.webadb.com](https://app.webadb.com/)
2. Connect Quest via USB
3. Click **Add Device** → Select your Quest
4. Allow USB debugging on Quest headset

5. Download WireGuard APK:
   ```bash
   wget https://download.wireguard.com/android-client/com.wireguard.android-latest.apk
   ```

6. In WebADB, click **Install APK**
7. Select the downloaded APK file
8. Wait for installation to complete

### Method C: ADB Command Line (Advanced)

**Install ADB:**

- **Windows:** Download [Platform Tools](https://developer.android.com/studio/releases/platform-tools)
- **Mac:** `brew install android-platform-tools`
- **Linux:** `sudo apt-get install android-tools-adb`

**Install WireGuard:**

```bash
# Download APK
wget https://download.wireguard.com/android-client/com.wireguard.android-latest.apk

# Connect via ADB
adb devices

# Should show your Quest device
# Example: 1WMHH1234ABCD    device

# Install APK
adb install com.wireguard.android-latest.apk

# Verify installation
adb shell pm list packages | grep wireguard
```

## Step 4: Configure WireGuard

### Import via QR Code (Easiest)

1. Generate peer config with QR code:
   ```bash
   ./scripts/gen-peer.sh quest-user both full
   ```

2. Display QR code on computer screen:
   - Open `peers/quest-user.west.qr.png` in image viewer
   - Or display ASCII QR: `cat peers/quest-user.west.qr.txt`

3. Put on Quest headset
4. Open **WireGuard** app (App Library → Unknown Sources)
5. Tap **+** button (bottom-right)
6. Select **Create from QR code**
7. Point Quest controllers at QR code on screen
8. Name the tunnel: **Quest West**
9. Tap **Create Tunnel**

10. Repeat for east region:
    - Display `peers/quest-user.east.qr.png`
    - Create from QR code
    - Name: **Quest East**

### Import via File (Alternative)

If QR code scanning doesn't work:

1. Copy config files to Quest:
   ```bash
   # Using ADB
   adb push peers/quest-user.west.conf /sdcard/Download/
   adb push peers/quest-user.east.conf /sdcard/Download/
   ```

2. In Quest WireGuard app:
   - Tap **+** button
   - Select **Create from file or archive**
   - Navigate to **Downloads** folder
   - Select `quest-user.west.conf`
   - Name: **Quest West**

3. Repeat for east config

### Manual Entry (Last Resort)

1. In WireGuard app, tap **+** → **Create from scratch**
2. Enter configuration from `peers/quest-user.west.conf`
3. Copy/paste each section carefully

## Step 5: Connect to VPN

### First Connection

1. Open WireGuard app
2. Select **Quest West** (or East)
3. Tap the toggle switch
4. **First time only:** Tap **OK** to allow VPN connection
5. Check **Don't ask again**
6. Status should show **Connected**

### Verify Connection

**Check public IP:**
1. Open Meta Quest Browser
2. Visit: `https://ifconfig.me/`
3. Should display your VPN server IP (not home IP)

**Check DNS leak:**
1. Visit: `https://dnsleaktest.com/`
2. Run **Standard test**
3. Should only show your VPN server location
4. No ISP DNS servers should appear

**Test ad blocking:**
1. Visit: `https://ads-blocker.com/testing/`
2. Most ads should be blocked (AdGuard in action)

## Step 6: Configure Per-App Split Tunneling

### Why Use Split Tunneling?

- **Performance:** Keep local apps off VPN for lower latency
- **Compatibility:** Some apps work better without VPN
- **LAN access:** Access local network devices (casting, file shares)

### Configuration

1. In WireGuard app, tap the **gear icon** next to your tunnel
2. Scroll down to **Applications**
3. Select mode:
   - **Exclude:** All apps use VPN except selected (recommended)
   - **Include:** Only selected apps use VPN

### Recommended Exclusions (Exclude Mode)

Exclude these apps for better local functionality:

- **Meta Home** - Quest system interface
- **Meta TV** - Local media streaming
- **Oculus Browser** - Keep on VPN for privacy
- **File Manager** - Local file access
- **Gallery** - Local photos/videos
- Any local network apps (Plex, file shares, etc.)

### Recommended Inclusions (Include Mode)

If using Include mode, add:

- **Oculus Browser** - Web browsing with privacy
- **YouTube VR** - Streaming content
- **Any apps requiring geo-unblocking**
- **Games with multiplayer** (may help with some regions)

## Step 7: Switch Between Regions

### When to Use Each Region

**West Region (Hillsboro, OR):**
- Better for West Coast, Asia-Pacific
- Lower latency to western servers
- Use for US west coast content

**East Region (Ashburn, VA):**
- Better for East Coast, Europe
- Lower latency to eastern servers
- Use for US east coast content

### Switching

1. Open WireGuard app
2. Toggle **OFF** current region
3. Toggle **ON** desired region
4. Wait 5-10 seconds for connection

## Troubleshooting

### Cannot Connect

**Check 1: Internet connectivity**
- Ensure Quest has Wi-Fi connection
- Test by opening Browser without VPN

**Check 2: Server reachability**
- Verify server is running: `./scripts/healthcheck.sh west`
- Check if ports 51820 or 443 are blocked by your network

**Check 3: Configuration**
- Verify DNS is set to `10.2.0.2`
- Check AllowedIPs is `0.0.0.0/0, ::/0` for full tunnel

### Connected But No Internet

**Issue:** Connected but can't browse

**Solutions:**
1. Check AdGuard → Unbound DNS chain on server
2. Run: `./scripts/healthcheck.sh west`
3. Verify AdGuard upstream is set to `10.2.0.3:53`
4. Restart AdGuard: `docker compose restart adguard`

### Slow Performance

**Check 1: MTU optimization**
```bash
./scripts/mtu-autotune.sh west
```
Update your config with recommended MTU value

**Check 2: Try alternate port**
- Edit tunnel in WireGuard app
- Change endpoint port from `51820` to `443`
- Some networks prioritize HTTPS port

**Check 3: Switch regions**
- Try the other region (east vs west)
- Geographic proximity affects latency

### DNS Leaks Detected

**Fix 1: Verify DNS setting**
- Edit tunnel
- Ensure **DNS** field is `10.2.0.2`
- Not public resolver (8.8.8.8, 1.1.1.1, etc.)

**Fix 2: Disable Private DNS**
- Quest Settings → Network → Advanced
- Disable Private DNS if enabled

### Quest Disconnects VPN

**Issue:** VPN randomly disconnects

**Solutions:**

1. **Increase PersistentKeepalive:**
   - Edit tunnel
   - Set PersistentKeepalive to `15` (more aggressive)

2. **Disable power saving:**
   - Quest Settings → Device → Power
   - Adjust sleep timer

3. **Check Wi-Fi stability:**
   - Move closer to router
   - Use 5GHz band if available

### Cannot Scan QR Code

**Solution 1: Increase brightness**
- Increase computer screen brightness
- Display QR code full-screen

**Solution 2: Print QR code**
- Print the PNG file
- Scan from paper

**Solution 3: Use file import**
- Copy .conf file to Quest via ADB
- Import from file instead

## Advanced Configuration

### Always-On VPN (Experimental)

See [ALWAYS_ON_ADB.md](ALWAYS_ON_ADB.md) for firmware-specific commands.

### Kill Switch (Block Without VPN)

WireGuard on Quest doesn't support native kill switch, but you can:

1. Use **Always-On VPN** (if supported)
2. Monitor connection in WireGuard app
3. Close apps if VPN disconnects

### Multiple Profiles

Create specialized profiles:

```bash
# Streaming profile (full tunnel)
./scripts/gen-peer.sh quest-streaming west full

# Gaming profile (split tunnel)
./scripts/gen-peer.sh quest-gaming east split

# Privacy profile (full tunnel, alternate port)
./scripts/gen-peer.sh quest-privacy both full
```

## Maintenance

### Update WireGuard App

1. Download latest APK from wireguard.com
2. Install via SideQuest (overwrites existing)
3. Configurations are preserved

### Regenerate Configs

If server keys change:

```bash
# Delete old configs from Quest
# Generate new ones
./scripts/gen-peer.sh quest-user both full

# Import new QR codes
```

### Backup Configurations

Export configs before factory reset:

```bash
# Via ADB
adb pull /data/data/com.wireguard.android/files/ quest-backup/
```

## FAQ

**Q: Do I need to sideload every time I factory reset?**
A: Yes, sideloaded apps are removed on factory reset.

**Q: Will this affect my Quest warranty?**
A: No, developer mode and sideloading don't void warranty.

**Q: Can I use this with Meta Link (PCVR)?**
A: Yes, works with both standalone and Link modes.

**Q: Does this drain battery faster?**
A: Minimal impact. VPN overhead is negligible.

**Q: Can I use this on Quest 1?**
A: Yes, process is identical for all Quest models.

**Q: Will Meta remove my sideloaded apps?**
A: No, sideloaded apps persist through updates.

## Support

- **Detailed troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Split tunnel strategies:** [SPLIT_TUNNEL.md](SPLIT_TUNNEL.md)
- **Router alternative:** [ROUTER_CLIENT.md](ROUTER_CLIENT.md)

---

**Enjoy private, secure VR browsing on your Meta Quest!**
