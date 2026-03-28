# MTU Tuning Guide

Optimize Maximum Transmission Unit (MTU) for best WireGuard performance on Meta Quest.

## What is MTU?

**MTU (Maximum Transmission Unit):** The largest packet size that can be transmitted without fragmentation.

- **Standard Ethernet MTU:** 1500 bytes
- **WireGuard overhead:** ~60-80 bytes
- **Optimal WireGuard MTU:** 1420 bytes (typical)
- **Problem:** Incorrect MTU causes fragmentation and packet loss

## Why MTU Matters for Quest VPN

### Impact of Wrong MTU

**MTU too high:**
- Packets fragmented by network
- Increased latency
- Packet loss
- Poor VR streaming performance

**MTU too low:**
- More packets needed
- Increased overhead
- Lower throughput
- Still works but inefficient

### Optimal MTU Benefits

- **Lower latency:** Less fragmentation
- **Better throughput:** Efficient packet sizes
- **Fewer retransmissions:** Packets fit network path
- **Smoother VR:** Reduced jitter

## Auto-Detection (Recommended)

Our `gen-peer.sh` script automatically detects optimal MTU:

```bash
./scripts/gen-peer.sh quest-user west full
```

**What it does:**
1. Tests packet sizes from 1420 down to 1280
2. Finds largest size that doesn't fragment
3. Sets MTU in generated config

## Manual MTU Testing

### Using mtu-autotune.sh Script

```bash
# Test MTU for specific region
./scripts/mtu-autotune.sh west

# Or specify custom target
./scripts/mtu-autotune.sh east 1.1.1.1
```

**Output example:**
```
Testing MTU 1420 (packet size 1340)... OK
Optimal MTU: 1420

Update your WireGuard configuration with:
  MTU = 1420
```

### Manual Ping Test (Advanced)

From a computer (not Quest directly):

```bash
# Test with Don't Fragment (DF) bit set
# WireGuard overhead is ~80 bytes

# Test 1420 MTU (1340 payload + 80 overhead)
ping -M do -s 1340 -c 3 <vpn-server-ip>

# If fails, try 1400
ping -M do -s 1320 -c 3 <vpn-server-ip>

# If fails, try 1380
ping -M do -s 1300 -c 3 <vpn-server-ip>

# Continue until you find size that works
```

**Interpretation:**
- **Success:** Packets received without fragmentation
- **Failure:** "Message too long" or packet loss
- **Optimal MTU:** Largest working payload + 80

## Network-Specific MTU Values

### Common Scenarios

**Standard home network:**
- MTU: 1420 (WireGuard default)
- Works for most connections

**PPPoE connections (DSL):**
- MTU: 1400 or 1392
- PPPoE adds 8 byte overhead

**Mobile hotspot:**
- MTU: 1400-1380
- Mobile networks often have lower MTU

**Public Wi-Fi / Hotel:**
- MTU: 1380-1360
- May have additional tunneling overhead

**IPv6 tunnels (6in4, 6to4):**
- MTU: 1380 or lower
- IPv6 encapsulation overhead

**VPN over VPN (double hop):**
- MTU: 1360 or lower
- Multiple layers of encapsulation

### By Internet Type

| Connection Type | Recommended MTU |
|----------------|----------------|
| Fiber / Cable | 1420 |
| DSL (PPPoE) | 1392-1400 |
| LTE / 5G | 1400 |
| Satellite | 1350-1380 |
| Public Wi-Fi | 1360-1380 |
| Cellular hotspot | 1380 |

## Configuring MTU

### In WireGuard Config File

Edit your `.conf` file:

```ini
[Interface]
Address = 10.2.0.10/32
DNS = 10.2.0.2
MTU = 1420  # Add or modify this line

[Peer]
PublicKey = <server-public-key>
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### In WireGuard App on Quest

1. Open WireGuard app
2. Tap **gear icon** next to tunnel
3. Edit **Interface** section
4. Add or modify: `MTU = 1420`
5. Save changes
6. Reconnect tunnel

### Regenerate Configs

If using our scripts, regenerate with detected MTU:

```bash
# Delete old config
rm peers/quest-user.west.conf

# Generate new with MTU detection
./scripts/gen-peer.sh quest-user west full

# Import new config to Quest
```

## Testing and Validation

### Test After Changing MTU

1. Connect to VPN with new MTU
2. Run tests below
3. Verify performance improvement

### Latency Test

```bash
# From Quest browser or computer connected to VPN
ping -c 10 8.8.8.8

# Check:
# - Low latency (< 100ms)
# - No packet loss
# - Consistent timing
```

### Throughput Test

```bash
# Speed test via VPN
# Visit: https://fast.com/

