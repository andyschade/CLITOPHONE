# Task: Build Remote Claude Code Workflow for Windows

Set up a complete "CLITOPHONE" system that allows SSH access to this Windows PC from a mobile phone (iOS or Android) to run Claude Code remotely with persistent sessions.

## Reference
Based on: https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/

## Requirements

### 1. Windows SSH Server
- [ ] Enable and configure OpenSSH Server on Windows
- [ ] Configure SSH to use WSL2 as the default shell
- [ ] Set up SSH key authentication (disable password auth for security)
- [ ] Create `~/.ssh/authorized_keys` with instructions for adding phone keys

### 2. Tailscale Networking
- [ ] Document Tailscale installation for Windows
- [ ] Create setup script or instructions for Tailscale configuration
- [ ] Document how to find the Tailscale hostname/IP for this machine
- [ ] Include instructions for installing Tailscale on iOS and Android

### 3. WSL2 Environment
- [ ] Ensure WSL2 is installed and configured
- [ ] Install required packages: mosh, tmux, nodejs (for Claude Code)
- [ ] Configure WSL2 to be accessible via SSH
- [ ] Set up environment variables (ANTHROPIC_API_KEY) in WSL2 shell profile

### 4. Mosh Server
- [ ] Install mosh-server in WSL2
- [ ] Configure mosh to work through SSH
- [ ] Document UDP port requirements (60000-61000) for Tailscale/firewall
- [ ] Test mosh connectivity

### 5. TMUX Configuration
- [x] Create `.tmux.conf` with sensible defaults for mobile use
- [x] Configure larger scrollback buffer
- [x] Set up easy-to-use key bindings
- [x] Configure status bar with session info and machine identifier emoji

### 6. Shell Scripts & Aliases
Create the following in `scripts/` directory:

- [x] `cc-start` - Start a new Claude Code session in TMUX
- [x] `cc-continue` - Resume existing Claude Code session or create new one
- [x] `tm` - TMUX session manager with machine-specific naming
- [x] `setup-env.sh` - One-time environment setup script
- [x] `ssh_config_example` - Template SSH config for phone clients

Add shell aliases to `.bashrc` or `.zshrc`:
```bash
alias cc='cc-continue'
alias ccs='cc-start'
```

### 7. Client Documentation
Create `docs/` directory with:

- [x] `SETUP-BLINK.md` - Blink.sh (iOS) configuration guide
- [x] `SETUP-TERMUX.md` - Termux (Android) configuration guide
- [x] `QUICKSTART.md` - TL;DR connection instructions
- [ ] `TROUBLESHOOTING.md` - Common issues and fixes

## Success Criteria
- [ ] Can SSH into Windows PC from phone via Tailscale
- [ ] Mosh provides persistent connection that survives network changes
- [ ] TMUX sessions persist across disconnections
- [ ] Claude Code runs smoothly in TMUX
- [ ] Multiple Claude Code sessions can run simultaneously
- [ ] Clear documentation exists for both iOS and Android setup
- [ ] All scripts are executable and tested

## Directory Structure
```
CLITOPHONE/
├── PROMPT.md
├── ralph.yml
├── README.md
├── scripts/
│   ├── cc-start
│   ├── cc-continue
│   ├── tm
│   └── setup-env.sh
├── config/
│   ├── .tmux.conf
│   └── ssh_config_example
└── docs/
    ├── SETUP-BLINK.md
    ├── SETUP-TERMUX.md
    ├── QUICKSTART.md
    └── TROUBLESHOOTING.md
```

## Notes
- This is a Windows host machine
- WSL2 is required for mosh and tmux
- Tailscale handles networking (no port forwarding needed)
- ANTHROPIC_API_KEY must be securely stored and loaded


## Progress Log

### Iteration 5 - Add ssh_config_example
- Created `config/ssh_config_example` - Template SSH config for phone clients
- Includes Tailscale hostname configuration, keep-alive settings, and compression
- Provides multiple host aliases (Tailscale, direct IP, LAN)

### Commit
`acabd53` - Add ssh_config_example for phone SSH client configuration

### Next iteration should:
Continue with one of the remaining documentation files (recommended: `docs/QUICKSTART.md`)


### Iteration 6 - Add QUICKSTART.md
- Created `docs/QUICKSTART.md` - TL;DR connection instructions
- Comprehensive 5-minute quick start guide with step-by-step instructions
- Includes prerequisites checklist, setup steps for PC and phone
- Quick reference tables for commands and TMUX shortcuts
- Basic troubleshooting section and workflow examples

### Commit
`4b36b47` - Add QUICKSTART.md - TL;DR connection guide

### Next iteration should:
Continue with remaining documentation files:
1. `docs/SETUP-BLINK.md` - Blink.sh (iOS) configuration guide
2. `docs/SETUP-TERMUX.md` - Termux (Android) configuration guide
3. `docs/TROUBLESHOOTING.md` - Common issues and fixes


### Iteration 7 - Add SETUP-BLINK.md
- Created `docs/SETUP-BLINK.md` - Comprehensive Blink Shell (iOS) configuration guide
- Covers SSH key generation, host configuration, mosh setup
- Includes Tailscale iOS setup instructions
- Provides recommended Blink settings for appearance, keyboard, and shell
- Documents TMUX shortcuts optimized for iOS (Caps as Ctrl)
- Includes gestures reference for Blink
- Comprehensive troubleshooting section for iOS-specific issues
- Tips for mobile development workflow

### Commit
`5053203` - Add SETUP-BLINK.md - iOS Blink Shell configuration guide

### Next iteration should:
Continue with remaining documentation files:
1. `docs/SETUP-TERMUX.md` - Termux (Android) configuration guide
2. `docs/TROUBLESHOOTING.md` - Common issues and fixes


### Iteration 8 - Add SETUP-TERMUX.md
- Created `docs/SETUP-TERMUX.md` - Comprehensive Termux (Android) configuration guide
- Covers F-Droid installation (emphasizes NOT using Play Store version)
- Includes Tailscale Android setup instructions
- SSH key generation and configuration with ControlMaster for multiplexing
- Mosh setup with quick-connect script
- Termux properties configuration (extra keys, colors, styling)
- Documents useful add-ons: Termux:Widget, Termux:Boot, Termux:API
- TMUX quick reference and CLITOPHONE commands
- Comprehensive troubleshooting section for Android-specific issues
- Tips for mobile development including external keyboard support
- Quick setup checklist for easy onboarding

### Commit
`a57c7bb` - Add SETUP-TERMUX.md - Android Termux configuration guide

### Next iteration should:
Create the final documentation file: `docs/TROUBLESHOOTING.md`
