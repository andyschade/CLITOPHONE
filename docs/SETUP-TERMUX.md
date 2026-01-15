# Termux (Android) Setup Guide

Complete guide for setting up Termux on Android to connect to your CLITOPHONE system.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installing Termux](#installing-termux)
- [Setting Up Tailscale](#setting-up-tailscale)
- [SSH Configuration](#ssh-configuration)
- [Mosh Setup](#mosh-setup)
- [Recommended Settings](#recommended-settings)
- [Useful Add-ons](#useful-add-ons)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:
- [ ] Android 7.0 or higher
- [ ] CLITOPHONE server set up and running
- [ ] Tailscale account (same as your PC)
- [ ] Your PC's Tailscale hostname (e.g., `your-pc.tail12345.ts.net`)

---

## Installing Termux

### Important: Get Termux from F-Droid

> **Warning**: Do NOT install Termux from Google Play Store - that version is outdated and unmaintained.

### Option 1: F-Droid (Recommended)

1. **Install F-Droid**:
   - Download from: https://f-droid.org/
   - Allow installation from unknown sources when prompted

2. **Install Termux from F-Droid**:
   - Open F-Droid
   - Search for "Termux"
   - Install **Termux** (by Fredrik Fornwall)
   - Also install **Termux:API** (optional but useful)

### Option 2: Direct APK Download

1. Go to: https://github.com/termux/termux-app/releases
2. Download the latest APK for your architecture (usually `arm64-v8a`)
3. Install the APK

### Initial Setup

After installing, open Termux and run:

```bash
# Update packages first (REQUIRED)
pkg update && pkg upgrade -y

# Install essential packages
pkg install -y openssh mosh tmux git

# Grant storage access (for file transfers)
termux-setup-storage
```

---

## Setting Up Tailscale

### Install Tailscale on Android

1. **From Google Play Store**:
   - Search "Tailscale"
   - Install the official Tailscale app

2. **Sign In**:
   - Open Tailscale app
   - Sign in with the same account as your PC
   - Enable VPN when prompted

3. **Verify Connection**:
   - Both your phone and PC should appear in the Tailscale admin console
   - Note your PC's Tailscale hostname or IP

### Test Connectivity

In Termux, test the connection:

```bash
# Replace with your PC's Tailscale hostname
ping -c 3 your-pc.tail12345.ts.net
```

---

## SSH Configuration

### Generate SSH Keys

```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "android-termux"

# Or RSA if Ed25519 isn't supported
ssh-keygen -t rsa -b 4096 -C "android-termux"
```

When prompted:
- Save to default location (`~/.ssh/id_ed25519`)
- Optionally set a passphrase

### Copy Public Key to Server

**Option 1: Display and manually copy**
```bash
cat ~/.ssh/id_ed25519.pub
```
Then add this key to your PC's `~/.ssh/authorized_keys` (in WSL2).

**Option 2: Use ssh-copy-id (if password auth is still enabled)**
```bash
ssh-copy-id username@your-pc.tail12345.ts.net
```

### Configure SSH Client

Create or edit `~/.ssh/config`:

```bash
# Create the config file
mkdir -p ~/.ssh
nano ~/.ssh/config
```

Add the following configuration:

```ssh-config
# ===========================================
# CLITOPHONE - Main Configuration (Tailscale)
# ===========================================
Host clitophone
    HostName your-pc.tail12345.ts.net
    User your-username
    Port 22
    IdentityFile ~/.ssh/id_ed25519

    # Keep connection alive
    ServerAliveInterval 30
    ServerAliveCountMax 3

    # Performance optimizations
    Compression yes

    # Multiplexing for faster reconnects
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600

# ===========================================
# Shorthand aliases
# ===========================================
Host cc
    HostName your-pc.tail12345.ts.net
    User your-username
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    Compression yes

# ===========================================
# Direct IP (backup)
# ===========================================
Host clitophone-ip
    HostName 100.x.x.x
    User your-username
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
```

Create the sockets directory:
```bash
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh ~/.ssh/sockets
```

### Test SSH Connection

```bash
# Connect using the alias
ssh clitophone

# Or use the short alias
ssh cc
```

---

## Mosh Setup

Mosh provides a better mobile experience with:
- Survives network switches (WiFi to cellular)
- Handles high latency gracefully
- Instant local echo

### Install Mosh

```bash
pkg install mosh
```

### Connect with Mosh

```bash
# Basic connection
mosh clitophone

# With explicit SSH command
mosh --ssh="ssh -p 22" clitophone

# Specify port range (if needed)
mosh -p 60001 clitophone
```

### Create a Connection Script

Create a quick-connect script:

```bash
# Create scripts directory
mkdir -p ~/bin

# Create connection script
cat > ~/bin/cc << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Quick connect to CLITOPHONE

HOST="${1:-clitophone}"

echo "Connecting to CLITOPHONE..."
echo "Using mosh for persistent connection"
echo ""

# Try mosh first, fall back to SSH
if command -v mosh &> /dev/null; then
    mosh "$HOST" -- tmux new-session -A -s main
else
    ssh -t "$HOST" "tmux new-session -A -s main"
fi
EOF

chmod +x ~/bin/cc
```

Add to PATH in `~/.bashrc`:
```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Now you can simply type:
```bash
cc          # Connect to default host
cc cc       # Connect using 'cc' ssh alias
```

---

## Recommended Settings

### Termux Properties

Edit Termux properties for better experience:

```bash
# Create/edit properties file
nano ~/.termux/termux.properties
```

Add these settings:

```properties
# Use black background
use-black-ui = true

# Extra keys row (customize as needed)
extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]

# Bell behavior
bell-character = vibrate

# Keyboard settings
enforce-char-based-input = true

# Terminal margins (prevents edge gestures)
terminal-margin-horizontal = 3
terminal-margin-vertical = 0
```

Reload settings:
```bash
termux-reload-settings
```

### Keyboard Shortcuts

Termux special keys:
- **Volume Down + Q**: Exit (like Ctrl+\\)
- **Volume Down + C**: Ctrl+C
- **Volume Down + E**: Escape
- **Volume Down + W**: Arrow Up
- **Volume Down + S**: Arrow Down
- **Volume Down + A**: Arrow Left
- **Volume Down + D**: Arrow Right

### Styling (Optional)

Install Termux styling:

```bash
# From F-Droid, install Termux:Styling
# Then long-press terminal > Style
```

Or manually set colors:

```bash
mkdir -p ~/.termux
cat > ~/.termux/colors.properties << 'EOF'
# Solarized Dark
background=#002b36
foreground=#839496
cursor=#93a1a1

color0=#073642
color1=#dc322f
color2=#859900
color3=#b58900
color4=#268bd2
color5=#d33682
color6=#2aa198
color7=#eee8d5
color8=#002b36
color9=#cb4b16
color10=#586e75
color11=#657b83
color12=#839496
color13=#6c71c4
color14=#93a1a1
color15=#fdf6e3
EOF

termux-reload-settings
```

---

## Useful Add-ons

### Termux:Widget

Create home screen shortcuts for quick connections:

1. Install **Termux:Widget** from F-Droid
2. Create shortcuts directory:
   ```bash
   mkdir -p ~/.shortcuts
   ```
3. Create shortcut script:
   ```bash
   cat > ~/.shortcuts/CLITOPHONE << 'EOF'
   #!/data/data/com.termux/files/usr/bin/bash
   mosh clitophone -- tmux new-session -A -s main
   EOF
   chmod +x ~/.shortcuts/CLITOPHONE
   ```
4. Add Termux:Widget to your home screen
5. Tap the shortcut to connect instantly

### Termux:Boot

Auto-start Tailscale verification on boot:

1. Install **Termux:Boot** from F-Droid
2. Create boot script:
   ```bash
   mkdir -p ~/.termux/boot
   cat > ~/.termux/boot/check-tailscale << 'EOF'
   #!/data/data/com.termux/files/usr/bin/bash
   # Notification reminder to enable Tailscale
   termux-notification \
       --title "CLITOPHONE" \
       --content "Remember to enable Tailscale VPN"
   EOF
   chmod +x ~/.termux/boot/check-tailscale
   ```

### Termux:API

Access Android features from the terminal:

```bash
# Install from F-Droid: Termux:API
pkg install termux-api

# Examples:
termux-notification --title "Connected" --content "CLITOPHONE session active"
termux-clipboard-get  # Get clipboard content
termux-clipboard-set "text"  # Set clipboard
termux-battery-status  # Check battery
```

---

## TMUX Quick Reference

When connected, use these TMUX commands:

| Action | Keys |
|--------|------|
| Prefix | `Ctrl+A` (custom) or `Ctrl+B` (default) |
| New window | `Prefix + c` |
| Next window | `Prefix + n` |
| Previous window | `Prefix + p` |
| Split horizontal | `Prefix + -` |
| Split vertical | `Prefix + \|` |
| Navigate panes | `Prefix + arrow` |
| Detach session | `Prefix + d` |
| Scroll mode | `Prefix + [` |
| Exit scroll | `q` |

### CLITOPHONE Commands

```bash
cc          # Resume/start Claude Code session
ccs         # Start new Claude Code session
tm          # TMUX session manager
tm list     # List all sessions
tm kill     # Kill specific session
```

---

## Troubleshooting

### "Connection refused" Error

1. **Check Tailscale is connected**:
   - Open Tailscale app
   - Ensure VPN is enabled (key icon in status bar)

2. **Verify PC is online**:
   ```bash
   ping your-pc.tail12345.ts.net
   ```

3. **Check SSH service on PC**:
   - On Windows, ensure OpenSSH Server is running

### "Permission denied (publickey)"

1. **Verify key was added**:
   ```bash
   # Check your public key
   cat ~/.ssh/id_ed25519.pub
   ```

2. **Ensure key is in authorized_keys on server**:
   - SSH must have the key in `~/.ssh/authorized_keys` (in WSL2)

3. **Check permissions**:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

### Mosh Connection Issues

1. **"mosh-server not found"**:
   - Ensure mosh is installed on the server (in WSL2):
     ```bash
     # On server
     sudo apt install mosh
     ```

2. **Connection timeout**:
   - Mosh uses UDP ports 60000-61000
   - Check Windows Firewall allows these ports
   - Tailscale should handle this automatically

3. **Fall back to SSH**:
   ```bash
   ssh -t clitophone "tmux new-session -A -s main"
   ```

### Termux Keyboard Issues

1. **Extra keys not showing**:
   - Swipe up from the terminal keyboard
   - Or long-press the terminal and select "Keyboard"

2. **Ctrl key not working**:
   - Use Volume Down + letter for Ctrl combinations
   - Or enable extra keys row in termux.properties

3. **Arrow keys**:
   - Volume Down + WASD
   - Or swipe on the terminal

### Session Lost on Network Change

1. **Use mosh instead of SSH**:
   ```bash
   mosh clitophone
   ```

2. **TMUX session should persist**:
   ```bash
   # Reattach after reconnection
   ssh clitophone -t "tmux attach"
   ```

### High Battery Usage

1. **Disable extra features**:
   ```bash
   # In termux.properties
   wake-lock = false
   ```

2. **Use SSH ControlMaster** (already configured above)

3. **Disconnect when not in use**:
   - Detach TMUX: `Ctrl+A d`
   - Sessions persist on server

### "Storage permission denied"

```bash
# Re-run storage setup
termux-setup-storage
```
Then allow storage access when prompted.

---

## Tips for Mobile Development

### External Keyboard

Termux works great with Bluetooth keyboards:
- Full Ctrl/Alt/Esc key support
- No Volume Down combinations needed
- TMUX shortcuts work normally

### Quick Workflows

```bash
# Morning startup
cc                    # Resume yesterday's Claude session

# Check multiple projects
tm list              # See all TMUX sessions
tm attach project1   # Switch to project1 session

# Quick command
ssh cc "cd ~/project && git status"
```

### Split Pane Layout

Once connected, create a productive layout:

```bash
# Horizontal split: Claude on top, shell below
tmux split-window -v -p 30

# Or vertical: Claude left, shell right
tmux split-window -h -p 40
```

### Copy/Paste with Termux

```bash
# Copy from terminal: long-press and select
# Paste: long-press and tap Paste

# Or use Termux:API
termux-clipboard-get > file.txt  # Paste clipboard to file
cat file.txt | termux-clipboard-set  # Copy file to clipboard
```

---

## Quick Setup Checklist

- [ ] Install Termux from F-Droid
- [ ] Run `pkg update && pkg upgrade`
- [ ] Install packages: `pkg install openssh mosh tmux`
- [ ] Install Tailscale from Play Store
- [ ] Sign in to Tailscale (same account as PC)
- [ ] Generate SSH key: `ssh-keygen -t ed25519`
- [ ] Add public key to server's authorized_keys
- [ ] Create `~/.ssh/config` with host configuration
- [ ] Test SSH: `ssh clitophone`
- [ ] Test Mosh: `mosh clitophone`
- [ ] Create quick-connect script in `~/bin/cc`
- [ ] (Optional) Install Termux:Widget for home screen shortcut

---

## Resources

- [Termux Wiki](https://wiki.termux.com/)
- [Termux GitHub](https://github.com/termux/termux-app)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Mosh Documentation](https://mosh.org/)
- [TMUX Cheat Sheet](https://tmuxcheatsheet.com/)