# Or use iperf3 (advanced):
iperf3 -c iperf.he.net

# Check:
# - Throughput close to VPN server bandwidth
# - No retransmissions
```

### VR Streaming Test

**Test in VR:**
1. Open YouTube VR or Netflix VR
2. Play 4K video
3. Check for buffering or stuttering

**Expected result with correct MTU:**
- Smooth playback
- No buffering
- Low latency

## Troubleshooting MTU Issues

### Symptom: Slow Speeds

**Possible cause:** MTU too high (fragmentation)

**Solution:**
```bash
# Lower MTU by 20 at a time
# Try: 1420 → 1400 → 1380 → 1360

# Edit config, test each value
MTU = 1380  # Example
```

### Symptom: Connection Drops

**Possible cause:** MTU mismatch

**Check:**
1. Server MTU settings
2. Client MTU settings
3. Should match or be compatible

**Solution:**
```bash
# Ensure client MTU <= server MTU
# Most servers use 1420 by default
```

### Symptom: Some Sites Don't Load

**Possible cause:** Path MTU discovery (PMTUD) blocked

**Solution:**
```bash
# Lower MTU to avoid PMTUD reliance
MTU = 1380  # Lower value
```

### Symptom: High Packet Loss

**Check with ping:**
```bash
# From VPN connection
ping -c 100 8.8.8.8

# If >5% loss, MTU may be wrong
```

**Solution:**
1. Run MTU auto-detection again
2. Try lower values
3. Check network stability

## Advanced: Path MTU Discovery

### What is PMTUD?

**Path MTU Discovery:** Protocol to find optimal MTU for network path

**How it works:**
1. Send packet with DF (Don't Fragment) bit set
2. If too large, router sends ICMP "Fragmentation Needed"
3. Adjust packet size and retry

### PMTUD Issues

**Problem:** Some networks block ICMP
- PMTUD fails
- Packets silently dropped
- Connection appears broken

**Solution: Disable PMTUD (use fixed MTU)**
```ini
# Set explicit MTU in config
MTU = 1380  # Below any likely path MTU

# No PMTUD needed
```

## Server-Side MTU Configuration

Usually not needed, but if you control server:

### WireGuard Server

```bash
# SSH to server
ssh root@vpn-server

# Check current MTU
ip link show wg0

# Change MTU (if needed)
ip link set dev wg0 mtu 1420

# Make permanent in docker-compose.yml
# Add to wg-easy environment:
WG_MTU=1420
```

### Docker Network MTU

```yaml
# In docker-compose.yml
networks:
  wg_net:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1420
```

## Per-Network MTU Profiles

Create multiple configs for different networks:

```bash
# Home network (high MTU)
./scripts/gen-peer.sh quest-home west full
# Edit: MTU = 1420

# Public Wi-Fi (low MTU)
./scripts/gen-peer.sh quest-public west full
# Edit: MTU = 1360

# Mobile hotspot (medium MTU)
./scripts/gen-peer.sh quest-mobile west full
# Edit: MTU = 1380
```

**Usage:**
- Switch profiles based on network
- Optimal MTU for each environment

## Monitoring MTU Performance

### Check Fragmentation

On VPN server:

```bash
# Check for fragmentation
netstat -s | grep -i frag

# Should be minimal
```

### Check MTU Negotiation

```bash
# View WireGuard interface
ip link show wg0

# Check MTU setting
# Should match config
```

## Best Practices

1. **Auto-detect first**
   - Use `gen-peer.sh` auto-detection
   - Test in your network environment

2. **Test before deploying**
   - Verify MTU works
   - Check for packet loss
   - Test VR streaming

3. **Document your MTU**
   - Note which MTU works where
   - Keep record for troubleshooting

4. **Re-test periodically**
   - Network paths change
   - ISP equipment updates
   - Rerun detection if issues

5. **When in doubt, go lower**
   - Lower MTU always works
   - Slight performance penalty is better than fragmentation

## Quick Reference

### MTU Decision Tree

```
Start with 1420
├─ Works perfectly? → Keep it
├─ Slow speeds? → Lower by 20
├─ Connection drops? → Lower by 40
└─ Some sites fail? → Use 1380 or lower

Test each change thoroughly
```

### Common Commands

```bash
# Auto-detect MTU
./scripts/mtu-autotune.sh west

# Manual ping test
ping -M do -s 1340 <server-ip>

# Regenerate config with new MTU
./scripts/gen-peer.sh quest-user west full
```

## Support

- **Quest setup:** [QUEST_SIDELOAD.md](QUEST_SIDELOAD.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Main guide:** [../QUICKSTART.md](../QUICKSTART.md)

---

**Optimize your VPN for the best Quest VR experience!**
