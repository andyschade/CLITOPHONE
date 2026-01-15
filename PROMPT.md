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
- [ ] `setup-env.sh` - One-time environment setup script

Add shell aliases to `.bashrc` or `.zshrc`:
```bash
alias cc='cc-continue'
alias ccs='cc-start'
```

### 7. Client Documentation
Create `docs/` directory with:

- [ ] `SETUP-BLINK.md` - Blink.sh (iOS) configuration guide
- [ ] `SETUP-TERMUX.md` - Termux (Android) configuration guide
- [ ] `QUICKSTART.md` - TL;DR connection instructions
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
