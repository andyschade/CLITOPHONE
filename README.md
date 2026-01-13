# CLITOPHONE - Remote Claude Code

Run Claude Code from your phone by SSH-ing into your workstation. Recreate the classic terminal-based development workflow with modern AI tools.

## Architecture

```
[Phone/Tablet] --> [Tailscale VPN] --> [Workstation]
    Blink               |                  |
      |                 |              [TMUX]
      +---- Mosh -------+                  |
                                     [Claude Code]
```

## Components

| Component | Purpose |
|-----------|---------|
| **Tailscale** | Private VPN network accessible from anywhere |
| **Blink** | iOS SSH client (or any terminal app) |
| **Mosh** | Persistent connections across network changes |
| **TMUX** | Session management, multiple Claude instances |
| **Scripts** | Workflow automation helpers |

## Quick Start

```bash
# 1. Install dependencies
./scripts/install.sh

# 2. Configure your environment
cp .env.example .env
# Edit .env with your settings

# 3. Source the helpers in your shell
echo 'source ~/clitophone/scripts/shell-helpers.sh' >> ~/.bashrc

# 4. From your phone, SSH in and start coding
tm work        # Start/attach to 'work' session
cc-start       # Launch Claude Code
```

## Scripts

### `tm` - TMUX Session Manager

Smart session management with machine-specific identifiers.

```bash
tm              # List sessions or create default
tm work         # Attach to 'work' session (creates if needed)
tm new project  # Create new 'project' session
tm kill work    # Kill 'work' session
```

### `cc-start` / `cc-continue`

Claude Code workflow helpers.

```bash
cc-start                    # Start new Claude session
cc-start "fix the bug"      # Start with initial prompt
cc-continue                 # Resume last session
```

### `unlock.sh`

Credential and keychain management for headless operation.

```bash
./scripts/unlock.sh         # Interactive unlock
./scripts/unlock.sh --check # Verify unlock status
```

## Installation

### Prerequisites

- macOS or Linux workstation with SSH enabled
- [Tailscale](https://tailscale.com/) account
- [Claude Code CLI](https://claude.ai/code) installed
- TMUX and Mosh installed

### Step-by-Step Setup

1. **Install Tailscale on your workstation**
   ```bash
   # macOS
   brew install tailscale

   # Linux (Debian/Ubuntu)
   curl -fsSL https://tailscale.com/install.sh | sh
   ```

2. **Enable SSH**
   ```bash
   # macOS: System Preferences > Sharing > Remote Login

   # Linux
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

3. **Install TMUX and Mosh**
   ```bash
   # macOS
   brew install tmux mosh

   # Linux
   sudo apt install tmux mosh
   ```

4. **Clone and install CLITOPHONE**
   ```bash
   git clone https://github.com/youruser/clitophone.git ~/clitophone
   cd ~/clitophone
   ./scripts/install.sh
   ```

5. **Install Tailscale on your phone**
   - iOS: App Store > Tailscale
   - Android: Play Store > Tailscale
   - Sign in with the same account

6. **Install Blink (iOS) or JuiceSSH (Android)**
   - Configure SSH key authentication
   - Add your workstation as a host

### SSH Key Setup

```bash
# On your phone/tablet, generate a key
ssh-keygen -t ed25519 -C "phone"

# Copy public key to workstation
# Add to ~/.ssh/authorized_keys on workstation
```

## Configuration

### Environment Variables (.env)

```bash
# Machine identifier (emoji for TMUX)
CLITOPHONE_MACHINE_ID="🖥️"

# Default TMUX session name
CLITOPHONE_DEFAULT_SESSION="dev"

# Claude Code options
CLAUDE_MODEL="claude-sonnet-4-20250514"

# Keychain service name (macOS)
KEYCHAIN_SERVICE="anthropic-api"
```

### TMUX Configuration

The included `config/tmux.conf` provides:
- Mouse support for phone interaction
- Status bar with session info
- Easy pane navigation
- Clipboard integration

```bash
# Use our config
cp config/tmux.conf ~/.tmux.conf
tmux source ~/.tmux.conf
```

## Workflow

### Daily Usage

1. **Open Blink/Terminal on phone**
2. **SSH to workstation**: `ssh myworkstation` (via Tailscale)
3. **Unlock credentials** (if needed): `unlock`
4. **Start/attach session**: `tm work`
5. **Launch Claude**: `cc-start` or `cc-continue`

### Multiple Projects

```bash
# Terminal 1: Main project
tm project-a
cc-start "working on feature X"

# Terminal 2 (new pane): Side project
tm project-b
cc-start "fix the tests"
```

### Handling Disconnections

Mosh automatically reconnects when you switch networks. TMUX preserves your session state. Just reconnect and `tm <session>` to resume.

## Troubleshooting

### Can't connect via Tailscale

```bash
# Check Tailscale status
tailscale status

# Ensure both devices are on the network
tailscale ping <device-name>
```

### TMUX session lost

```bash
# List all sessions
tmux list-sessions

# Force attach
tmux attach -t <session-name>
```

### Claude Code API issues

```bash
# Verify API key is available
./scripts/unlock.sh --check

# Test Claude directly
claude --version
```

## Security Notes

- Use SSH key authentication, never passwords
- Store SSH key passphrase in your phone's secure enclave
- API keys should be in system keychain, not plain text
- Tailscale provides end-to-end encryption

## Credits

- Inspired by [Harper Reed's blog post](https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/)
- Built using the [Ralph Wiggum technique](https://github.com/mikeyobrien/ralph-orchestrator)

## License

MIT
