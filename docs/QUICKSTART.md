# CLITOPHONE Quick Start Guide

Get Claude Code running on your phone in 5 minutes.

## Prerequisites

Before starting, ensure you have:
- [ ] Windows PC with WSL2 installed
- [ ] Tailscale account (free at [tailscale.com](https://tailscale.com))
- [ ] Phone with SSH client (Blink for iOS, Termux for Android)
- [ ] Your ANTHROPIC_API_KEY ready

---

## TL;DR - Super Quick Setup

```bash
# 1. On your Windows PC (in WSL2):
./scripts/setup-env.sh

# 2. On your phone:
mosh clitophone -- cc
```

That's it! Read below for detailed steps.

---

## Step 1: Set Up Your Windows PC (5 min)

### Run the Setup Script

Open WSL2 and run:

```bash
cd /path/to/CLITOPHONE
./scripts/setup-env.sh
```

This script will:
- Install required packages (tmux, mosh, nodejs)
- Configure your shell with aliases
- Set up tmux configuration
- Guide you through API key setup

### Start Tailscale

```powershell
# In Windows PowerShell (Admin)
tailscale up
```

### Get Your Tailscale Hostname

```powershell
tailscale status
```

Note your machine name (e.g., `my-pc.tailnet-name.ts.net`)

---

## Step 2: Set Up Your Phone (3 min)

### Install Apps

| Platform | App | Link |
|----------|-----|------|
| iOS | Blink Shell | [App Store](https://apps.apple.com/app/blink-shell/id1594898306) |
| Android | Termux | [F-Droid](https://f-droid.org/packages/com.termux/) |

### Install Tailscale on Phone

| Platform | Link |
|----------|------|
| iOS | [App Store](https://apps.apple.com/app/tailscale/id1470499037) |
| Android | [Play Store](https://play.google.com/store/apps/details?id=com.tailscale.ipn) |

Sign in with the same account as your PC.

### Generate SSH Key (if needed)

**Blink (iOS):**
- Settings > Keys > + > Generate new key (ED25519)
- Copy the public key

**Termux (Android):**
```bash
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub
```

### Add Key to PC

On your Windows PC (WSL2):

```bash
# Create authorized_keys if it doesn't exist
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Add your phone's public key
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
```

### Configure SSH on Phone

Copy `config/ssh_config_example` to your phone and customize:

**Blink (iOS):**
- Settings > Hosts > +
- Alias: `clitophone`
- HostName: `your-pc.tailnet.ts.net`
- User: `your-username`
- Key: Select your key

**Termux (Android):**
```bash
mkdir -p ~/.ssh
# Edit ~/.ssh/config with the template from config/ssh_config_example
```

---

## Step 3: Connect! (30 sec)

### First Connection (SSH)

```bash
ssh clitophone
```

### Persistent Connection (Mosh)

```bash
mosh clitophone
```

### Start Claude Code

```bash
# After connecting:
cc                    # Resume or start Claude Code
cc myproject          # Named session
cc -l                 # List all sessions

# Or directly:
mosh clitophone -- cc
```

---

## Quick Reference

### Commands After Connecting

| Command | Description |
|---------|-------------|
| `cc` | Resume or start Claude Code (alias for cc-continue) |
| `ccs name` | Start new named session (alias for cc-start) |
| `tm` | TMUX session manager |
| `cc -l` | List all Claude Code sessions |

### TMUX Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+A d` | Detach (disconnect but keep running) |
| `Ctrl+A c` | New window |
| `Ctrl+A n` | Next window |
| `Ctrl+A p` | Previous window |
| `Ctrl+A [` | Scroll mode (q to exit) |
| `Ctrl+A ?` | Help |

### Reconnecting After Disconnect

```bash
# Your session persists! Just reconnect:
mosh clitophone -- tmux attach

# Or use the helper:
mosh clitophone -- cc
```

---

## Troubleshooting

### Can't Connect?

1. **Check Tailscale** - Is it running on both devices?
   ```bash
   tailscale status
   ```

2. **Check SSH** - Is the server running?
   ```powershell
   # Windows PowerShell
   Get-Service sshd
   ```

3. **Test basic connectivity**
   ```bash
   ssh -v clitophone
   ```

### Mosh Not Working?

1. **Check UDP ports** - Mosh needs ports 60000-61000
   ```powershell
   # Open UDP ports in Windows Firewall
   New-NetFirewallRule -Name "Mosh" -DisplayName "Mosh Server" -Protocol UDP -LocalPort 60000-61000 -Action Allow
   ```

2. **Run mosh-server in WSL2** - Ensure mosh is installed
   ```bash
   sudo apt install mosh
   ```

### Session Lost?

```bash
# Sessions persist in tmux. Just reattach:
tmux list-sessions
tmux attach -t session-name
# Or simply:
cc
```

---

## Next Steps

- **iOS users:** See [SETUP-BLINK.md](SETUP-BLINK.md) for detailed Blink configuration
- **Android users:** See [SETUP-TERMUX.md](SETUP-TERMUX.md) for detailed Termux configuration
- **Problems?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions

---

## Example Workflow

```bash
# Morning: Start a new session from your phone
mosh clitophone -- cc myproject

# Work with Claude Code...
# Phone dies? Network drops? No problem!

# Later: Reconnect and continue where you left off
mosh clitophone -- cc
# Your session is exactly as you left it
```

Happy coding!
