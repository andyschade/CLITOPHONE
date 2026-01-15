# CLITOPHONE Troubleshooting Guide

Complete troubleshooting guide for common issues with the CLITOPHONE system.

## Table of Contents

- [Connection Issues](#connection-issues)
- [SSH Problems](#ssh-problems)
- [Mosh Problems](#mosh-problems)
- [Tailscale Issues](#tailscale-issues)
- [TMUX Issues](#tmux-issues)
- [Claude Code Issues](#claude-code-issues)
- [WSL2 Issues](#wsl2-issues)
- [Performance Issues](#performance-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Diagnostic Commands](#diagnostic-commands)

---

## Connection Issues

### Cannot Connect at All

**Symptoms**: No response, connection timeout, "No route to host"

**Diagnosis Steps**:

```bash
# 1. Check if Tailscale is running on your phone
# Open Tailscale app - VPN should be enabled

# 2. Test basic connectivity
ping your-pc.tailnet.ts.net

# 3. Check if host is reachable
nc -zv your-pc.tailnet.ts.net 22
```

**Solutions**:

1. **Tailscale not connected on phone**:
   - Open Tailscale app
   - Toggle VPN on
   - Wait for connection (green checkmark)

2. **Tailscale not running on PC**:
   ```powershell
   # Windows PowerShell (Admin)
   tailscale up
   tailscale status
   ```

3. **PC is asleep/hibernating**:
   - Ensure Windows power settings don't sleep the PC
   - Consider disabling sleep when on power

4. **Firewall blocking connections**:
   ```powershell
   # Check if SSH port is open
   Get-NetFirewallRule -DisplayName "*ssh*"

   # Add SSH rule if missing
   New-NetFirewallRule -Name "OpenSSH-Server" -DisplayName "OpenSSH Server" -Protocol TCP -LocalPort 22 -Action Allow
   ```

### Connection Drops Frequently

**Symptoms**: SSH disconnects, "Connection reset", "Broken pipe"

**Solutions**:

1. **Use Mosh instead of SSH**:
   ```bash
   mosh clitophone
   ```

2. **Enable SSH keep-alive** (in `~/.ssh/config` on phone):
   ```
   Host clitophone
       ServerAliveInterval 30
       ServerAliveCountMax 3
   ```

3. **Check network stability**:
   - Ensure strong WiFi/cellular signal
   - Tailscale routes may change on poor networks

4. **Enable TCP keep-alive on Windows SSH**:
   ```powershell
   # Edit C:\ProgramData\ssh\sshd_config
   TCPKeepAlive yes
   ClientAliveInterval 60
   ClientAliveCountMax 3
   # Restart SSH service
   Restart-Service sshd
   ```

---

## SSH Problems

### "Connection refused"

**Cause**: SSH server not running or not accessible

**Solutions**:

1. **Check SSH service on Windows**:
   ```powershell
   # PowerShell (Admin)
   Get-Service sshd

   # Start if stopped
   Start-Service sshd

   # Set to auto-start
   Set-Service sshd -StartupType Automatic
   ```

2. **Install OpenSSH Server if missing**:
   ```powershell
   # PowerShell (Admin)
   Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
   Start-Service sshd
   Set-Service -Name sshd -StartupType 'Automatic'
   ```

3. **Check Windows Firewall**:
   ```powershell
   Get-NetFirewallRule -Name *ssh* | Format-Table
   ```

### "Permission denied (publickey)"

**Cause**: SSH key authentication failed

**Diagnosis**:
```bash
# Verbose SSH output
ssh -vvv clitophone
```

**Solutions**:

1. **Verify key is in authorized_keys**:
   ```bash
   # On PC (WSL2)
   cat ~/.ssh/authorized_keys
   # Should contain your phone's public key
   ```

2. **Check file permissions (WSL2)**:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ls -la ~/.ssh/
   ```

3. **Verify key format**:
   - Key should be on a single line
   - No extra whitespace or line breaks
   - Format: `ssh-ed25519 AAAA... comment`

4. **Check the correct user**:
   ```bash
   # Your SSH config should specify the right user
   Host clitophone
       User your-wsl-username
   ```

5. **Windows OpenSSH authorized_keys location**:
   - For admin users: `C:\ProgramData\ssh\administrators_authorized_keys`
   - For regular users: `C:\Users\<username>\.ssh\authorized_keys`

   When using WSL2 as default shell, keys go in WSL2's `~/.ssh/authorized_keys`

### "Host key verification failed"

**Cause**: Server's host key changed (or first connection)

**Solutions**:

1. **First time connecting** - Accept the key:
   ```bash
   ssh clitophone
   # Type "yes" when prompted
   ```

2. **Key changed** (e.g., after reinstall):
   ```bash
   # Remove old key
   ssh-keygen -R your-pc.tailnet.ts.net

   # Reconnect
   ssh clitophone
   ```

### SSH Connects to Wrong Shell

**Symptoms**: SSH connects to Windows CMD instead of WSL2

**Solution**:

1. **Set WSL2 as default shell**:
   ```powershell
   # PowerShell (Admin)
   # Edit C:\ProgramData\ssh\sshd_config
   # Add this line:
   # ForceCommand C:\Windows\System32\wsl.exe

   # Or set default shell:
   New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\wsl.exe" -PropertyType String -Force

   Restart-Service sshd
   ```

---

## Mosh Problems

### "mosh-server: not found"

**Cause**: Mosh not installed in WSL2

**Solution**:
```bash
# In WSL2
sudo apt update
sudo apt install mosh

# Verify installation
which mosh-server
# Should output: /usr/bin/mosh-server
```

### Mosh Connection Timeout

**Cause**: UDP ports blocked

**Solutions**:

1. **Open UDP ports in Windows Firewall**:
   ```powershell
   # PowerShell (Admin)
   New-NetFirewallRule -Name "Mosh-UDP" -DisplayName "Mosh Server UDP" -Protocol UDP -LocalPort 60000-61000 -Action Allow
   ```

2. **Check existing rules**:
   ```powershell
   Get-NetFirewallRule -DisplayName "*mosh*" | Format-Table
   ```

3. **Verify mosh ports are listening**:
   ```bash
   # In WSL2, after a mosh connection attempt
   ss -ulnp | grep mosh
   ```

### Mosh Works but Displays Garbage

**Cause**: Character encoding mismatch

**Solutions**:

1. **Set locale in WSL2**:
   ```bash
   # Add to ~/.bashrc
   export LANG=en_US.UTF-8
   export LC_ALL=en_US.UTF-8

   # Regenerate locales
   sudo locale-gen en_US.UTF-8
   ```

2. **On phone client**:
   - Blink: Settings > Appearance > Font should support UTF-8
   - Termux: Use UTF-8 compatible terminal settings

### Mosh High Latency Prediction Issues

**Cause**: Mosh prediction acting strangely

**Solution**:
```bash
# Try different prediction modes
mosh --predict=never clitophone
mosh --predict=always clitophone
mosh --predict=adaptive clitophone  # Default
```

---

## Tailscale Issues

### Devices Not Seeing Each Other

**Solutions**:

1. **Verify both devices on same Tailnet**:
   - Check tailscale.com/admin console
   - Both devices should be listed

2. **Check Tailscale status**:
   ```bash
   # On phone (Termux) or PC
   tailscale status
   ```

3. **Restart Tailscale**:
   ```powershell
   # Windows
   tailscale down
   tailscale up
   ```

   On phone: Toggle VPN off and on in Tailscale app

4. **Check for ACL blocks**:
   - Visit tailscale.com/admin/acls
   - Ensure default allow rules are in place

### Tailscale IP Changed

**Symptoms**: Can't connect to old hostname/IP

**Solutions**:

1. **Get new hostname**:
   ```bash
   tailscale status
   ```

2. **Update SSH config** with new hostname

3. **Use MagicDNS** (more stable):
   - Enable in Tailscale admin console
   - Use hostname like `your-pc` instead of full domain

### Slow Tailscale Connection

**Cause**: DERP relay being used instead of direct connection

**Diagnosis**:
```bash
tailscale status
# Look for "relay" in output - indicates not direct
tailscale ping your-pc
# Shows if using relay
```

**Solutions**:

1. **Enable direct connections** (may require NAT config)
2. **Check for firewall blocking UDP**
3. **Wait** - Tailscale may establish direct connection after some time

---

## TMUX Issues

### TMUX Session Not Persisting

**Symptoms**: Session disappears after disconnect

**Cause**: SSH session closing TMUX

**Solutions**:

1. **Detach properly** before disconnecting:
   ```
   Ctrl+A d
   ```

2. **Check session still exists**:
   ```bash
   tmux list-sessions
   ```

3. **Attach to existing session**:
   ```bash
   tmux attach -t session-name
   # Or use the helper:
   cc
   ```

### "no sessions" When Attaching

**Cause**: No TMUX sessions exist

**Solutions**:

1. **Create a new session**:
   ```bash
   tmux new -s main
   # Or use helper:
   cc-start main
   ```

2. **Check TMUX server is running**:
   ```bash
   pgrep tmux
   ```

### TMUX Colors Not Working

**Solutions**:

1. **Set terminal type**:
   ```bash
   # Add to ~/.bashrc
   export TERM=xterm-256color
   ```

2. **Check tmux.conf**:
   ```bash
   # In ~/.tmux.conf
   set -g default-terminal "screen-256color"
   ```

3. **Reload tmux config**:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

### TMUX Prefix Key Not Working

**Symptoms**: Ctrl+A (or Ctrl+B) doesn't work

**Solutions**:

1. **Check your tmux.conf prefix setting**:
   ```bash
   grep prefix ~/.tmux.conf
   ```

2. **Mobile keyboard issues**:
   - **Blink (iOS)**: Enable "Caps as Ctrl" in Settings > Keyboard
   - **Termux (Android)**: Use Volume Down + A for Ctrl+A

3. **Test with default prefix**:
   ```bash
   # Try Ctrl+B (default tmux prefix)
   ```

### Can't Scroll in TMUX

**Solution**:

1. **Enter scroll mode**:
   ```
   Ctrl+A [
   ```

2. **Navigate** with arrow keys or Page Up/Down

3. **Exit** scroll mode with `q`

4. **Enable mouse scrolling** (if in tmux.conf):
   ```bash
   # Check if mouse mode is enabled
   grep mouse ~/.tmux.conf
   ```

---

## Claude Code Issues

### Claude Code Not Found

**Symptoms**: "claude: command not found"

**Solutions**:

1. **Install Claude Code**:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **Check Node.js is installed**:
   ```bash
   node --version
   npm --version
   ```

3. **Install Node.js if missing**:
   ```bash
   # Using nvm (recommended)
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   source ~/.bashrc
   nvm install --lts
   ```

### ANTHROPIC_API_KEY Not Set

**Symptoms**: Claude Code prompts for API key every time

**Solutions**:

1. **Set in shell profile**:
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export ANTHROPIC_API_KEY="your-key-here"
   ```

2. **Verify it's set**:
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

3. **Use setup script**:
   ```bash
   ./scripts/setup-env.sh
   ```

### Claude Code Session Lost

**Solutions**:

1. **Sessions persist in TMUX**:
   ```bash
   tmux list-sessions
   cc   # Reconnect to Claude session
   ```

2. **Check for crashed session**:
   ```bash
   cc -l   # List Claude sessions
   ```

### Claude Code Display Issues

**Symptoms**: Garbled output, broken formatting

**Solutions**:

1. **Check terminal size**:
   ```bash
   stty size
   # Should return reasonable dimensions
   ```

2. **Resize tmux pane**:
   ```
   Ctrl+A : resize-pane -x 120
   ```

3. **Check encoding**:
   ```bash
   echo $LANG
   # Should be UTF-8
   ```

---

## WSL2 Issues

### WSL2 Not Starting

**Symptoms**: "The Windows Subsystem for Linux has not been enabled"

**Solutions**:

1. **Enable WSL**:
   ```powershell
   # PowerShell (Admin)
   wsl --install
   # Or manually:
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. **Restart Windows**

3. **Set WSL2 as default**:
   ```powershell
   wsl --set-default-version 2
   ```

### WSL2 Network Issues

**Symptoms**: Can't access network from WSL2

**Solutions**:

1. **Check WSL2 network**:
   ```bash
   # In WSL2
   ip addr
   ping google.com
   ```

2. **Restart WSL2**:
   ```powershell
   wsl --shutdown
   wsl
   ```

3. **Reset network adapter**:
   ```powershell
   # PowerShell (Admin)
   Restart-NetAdapter -Name "vEthernet (WSL)"
   ```

### WSL2 Clock Drift

**Symptoms**: SSL errors, time-related issues

**Solution**:
```bash
# In WSL2
sudo hwclock -s
# Or
sudo ntpdate pool.ntp.org
```

---

## Performance Issues

### Slow Connection Response

**Solutions**:

1. **Use Mosh** for better perceived latency
2. **Enable SSH compression**:
   ```
   Host clitophone
       Compression yes
   ```
3. **Check Tailscale connection type**:
   ```bash
   tailscale ping your-pc
   # Direct is faster than relay
   ```

### High Latency

**Diagnosis**:
```bash
ping your-pc.tailnet.ts.net
mtr your-pc.tailnet.ts.net  # If available
```

**Solutions**:

1. **Switch to faster network (WiFi vs cellular)**
2. **Check for VPN conflicts** (disable other VPNs)
3. **Optimize Tailscale**:
   - Enable direct connections
   - Check for relay usage

### WSL2 Slow Performance

**Solutions**:

1. **Move files to Linux filesystem**:
   ```bash
   # Use /home/user/ instead of /mnt/c/
   ```

2. **Increase WSL2 memory** (in `%USERPROFILE%\.wslconfig`):
   ```ini
   [wsl2]
   memory=8GB
   processors=4
   ```

3. **Restart WSL2**:
   ```powershell
   wsl --shutdown
   ```

---

## Platform-Specific Issues

### iOS (Blink) Issues

**Can't paste from clipboard**:
- Three-finger tap to paste
- Or long-press and select Paste

**Keyboard disappears**:
- Swipe up from bottom edge
- Use external keyboard for extended sessions

**Connection drops in background**:
- Settings > Advanced > Allow Background
- Use Mosh for automatic reconnection

### Android (Termux) Issues

**Storage permission denied**:
```bash
termux-setup-storage
# Grant permission when prompted
```

**Extra keys row missing**:
- Swipe up on the keyboard
- Or check `~/.termux/termux.properties`

**Volume key shortcuts not working**:
- Some keyboards intercept Volume+key
- Try different keyboard app

---

## Diagnostic Commands

### Quick Health Check

Run these to diagnose most issues:

```bash
# 1. Check Tailscale
tailscale status

# 2. Test connectivity
ping -c 3 your-pc.tailnet.ts.net

# 3. Test SSH
ssh -v clitophone "echo 'SSH works!'"

# 4. Test Mosh
mosh clitophone -- echo "Mosh works!"

# 5. Check TMUX
tmux list-sessions

# 6. Check Claude Code
which claude
echo $ANTHROPIC_API_KEY | head -c 10
```

### Full Diagnostic Script

Create a diagnostic script:

```bash
#!/bin/bash
echo "=== CLITOPHONE Diagnostics ==="
echo ""

echo "1. Tailscale Status:"
tailscale status 2>&1 || echo "Tailscale not running"
echo ""

echo "2. Network Test:"
ping -c 2 your-pc.tailnet.ts.net 2>&1 || echo "Cannot reach host"
echo ""

echo "3. SSH Test:"
ssh -o ConnectTimeout=5 clitophone "echo 'SSH: OK'" 2>&1 || echo "SSH failed"
echo ""

echo "4. Mosh Test:"
timeout 5 mosh clitophone -- echo "Mosh: OK" 2>&1 || echo "Mosh failed"
echo ""

echo "5. TMUX Sessions:"
ssh clitophone "tmux list-sessions" 2>&1 || echo "No sessions"
echo ""

echo "6. Environment:"
ssh clitophone 'echo "Node: $(node --version 2>/dev/null || echo missing)"'
ssh clitophone 'echo "API Key: $([ -n "$ANTHROPIC_API_KEY" ] && echo "set" || echo "not set")"'
echo ""

echo "=== Diagnostics Complete ==="
```

### Verbose Connection Debugging

```bash
# Maximum SSH verbosity
ssh -vvv clitophone

# Mosh debug
MOSH_SERVER_NETWORK_TMOUT=60 mosh clitophone

# Check ports
nc -zv your-pc.tailnet.ts.net 22   # SSH
nc -zvu your-pc.tailnet.ts.net 60001  # Mosh UDP
```

---

## Getting Help

If you're still having issues:

1. **Check the logs**:
   - Windows: Event Viewer > Applications and Services > OpenSSH
   - WSL2: `journalctl -xe` (if systemd enabled)

2. **Search existing issues**:
   - [Tailscale GitHub Issues](https://github.com/tailscale/tailscale/issues)
   - [Mosh GitHub Issues](https://github.com/mobile-shell/mosh/issues)
   - [WSL2 GitHub Issues](https://github.com/microsoft/WSL/issues)

3. **Community resources**:
   - [Tailscale Discord](https://discord.com/invite/tailscale)
   - [r/tailscale](https://reddit.com/r/tailscale)
   - [r/bashonubuntuonwindows](https://reddit.com/r/bashonubuntuonwindows)

---

## Quick Reference: Error Messages

| Error | Likely Cause | Quick Fix |
|-------|-------------|-----------|
| "Connection refused" | SSH not running | Start sshd service |
| "Permission denied (publickey)" | Key not authorized | Add key to authorized_keys |
| "mosh-server: not found" | Mosh not installed | `sudo apt install mosh` |
| "Connection timed out" | Firewall/network | Check Tailscale, firewall |
| "No route to host" | Network unreachable | Enable Tailscale VPN |
| "Host key verification failed" | Server key changed | `ssh-keygen -R hostname` |
| "ANTHROPIC_API_KEY not set" | Missing env var | Add to ~/.bashrc |
| "command not found: claude" | Claude not installed | `npm install -g @anthropic-ai/claude-code` |

---

*Last updated: January 2026*
