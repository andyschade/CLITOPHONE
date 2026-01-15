# Blink Shell Setup Guide for iOS

Complete guide to configuring Blink Shell on your iPhone/iPad for CLITOPHONE.

## About Blink Shell

[Blink Shell](https://blink.sh) is a professional-grade terminal emulator for iOS that supports:
- Native mosh client (crucial for mobile connectivity)
- SSH key management
- Custom fonts and themes
- Hardware keyboard support
- Split view multitasking

**Cost:** $19.99 one-time purchase (worth it for mobile development)

## Installation

1. Download from the [App Store](https://apps.apple.com/app/blink-shell/id1594898306)
2. Open Blink and complete the initial setup

---

## Step 1: Generate SSH Key

### Option A: Generate in Blink (Recommended)

1. Open Blink
2. Type `config` or swipe down and tap **Settings**
3. Go to **Keys**
4. Tap **+** (Add Key)
5. Select **Generate New Key**
6. Configuration:
   - **Name:** `clitophone` (or any memorable name)
   - **Type:** `ED25519` (recommended) or `RSA 4096`
   - **Passphrase:** Optional but recommended
7. Tap **Save**

### Option B: Import Existing Key

If you have an existing key:
1. Go to **Settings > Keys > +**
2. Select **Import from clipboard** or **Import from file**
3. Paste or select your private key

### Copy Your Public Key

1. Go to **Settings > Keys**
2. Tap your key name
3. Tap **Copy Public Key**
4. Send this to yourself (email, AirDrop, secure notes) to add to your PC

---

## Step 2: Add Public Key to Your PC

On your Windows PC (in WSL2):

```bash
# Create .ssh directory if needed
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create or edit authorized_keys
nano ~/.ssh/authorized_keys

# Paste your public key (one line), save and exit

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys
```

---

## Step 3: Configure Host

1. Open Blink
2. Type `config` or access **Settings**
3. Go to **Hosts**
4. Tap **+** (Add Host)
5. Configure:

| Field | Value |
|-------|-------|
| **Alias** | `clitophone` |
| **HostName** | `your-pc.tailnet-name.ts.net` |
| **Port** | `22` |
| **User** | Your WSL2 username |
| **Key** | Select your key from Step 1 |
| **Mosh** | Enable (toggle on) |

6. Tap **Save**

### Finding Your Tailscale Hostname

On your Windows PC:
```powershell
tailscale status
```
Look for your machine name, format: `machine-name.tailnet-name.ts.net`

---

## Step 4: Configure Mosh (Important!)

Mosh provides persistent connections that survive network switches and sleep.

1. Go to **Settings > Hosts > clitophone**
2. Scroll to **Mosh** section
3. Enable **Mosh** toggle
4. Configure:

| Setting | Value |
|---------|-------|
| **Mosh Command** | Leave empty (uses default) |
| **Mosh Server** | `/usr/bin/mosh-server` |
| **Prediction** | `Adaptive` (recommended) |
| **UDP Port** | Leave empty (auto) |

---

## Step 5: Install Tailscale on iOS

1. Download [Tailscale](https://apps.apple.com/app/tailscale/id1470499037) from App Store
2. Open Tailscale
3. Sign in with the **same account** as your Windows PC
4. Tap **Connect**
5. Allow VPN configuration when prompted

### Verify Connection

In Blink, run:
```bash
ping your-pc.tailnet-name.ts.net
```

---

## Step 6: Test Connection

### Basic SSH Test

In Blink, type:
```bash
ssh clitophone
```

You should see your WSL2 prompt.

### Mosh Connection

```bash
mosh clitophone
```

You should see `[mosh]` indicator in Blink when connected via mosh.

### Start Claude Code

```bash
# After connecting:
cc
```

---

## Recommended Blink Settings

### Appearance (Settings > Appearance)

| Setting | Recommended Value |
|---------|-------------------|
| **Font** | `Fira Code` or `JetBrains Mono` |
| **Font Size** | 14-16 (adjust for your screen) |
| **Theme** | `Default` or `Dracula` |
| **Cursor** | `Block` |
| **Cursor Blink** | Off (less distracting) |

### Keyboard (Settings > Keyboard)

| Setting | Recommended Value |
|---------|-------------------|
| **Caps as Ctrl** | Enable (easier tmux prefix) |
| **Option as Meta** | Enable |

### Shell (Settings > Shell)

| Setting | Recommended Value |
|---------|-------------------|
| **Default Shell** | `bash` |

---

## Quick Commands Reference

Once connected, you can use these commands:

| Command | Action |
|---------|--------|
| `cc` | Resume or start Claude Code |
| `cc projectname` | Named Claude Code session |
| `cc -l` | List all sessions |
| `ccs name` | Start fresh named session |
| `tm` | TMUX session manager |

---

## TMUX Shortcuts (Blink-Optimized)

With Caps Lock mapped to Ctrl:

| Shortcut | Action |
|----------|--------|
| `Caps+A d` | Detach from session |
| `Caps+A c` | New window |
| `Caps+A n` | Next window |
| `Caps+A p` | Previous window |
| `Caps+A [` | Enter scroll mode |
| `q` | Exit scroll mode |
| `Caps+A ?` | Show help |
| `Caps+A :` | Command mode |

---

## Gestures in Blink

| Gesture | Action |
|---------|--------|
| **Swipe Left/Right** | Switch between shells |
| **Pinch** | Zoom in/out |
| **Two-finger swipe down** | Settings |
| **Three-finger tap** | Paste |

---

## Troubleshooting

### "Connection refused"

1. Check Tailscale is running on both devices
2. Verify SSH server is running on Windows:
   ```powershell
   Get-Service sshd
   Start-Service sshd  # If stopped
   ```
3. Check your PC's Tailscale IP: `tailscale ip` on PC

### "Permission denied (publickey)"

1. Verify your public key is in `~/.ssh/authorized_keys` on the PC
2. Check file permissions:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```
3. Ensure the key in Blink matches what's on the server

### Mosh Fails to Connect

1. SSH works but mosh doesn't? Check UDP ports:
   ```powershell
   # On Windows (Admin PowerShell)
   New-NetFirewallRule -Name "Mosh" -DisplayName "Mosh Server" -Protocol UDP -LocalPort 60000-61000 -Action Allow
   ```

2. Verify mosh-server is installed in WSL2:
   ```bash
   which mosh-server
   # If not found:
   sudo apt install mosh
   ```

### Connection Drops Frequently

1. Enable Blink's background modes:
   - Settings > Advanced > Allow Background
2. Disable iOS Low Power Mode
3. Use mosh instead of SSH (mosh handles reconnection automatically)

### Can't Type Special Characters

1. Check keyboard settings in Blink
2. Enable "Option as Meta" for Alt key functionality
3. For Escape: Two-finger tap or configure a gesture

### Slow or Laggy Connection

1. Mosh prediction settings:
   - Try setting Prediction to `Always` for faster feel
2. Check network quality (Tailscale handles routing efficiently)

---

## Advanced: Custom Configuration

### SSH Config File

Blink also supports an SSH config file. Access via:
```bash
config  # Opens settings
```

Or create custom SSH options in the host configuration.

### Using ProxyJump

If you need to jump through servers:

1. Edit host settings
2. Add ProxyJump configuration
3. Example: `ProxyJump=bastion.example.com`

### Multiple Hosts

Create separate host entries for:
- Different projects
- Different machines
- Different network paths (Tailscale vs direct IP)

---

## Tips for Mobile Development

1. **Use Landscape Mode** - More screen width for code
2. **External Keyboard** - Bluetooth keyboards work great with Blink
3. **iPad Split View** - Run Blink alongside documentation
4. **Siri Shortcuts** - Create shortcuts to quickly connect:
   - "Hey Siri, start coding" → Opens Blink and connects

---

## Example Daily Workflow

```bash
# Morning: Start fresh
mosh clitophone -- cc morning-task

# Work with Claude Code on your commute...
# Train goes into tunnel? Mosh handles it.

# Afternoon: Continue previous session
mosh clitophone -- cc
# Right where you left off!

# Evening: Check on long-running task
mosh clitophone -- cc -l
# See all your sessions
```

---

## Resources

- [Blink Shell Documentation](https://docs.blink.sh)
- [Blink GitHub](https://github.com/blinksh/blink)
- [Tailscale iOS Docs](https://tailscale.com/kb/1020/install-ios)

---

## Next Steps

- Return to [QUICKSTART.md](QUICKSTART.md) for connection basics
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions
