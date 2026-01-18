# CLITOPHONE

**CLI + Telephone = CLITOPHONE**

A complete remote development setup that lets you run Claude Code from your phone via SSH + Mosh + tmux on a Windows PC with WSL2.

---

## Why CLITOPHONE?

I created CLITOPHONE because I wanted to **code from anywhere using my phone**. Whether I'm on the couch, commuting, or away from my desk, I can pull out my phone and continue working on projects with Claude Code as my AI pair programmer.

The problem with remote development is that mobile connections are unreliable - WiFi switches to cellular, tunnels break connections, and phones go to sleep. CLITOPHONE solves this by combining:

- **Tailscale** for secure, zero-config VPN access to your PC from anywhere
- **Mosh** for connections that survive network changes and high latency
- **tmux** for persistent sessions that keep running even when you disconnect
- **Claude Code** for AI-powered development

The result: You can start a coding session on your PC, continue it from your phone on the train, lose signal in a tunnel, and pick up exactly where you left off when you emerge.

---

## Credits & Inspiration

This project is based on the workflow described in:

**[Claude Code is Better on Your Phone](https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/)** by Harper

The implementation uses the **Ralph Wiggum workflow** - an agentic coding approach where Claude Code orchestrates the development process while you supervise from your mobile device.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              YOUR PHONE                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    BLINK (iOS) / TERMUX (Android)                    │    │
│  │  • Terminal emulator with mosh support                               │    │
│  │  • Stores SSH keys                                                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│                                    │ mosh (UDP) / ssh (TCP)                  │
│                                    ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         TAILSCALE VPN                                │    │
│  │  • Encrypts all traffic                                              │    │
│  │  • Works through NAT/firewalls                                       │    │
│  │  • No port forwarding needed                                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                          Internet (encrypted tunnel)
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            YOUR WINDOWS PC                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  TAILSCALE → OPENSSH SERVER → WSL2 UBUNTU                            │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐    │
│         WSL2 UBUNTU                                                      │    │
│  │                                                                       │    │
│     ┌─────────────┐      ┌─────────────┐      ┌─────────────────────┐   │    │
│  │  │ MOSH-SERVER │ ───▶ │    TMUX     │ ───▶ │    CLAUDE CODE      │  │    │
│     │             │      │  (session)  │      │  (AI pair programmer)│   │    │
│  │  └─────────────┘      └─────────────┘      └─────────────────────┘  │    │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### On Your Windows PC
- Windows 10 (version 1903+) or Windows 11
- WSL2 with Ubuntu installed
- Administrator access for initial setup
- Anthropic API key for Claude Code

### On Your Phone
- **iOS**: Blink Shell ($19.99 one-time) + Tailscale (free)
- **Android**: Termux (free from F-Droid) + Tailscale (free)

---

## Installation

### Part 1: Windows PC Setup

#### Step 1: Install WSL2

Open PowerShell as Administrator:

```powershell
# Install WSL with Ubuntu
wsl --install

# Restart your computer, then verify
wsl --list --verbose
# Should show Ubuntu with VERSION 2
```

#### Step 2: Install Tailscale on Windows

