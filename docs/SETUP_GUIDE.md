# CLITOPHONE Setup Guide

Complete guide for setting up Remote Claude Code on your workstation and mobile device.

## Prerequisites

Before starting, ensure you have:
- A Mac or Linux workstation that stays powered on
- An iOS or Android device
- An Anthropic API key (get one at https://console.anthropic.com)

## Part 1: Workstation Setup

### 1.1 Install Core Dependencies

**macOS:**
```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required packages
brew install tmux mosh

# Install Claude Code
npm install -g @anthropic-ai/claude-code
# or
brew install claude-code
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install tmux mosh openssh-server

# Install Claude Code
npm install -g @anthropic-ai/claude-code
```

### 1.2 Enable SSH

**macOS:**
1. Open System Preferences → Sharing
2. Enable "Remote Login"
3. Note your computer name (e.g., `mymac.local`)

**Linux:**
```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

### 1.3 Install Tailscale

Tailscale creates a private network so you can access your workstation from anywhere.

```bash
# macOS
brew install tailscale

# Linux
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
sudo tailscale up
```

Follow the authentication prompts. Note your machine's Tailscale hostname (e.g., `mymac`).

### 1.4 Install CLITOPHONE

```bash
# Clone the repository
git clone https://github.com/youruser/clitophone.git ~/clitophone

# Run the installer
cd ~/clitophone
./scripts/install.sh
```

### 1.5 Store Your API Key Securely

**macOS (Keychain):**
```bash
security add-generic-password -s "anthropic-api" -a "$USER" -w "sk-ant-your-key-here"
```

**Linux (GPG):**
```bash
mkdir -p ~/.config/anthropic
echo "sk-ant-your-key-here" | gpg -e -r your@email.com > ~/.config/anthropic/api_key.gpg
```

## Part 2: Mobile Setup

### 2.1 Install Tailscale

1. Download Tailscale from App Store (iOS) or Play Store (Android)
2. Sign in with the same account used on your workstation
3. Your devices should now see each other

### 2.2 Install Terminal App

**iOS (Recommended: Blink Shell)**
1. Download Blink from the App Store
2. Open Blink and generate an SSH key:
   ```
   config > keys > + > Generate
   ```
3. Copy the public key

**Android (Recommended: JuiceSSH)**
1. Download JuiceSSH from Play Store
2. Go to Connections → Identities → Add
3. Generate a new key pair
4. Copy the public key

### 2.3 Add Your Phone's Key to Workstation

On your workstation, add the phone's public key:

```bash
# Open authorized_keys
nano ~/.ssh/authorized_keys

# Paste your phone's public key on a new line
# Save and exit
```

### 2.4 Configure SSH Host

**In Blink:**
1. Go to `config > hosts > +`
2. Host: `workstation` (or any name)
3. Hostname: Your Tailscale hostname (e.g., `mymac`)
4. User: Your username
5. Key: Select the key you generated
6. Mosh: Enable for persistent connections

**In JuiceSSH:**
1. Connections → Add
2. Nickname: `workstation`
3. Address: Your Tailscale hostname
4. Identity: Select your identity
5. Save

## Part 3: First Connection

### 3.1 Test the Connection

From your phone's terminal app:

```bash
ssh workstation
```

You should now be connected to your workstation!

### 3.2 Start Your First Session

```bash
# Unlock credentials (first time)
unlock

# Start a TMUX session
tm work

# Launch Claude Code
cc-start
```

### 3.3 Using Mosh (Recommended)

Mosh maintains your connection even when switching networks:

```bash
mosh workstation
```

In Blink, if you enabled Mosh for your host, just use:
```bash
workstation
```

## Part 4: Daily Workflow

### Quick Start

1. Open terminal app on phone
2. `mosh workstation` (or tap your saved host)
3. `tm work` (attach to existing session or create new)
4. `cc-start` or `cc-continue`

### Managing Multiple Projects

```bash
# Create sessions for different projects
tm project-alpha
cc-start "working on the API"

# Switch to another project (Ctrl-a then d to detach first)
tm project-beta
cc-start "updating the frontend"
```

### Checking Session Status

```bash
# List all TMUX sessions
tm ls

# Check credential status
unlock --check
```

## Troubleshooting

### Cannot connect via Tailscale

```bash
# On workstation, check Tailscale status
tailscale status

# Try pinging from phone (in Tailscale app)
# Or from workstation:
tailscale ping phone-device-name
```

### Connection drops frequently

Use Mosh instead of raw SSH:
```bash
mosh workstation
```

### TMUX session not found

```bash
# List all sessions
tmux list-sessions

# Create a new one
tm new work
```

### API key not working

```bash
# Check if key is accessible
./scripts/unlock.sh --check

# Re-store the key (macOS)
security delete-generic-password -s "anthropic-api" 2>/dev/null
security add-generic-password -s "anthropic-api" -a "$USER" -w "sk-ant-new-key"
```

## Security Best Practices

1. **Use SSH keys, never passwords** - Disable password auth in sshd_config
2. **Store passphrase in secure enclave** - Blink and most iOS apps support this
3. **Keep API keys in keychain** - Never store in plain text files
4. **Enable Tailscale's MagicDNS** - Avoid exposing real IP addresses
5. **Use key-based Tailscale auth** - Enable "Require authentication" in Tailscale admin

## Next Steps

- Customize your TMUX config in `~/.tmux.conf`
- Set up project-specific prompts in `~/clitophone/.env`
- Explore Claude Code's `--continue` flag for session persistence
