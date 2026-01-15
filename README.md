# CLITOPHONE

**CLI + Telephone = CLITOPHONE**

A complete remote development setup that lets you run Claude Code from your phone via SSH + Mosh + TMUX on a Windows PC with WSL2.

Based on: [Claude Code is Better on Your Phone](https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/)

## What is CLITOPHONE?

CLITOPHONE provides a robust, persistent connection to Claude Code running on your Windows PC from anywhere using your phone. It combines:

- **Tailscale**: Secure, zero-config VPN networking
- **SSH + Mosh**: Reliable connections that survive network changes
- **TMUX**: Persistent terminal sessions
- **Claude Code**: AI-powered coding assistant

## Features

- **Persistent Sessions**: Your Claude Code sessions survive disconnections
- **Mobile-Optimized**: Configured for small screens and touch keyboards
- **Multi-Session**: Run multiple Claude Code instances simultaneously
- **Secure**: SSH key authentication with Tailscale's encrypted network
- **Cross-Platform**: Works with iOS (Blink.sh) and Android (Termux)

## Quick Start

### Prerequisites

1. Windows PC with WSL2 installed
2. Tailscale installed on Windows and your phone
3. Mobile SSH client (Blink.sh for iOS, Termux for Android)

### One-Time Setup (on Windows PC)

```bash
# In WSL2, run the setup script
./scripts/setup-env.sh

# Copy the tmux config
cp config/.tmux.conf ~/.tmux.conf

# Add aliases to your shell profile
echo 'source /path/to/CLITOPHONE/scripts/aliases.sh' >> ~/.bashrc
```

### Connect from Phone

```bash
# Connect via mosh (recommended)
mosh your-pc.tailnet-name.ts.net

# Or via SSH
ssh your-pc.tailnet-name.ts.net

# Start/resume Claude Code session
cc
```

## Directory Structure

```
CLITOPHONE/
├── README.md           # This file
├── PROMPT.md           # Project task definition
├── ralph.yml           # Orchestrator configuration
├── scripts/
│   ├── cc-start        # Start new Claude Code session
│   ├── cc-continue     # Resume or create session
│   ├── tm              # TMUX session manager
│   └── setup-env.sh    # One-time environment setup
├── config/
│   ├── .tmux.conf      # TMUX configuration for mobile use
│   └── ssh_config_example  # Example SSH client config
└── docs/
    ├── QUICKSTART.md   # TL;DR connection guide
    ├── SETUP-BLINK.md  # iOS (Blink.sh) setup guide
    ├── SETUP-TERMUX.md # Android (Termux) setup guide
    ├── SERVER-SETUP.md    # Server setup guide (Windows/WSL2/SSH/Mosh)
    └── TROUBLESHOOTING.md  # Common issues and fixes
```

## Scripts

### `cc-start`
Creates a new named Claude Code session in TMUX.

```bash
cc-start project-name [directory]
```

### `cc-continue` (alias: `cc`)
Attaches to an existing Claude Code session, or creates one if none exists.

```bash
cc                    # Resume/create default session
cc project-name       # Resume/create named session
```

### `tm`
TMUX session manager with machine-specific naming.

```bash
tm                    # List sessions
tm new [name]         # Create new session
tm attach [name]      # Attach to session
tm kill [name]        # Kill session
```

## Documentation

### Getting Started
- **[QUICKSTART.md](docs/QUICKSTART.md)** - Get connected in 5 minutes

### Server Setup
- **[SERVER-SETUP.md](docs/SERVER-SETUP.md)** - Complete Windows/WSL2/SSH/Mosh server setup

### Phone Client Setup
- **[SETUP-BLINK.md](docs/SETUP-BLINK.md)** - Complete iOS setup with Blink.sh
- **[SETUP-TERMUX.md](docs/SETUP-TERMUX.md)** - Complete Android setup with Termux

### Reference
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Fix common issues

## Requirements

### Windows Host
- Windows 10/11 with WSL2
- OpenSSH Server enabled
- Tailscale client installed

### WSL2 Environment
- Ubuntu or Debian distribution
- Packages: `mosh`, `tmux`, `nodejs` (18+)
- Claude Code installed via npm

### Mobile Client
- **iOS**: Blink.sh (recommended) or any SSH client with mosh
- **Android**: Termux with mosh package

## Security

- SSH key authentication only (password auth disabled)
- All traffic encrypted via Tailscale
- No port forwarding or public exposure needed
- API keys stored securely in WSL2 environment

## License

MIT License - See LICENSE file for details.