1. Download from [tailscale.com/download/windows](https://tailscale.com/download/windows)
2. Install and sign in with your preferred account (Google, Microsoft, GitHub)
3. Note your machine's Tailscale hostname:
   ```powershell
   tailscale status
   # Shows: surface    100.x.x.x    ...
   # Your hostname is: surface (or surface.tailnet-name.ts.net)
   ```

#### Step 3: Install OpenSSH Server

Open PowerShell as Administrator:

```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the service and set to auto-start
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Verify it's running
Get-Service sshd
```

#### Step 4: Configure SSH to Use WSL2

This makes SSH connections drop you directly into Linux instead of Windows.

Open PowerShell as Administrator:

```powershell
# Set WSL2 as the default shell for SSH
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\wsl.exe" -PropertyType String -Force

# Restart SSH to apply
Restart-Service sshd
```

#### Step 5: Set Up WSL2 Environment

Open WSL2 (type `wsl` in PowerShell):

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y tmux mosh curl wget git

# Install Node.js (required for Claude Code)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version
```

#### Step 6: Configure Your API Key

```bash
# Add to your shell profile
echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

#### Step 7: Add Your Phone's SSH Key

Your phone's public key needs to be added in **two locations** on Windows.

**For admin users** (most common), add to the administrators file.
In Admin PowerShell:

```powershell
# Replace with YOUR phone's public key
Set-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value "ssh-ed25519 AAAA... your-phone-key"

# Set correct permissions
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"

# Restart SSH
Restart-Service sshd
```

**Also add to WSL2** for when you're inside Linux:

```bash
mkdir -p ~/.ssh
echo "ssh-ed25519 AAAA... your-phone-key" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

### Part 2: Phone Setup

Choose your platform:

- **iOS (iPhone/iPad)**: See [SETUP-BLINK.md](docs/SETUP-BLINK.md)
- **Android**: See [SETUP-TERMUX.md](docs/SETUP-TERMUX.md)

#### Quick Setup Summary

**iOS (Blink Shell)**:
1. Install Tailscale from App Store, sign in with same account as PC
2. Install Blink Shell from App Store
3. In Blink: `config` → Keys → Generate ED25519 key
4. Copy public key to your PC (see Step 7 above)
5. In Blink: `config` → Hosts → Add host with your Tailscale hostname

**Android (Termux)**:
1. Install Tailscale from Play Store, sign in with same account as PC
2. Install Termux from F-Droid (NOT Play Store)
3. In Termux: `pkg install openssh mosh tmux`
4. Generate key: `ssh-keygen -t ed25519`
5. Copy public key to your PC (see Step 7 above)
6. Create `~/.ssh/config` with your host settings

---

## Usage

### Connect from Your Phone

```bash
# SSH connection (basic)
ssh surface

# Mosh connection (recommended - survives network changes)
mosh surface
```

### Start Claude Code in tmux

```bash
# Create a new tmux session
tmux new -s code

# Run Claude Code
claude
```

### Reconnect Later

```bash
# Connect and reattach to your session
mosh surface
tmux attach -t code

# Your Claude Code session is exactly where you left it!
```

---

## tmux Command Reference

tmux keeps your sessions alive even when you disconnect.

### Session Management

| Command | Description |
|---------|-------------|
| `tmux new -s name` | Create new session named "name" |
| `tmux ls` | List all sessions |
| `tmux attach -t name` | Attach to session "name" |
| `tmux kill-session -t name` | Kill session "name" |
| `tmux kill-server` | Kill ALL sessions |

### Inside tmux (Keyboard Shortcuts)

The prefix key is `Ctrl+A` (if using CLITOPHONE config) or `Ctrl+B` (default).

| Shortcut | Action |
|----------|--------|
| `Prefix, d` | Detach from session (keeps running) |
| `Prefix, c` | Create new window |
| `Prefix, n` | Next window |
| `Prefix, p` | Previous window |
| `Prefix, 0-9` | Switch to window number |
| `Prefix, ,` | Rename current window |
| `Prefix, [` | Enter scroll/copy mode |
| `q` | Exit scroll mode |
| `Prefix, ?` | Show all shortcuts |

### Split Panes

| Shortcut | Action |
|----------|--------|
| `Prefix, %` | Split vertically |
| `Prefix, "` | Split horizontally |
| `Prefix, arrow` | Navigate between panes |
| `Prefix, x` | Kill current pane |
| `Prefix, z` | Toggle pane zoom (fullscreen) |

### Quick Reference

```bash
# Start coding session
tmux new -s code
claude

# Detach (from phone, keep session running)
# Press: Ctrl+A, then d

# Later, reconnect
mosh surface
tmux attach -t code

# List all sessions
tmux ls

# Kill a session when done
tmux kill-session -t code
```

---

## Example Daily Workflow

```bash
# Morning: Start a session on your PC
tmux new -s work
claude

# Head out, detach the session
# Ctrl+A, d

# On the train: Connect from phone
mosh surface
tmux attach -t work
# Continue where you left off!

# Train goes into tunnel - connection drops
# (Session keeps running on your PC)

# Signal returns - mosh reconnects automatically
# Still in your session, no work lost

# Evening: Check on a long-running task
mosh surface
tmux attach -t work
# See the results
```

---

## Troubleshooting

### "Connection refused"
1. Check Tailscale is running on both devices
2. Verify SSH service: `Get-Service sshd` (should show "Running")
3. Test connectivity: `ping surface` from phone

### "Permission denied (publickey)"
1. Your SSH key isn't recognized
2. For admin Windows users, key must be in `C:\ProgramData\ssh\administrators_authorized_keys`
3. Check permissions on that file (see Step 7)

### SSH works but mosh doesn't
1. Mosh uses UDP ports 60000-61000
2. In Admin PowerShell:
   ```powershell
   New-NetFirewallRule -Name "Mosh" -DisplayName "Mosh Server" -Protocol UDP -LocalPort 60000-61000 -Action Allow
   ```

### Session lost after disconnect
1. Make sure you're using tmux
2. Detach properly with `Ctrl+A, d` instead of closing the app
3. Reconnect with `tmux attach -t sessionname`

### Password prompt instead of key auth
1. Windows admin users need keys in `C:\ProgramData\ssh\administrators_authorized_keys`
2. Make sure file permissions are set correctly (see Step 7)

For more solutions, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## Project Structure

```
CLITOPHONE/
├── README.md                 # This file
├── docs/
│   ├── QUICKSTART.md         # 5-minute setup guide
│   ├── SETUP-BLINK.md        # iOS (Blink Shell) setup
│   ├── SETUP-TERMUX.md       # Android (Termux) setup
│   ├── SERVER-SETUP.md       # Detailed server setup
│   └── TROUBLESHOOTING.md    # Common issues and fixes
├── config/
│   ├── .tmux.conf            # tmux configuration
│   └── ssh_config_example    # SSH client config template
└── scripts/
    ├── setup-env.sh          # Automated setup script
    ├── cc-start              # Start new Claude session
    ├── cc-continue           # Resume Claude session
    └── tm                    # tmux session manager
```

---

## Security

- **SSH key authentication only** - No passwords transmitted
- **Tailscale encryption** - All traffic encrypted end-to-end
- **No port forwarding** - Your PC isn't exposed to the internet
- **API keys stay on your PC** - Never transmitted to your phone

---

## License

MIT License - See LICENSE file for details.

---

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Mosh Documentation](https://mosh.org/)
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Blink Shell Documentation](https://docs.blink.sh/)
- [Termux Wiki](https://wiki.termux.com/)
