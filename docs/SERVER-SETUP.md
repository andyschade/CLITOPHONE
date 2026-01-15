# CLITOPHONE Server Setup Guide

Complete guide to setting up your Windows PC as a CLITOPHONE server.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Windows SSH Server Setup](#windows-ssh-server-setup)
3. [WSL2 Configuration](#wsl2-configuration)
4. [Tailscale Networking](#tailscale-networking)
5. [Mosh Server Setup](#mosh-server-setup)
6. [Final Configuration](#final-configuration)
7. [Testing Your Setup](#testing-your-setup)

---

## Prerequisites

### System Requirements

- **Windows 10** (version 1903+) or **Windows 11**
- **WSL2** capability (hardware virtualization enabled in BIOS)
- **8GB+ RAM** (WSL2 + Claude Code can use 2-4GB)
- **Administrator access** for initial setup

### What You'll Need

- Anthropic API key for Claude Code
- About 30-60 minutes for complete setup
- Your phone ready for testing

---

## Windows SSH Server Setup

### 1. Enable OpenSSH Server

Open **PowerShell as Administrator** and run:

```powershell
# Check if OpenSSH is installed
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# Install OpenSSH Server (if not installed)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start the SSH service
Start-Service sshd

# Set SSH to start automatically
Set-Service -Name sshd -StartupType 'Automatic'

# Verify it's running
Get-Service sshd
```

### 2. Configure SSH to Use WSL2 as Default Shell

This is the key step that makes SSH drop you directly into WSL2.

**Option A: Per-User Configuration (Recommended)**

Edit or create `%USERPROFILE%\.ssh\config` on Windows:

```
# C:\Users\YourUsername\.ssh\config
# This is the Windows SSH client config
```

For the server to use WSL2, edit the global SSH config:

1. Open `C:\ProgramData\ssh\sshd_config` as Administrator
2. Add at the end:

```
# Use WSL2 as default shell
Match User YourWindowsUsername
    ForceCommand C:\Windows\System32\wsl.exe -d Ubuntu --cd ~
```

**Option B: System-Wide Default (All Users)**

Set WSL as the default shell for all SSH sessions:

```powershell
# Run as Administrator
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\wsl.exe" -PropertyType String -Force

# Optional: Set default arguments
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShellCommandOption -Value "-d Ubuntu --cd ~" -PropertyType String -Force
```

### 3. Restart SSH Service

```powershell
Restart-Service sshd
```

### 4. Set Up SSH Key Authentication

**On your Windows PC (in WSL2):**

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create authorized_keys file
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Important:** The authorized_keys file needs to exist in **both** locations:
- WSL2: `~/.ssh/authorized_keys` (for WSL2 direct SSH)
- Windows: `C:\Users\YourUsername\.ssh\authorized_keys` (for Windows SSH)

For seamless operation, symlink or copy your keys:

```bash
# In WSL2, create a symlink to Windows authorized_keys
# Replace 'YourUsername' with your Windows username
ln -sf /mnt/c/Users/YourUsername/.ssh/authorized_keys ~/.ssh/authorized_keys
```

### 5. Add Your Phone's Public Key

Generate a key on your phone (see [SETUP-BLINK.md](SETUP-BLINK.md) or [SETUP-TERMUX.md](SETUP-TERMUX.md)), then add it:

```bash
# On your Windows PC, add the public key
echo "ssh-ed25519 AAAA... your-phone-key" >> ~/.ssh/authorized_keys
```

Or copy from your phone and paste into the file.

### 6. Disable Password Authentication (Security)

Edit `C:\ProgramData\ssh\sshd_config` as Administrator:

```
# Find and modify these lines
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart the SSH service:

```powershell
Restart-Service sshd
```

### 7. Configure Windows Firewall

SSH should work through Tailscale without additional firewall rules, but if needed:

```powershell
# Allow SSH through Windows Firewall
New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

---

## WSL2 Configuration

### 1. Install WSL2 (if not installed)

Open PowerShell as Administrator:

```powershell
# Install WSL with Ubuntu (default)
wsl --install

# Or install a specific distribution
wsl --install -d Ubuntu-22.04

# Restart your computer after installation
```

### 2. Verify WSL2 is Active

```powershell
# Check WSL version
wsl --list --verbose

# Should show VERSION 2
```

If showing VERSION 1, upgrade:

```powershell
wsl --set-version Ubuntu 2
```

### 3. Update WSL2 and Install Required Packages

Open WSL2 terminal:

```bash
# Update package lists
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    tmux \
    mosh \
    htop \
    jq

# Install Node.js (required for Claude Code)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Verify Node.js installation
node --version  # Should be 18.x or higher
npm --version
```

### 4. Install Claude Code

```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version
```

### 5. Configure Environment Variables

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Claude Code API Key
# SECURITY: Keep this secret! Never commit to git.
export ANTHROPIC_API_KEY="your-api-key-here"

# Optional: Set default model
export CLAUDE_MODEL="claude-sonnet-4-20250514"

# Optional: Custom temp directory for better performance
export CLAUDE_TEMP_DIR="/tmp/claude"
mkdir -p $CLAUDE_TEMP_DIR 2>/dev/null

# Source CLITOPHONE scripts
export CLITOPHONE_HOME="$HOME/CLITOPHONE"
export PATH="$CLITOPHONE_HOME/scripts:$PATH"
```

Reload your shell:

```bash
source ~/.bashrc
```

### 6. Copy CLITOPHONE Configuration

```bash
# Clone or copy CLITOPHONE to your home directory
# If you have it elsewhere, adjust the path
cp ~/CLITOPHONE/config/.tmux.conf ~/.tmux.conf

# Verify tmux config works
tmux new-session -d -s test && tmux kill-session -t test
echo "TMUX config OK"
```

---

## Tailscale Networking

### 1. Install Tailscale on Windows

1. Download from [tailscale.com/download/windows](https://tailscale.com/download/windows)
2. Run the installer
3. Click "Connect" when prompted
4. Sign in with your preferred account (Google, Microsoft, GitHub, etc.)

### 2. Verify Tailscale Connection

```powershell
# Check Tailscale status
tailscale status

# Get your Tailscale IP and hostname
tailscale ip
```

Your machine will have a hostname like: `your-pc-name.tailnet-name.ts.net`

### 3. Find Your Tailscale Hostname

```powershell
# In PowerShell
tailscale status | Select-String $(hostname)

# Or check the Tailscale tray icon > Network Devices
```

Note down your hostname - you'll need it for phone configuration.

### 4. Install Tailscale on Your Phone

**iOS:**
1. Install from App Store: [Tailscale](https://apps.apple.com/app/tailscale/id1470499037)
2. Open and sign in with the same account
3. Grant VPN permission when prompted

**Android:**
1. Install from Play Store: [Tailscale](https://play.google.com/store/apps/details?id=com.tailscale.ipn)
2. Open and sign in with the same account
3. Grant VPN permission when prompted

### 5. Verify Phone Can See PC

On your phone, open Tailscale and verify your PC appears in the device list.

Test connectivity:
```bash
# From phone terminal (Blink or Termux)
ping your-pc-name.tailnet-name.ts.net
```

### 6. Tailscale MagicDNS (Optional but Recommended)

Enable MagicDNS in Tailscale admin console for shorter hostnames:
- Go to [login.tailscale.com/admin/dns](https://login.tailscale.com/admin/dns)
- Enable MagicDNS

Now you can use just `your-pc-name` instead of the full `.ts.net` address.

---

## Mosh Server Setup

Mosh provides persistent connections that survive network changes - essential for mobile use.

### 1. Install Mosh in WSL2

```bash
# Mosh should already be installed from earlier steps
# Verify it's available
which mosh-server
mosh-server --version
```

### 2. Understand Mosh Port Requirements

Mosh uses UDP ports 60000-61000. These need to be accessible.

**Good News:** Tailscale handles this automatically! Since both devices are on your Tailscale network, UDP traffic flows directly without port forwarding.

### 3. Test Mosh Server

```bash
# Test that mosh-server can start
mosh-server

# You should see something like:
# MOSH CONNECT 60001 <encryption-key>
# Press Ctrl+C to stop
```

### 4. Configure Windows Firewall for Mosh (if needed)

Usually not needed with Tailscale, but if you have issues:

```powershell
# Run as Administrator
New-NetFirewallRule -Name "Mosh-UDP" -DisplayName "Mosh Server (UDP)" -Enabled True -Direction Inbound -Protocol UDP -Action Allow -LocalPort 60000-61000
```

### 5. WSL2 Network Configuration

WSL2 may need special handling for UDP. The `setup-env.sh` script handles this, but manually:

```bash
# Ensure mosh-server is findable
which mosh-server

# If mosh isn't in default path, create a symlink
sudo ln -sf $(which mosh-server) /usr/bin/mosh-server
```

### 6. Test Mosh Connection

From your phone:

```bash
# Basic mosh connection
mosh your-pc-name.tailnet-name.ts.net

# With explicit SSH command
mosh --ssh="ssh -p 22" your-pc-name.tailnet-name.ts.net
```

---

## Final Configuration

### 1. Run CLITOPHONE Setup Script

The setup script automates most configuration:

```bash
cd ~/CLITOPHONE
./scripts/setup-env.sh
```

This script:
- Installs required packages
- Configures shell environment
- Sets up TMUX configuration
- Configures aliases

### 2. Set Up Shell Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# CLITOPHONE aliases
alias cc='cc-continue'
alias ccs='cc-start'
alias tm='tm'

# Quick connect test
alias test-ssh='ssh localhost echo "SSH OK"'
```

### 3. Create Session Auto-Start (Optional)

To automatically start a default TMUX session on login:

```bash
# Add to ~/.bashrc (at the end)
if [ -z "$TMUX" ]; then
    tmux attach-session -t default 2>/dev/null || tmux new-session -s default
fi
```

### 4. Configure SSH Keep-Alive

Add to `/etc/ssh/sshd_config` in WSL2:

```bash
# Server-side keep-alive
ClientAliveInterval 30
ClientAliveCountMax 3
```

---

## Testing Your Setup

### Quick Test Checklist

Run these tests to verify everything works:

```bash
# 1. Test SSH service (from Windows PowerShell)
Test-NetConnection -ComputerName localhost -Port 22

# 2. Test local SSH (from WSL2)
ssh localhost echo "Local SSH OK"

# 3. Test Tailscale (from WSL2)
tailscale status

# 4. Test mosh-server
mosh-server --version

# 5. Test TMUX
tmux new-session -d -s test && tmux kill-session -t test && echo "TMUX OK"

# 6. Test Claude Code
claude --version

# 7. Test CLITOPHONE scripts
tm list
```

### Full Connection Test

From your phone:

```bash
# 1. Test SSH connection
ssh your-pc-name.tailnet-name.ts.net

# 2. Test mosh connection
mosh your-pc-name.tailnet-name.ts.net

# 3. Start Claude Code session
cc

# 4. Verify persistence by disconnecting and reconnecting
# Your session should still be there!
```

### Diagnostic Script

Run the full diagnostic:

```bash
cd ~/CLITOPHONE
./scripts/setup-env.sh --check
```

---

## Next Steps

1. **Configure your phone** - Follow [SETUP-BLINK.md](SETUP-BLINK.md) (iOS) or [SETUP-TERMUX.md](SETUP-TERMUX.md) (Android)
2. **Review quick reference** - See [QUICKSTART.md](QUICKSTART.md)
3. **Troubleshoot issues** - Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Common Issues During Setup

### SSH Connection Refused

```powershell
# Ensure SSH service is running
Get-Service sshd
Start-Service sshd
```

### WSL2 Not Starting

```powershell
# Restart WSL
wsl --shutdown
wsl
```

### Mosh Connection Timeout

Usually a Tailscale or firewall issue:
1. Ensure both devices show "Connected" in Tailscale
2. Try SSH first to verify basic connectivity
3. Check Windows Firewall for UDP 60000-61000

### Permission Denied (publickey)

```bash
# Check key permissions
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Verify key is in authorized_keys
cat ~/.ssh/authorized_keys
```

---

## Security Best Practices

1. **Use SSH keys only** - Disable password authentication
2. **Keep Tailscale updated** - Security patches are important
3. **Protect your API key** - Never commit to git or share
4. **Review SSH access** - Regularly audit authorized_keys
5. **Use strong keys** - ED25519 recommended over RSA
6. **Enable 2FA on Tailscale** - Additional security layer

---

**Setup Complete!** You're ready to code from anywhere.
