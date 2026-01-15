#!/usr/bin/env bash
# setup-env.sh - One-time environment setup for CLITOPHONE
# This script sets up WSL2 environment for remote Claude Code access
# Run this script once after cloning the repository

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"

# Default machine emoji (can be customized)
DEFAULT_EMOJI="🖥️"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

log_header() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response

    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n] " -n 1 -r response
    else
        read -p "$prompt [y/N] " -n 1 -r response
    fi
    echo

    if [[ -z "$response" ]]; then
        response="$default"
    fi

    [[ "$response" =~ ^[Yy]$ ]]
}

command_exists() {
    command -v "$1" &> /dev/null
}

# =============================================================================
# SYSTEM CHECKS
# =============================================================================

check_wsl() {
    log_step "Checking WSL environment..."

    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        log_success "Running in WSL2"
        return 0
    else
        log_warn "Not running in WSL2. Some features may not work."
        log_info "This script is designed for WSL2 on Windows."
        return 1
    fi
}

check_package_manager() {
    if command_exists apt; then
        echo "apt"
    elif command_exists apt-get; then
        echo "apt-get"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    else
        echo "unknown"
    fi
}

# =============================================================================
# PACKAGE INSTALLATION
# =============================================================================

install_packages() {
    log_header "Installing Required Packages"

    local pkg_manager
    pkg_manager=$(check_package_manager)

    if [[ "$pkg_manager" == "unknown" ]]; then
        log_error "Could not detect package manager."
        log_info "Please install manually: tmux, mosh, nodejs, fzf"
        return 1
    fi

    log_info "Detected package manager: $pkg_manager"

    # Update package list
    log_step "Updating package list..."
    case "$pkg_manager" in
        apt|apt-get)
            sudo apt-get update
            ;;
        dnf)
            sudo dnf check-update || true
            ;;
        yum)
            sudo yum check-update || true
            ;;
    esac

    # Install packages
    local packages=("tmux" "mosh" "fzf" "curl" "git")

    for pkg in "${packages[@]}"; do
        log_step "Installing $pkg..."
        case "$pkg_manager" in
            apt|apt-get)
                sudo apt-get install -y "$pkg" || log_warn "Failed to install $pkg"
                ;;
            dnf)
                sudo dnf install -y "$pkg" || log_warn "Failed to install $pkg"
                ;;
            yum)
                sudo yum install -y "$pkg" || log_warn "Failed to install $pkg"
                ;;
        esac
    done

    # Install Node.js via NodeSource if not present
    if ! command_exists node; then
        log_step "Installing Node.js..."
        if [[ "$pkg_manager" == "apt" || "$pkg_manager" == "apt-get" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        else
            log_warn "Please install Node.js manually for your distribution"
        fi
    fi

    log_success "Package installation complete"
}

verify_packages() {
    log_header "Verifying Installed Packages"

    local all_ok=true

    local required_commands=("tmux" "mosh-server" "node" "npm")

    for cmd in "${required_commands[@]}"; do
        if command_exists "$cmd"; then
            local version
            case "$cmd" in
                tmux)
                    version=$(tmux -V 2>/dev/null || echo "unknown")
                    ;;
                mosh-server)
                    version=$(mosh-server --version 2>&1 | head -1 || echo "unknown")
                    ;;
                node)
                    version=$(node --version 2>/dev/null || echo "unknown")
                    ;;
                npm)
                    version=$(npm --version 2>/dev/null || echo "unknown")
                    ;;
                *)
                    version="installed"
                    ;;
            esac
            log_success "$cmd: $version"
        else
            log_error "$cmd: NOT FOUND"
            all_ok=false
        fi
    done

    # Check optional commands
    local optional_commands=("fzf" "git" "claude")

    echo ""
    log_info "Optional commands:"
    for cmd in "${optional_commands[@]}"; do
        if command_exists "$cmd"; then
            log_success "$cmd: installed"
        else
            log_warn "$cmd: not installed"
        fi
    done

    if ! $all_ok; then
        log_error "Some required packages are missing. Please install them manually."
        return 1
    fi
}

# =============================================================================
# CLAUDE CODE INSTALLATION
# =============================================================================

install_claude_code() {
    log_header "Claude Code Setup"

    if command_exists claude; then
        log_success "Claude Code is already installed"
        claude --version 2>/dev/null || true
        return 0
    fi

    log_info "Claude Code is not installed."
    log_info "To install Claude Code, run:"
    echo ""
    echo -e "  ${CYAN}npm install -g @anthropic-ai/claude-code${NC}"
    echo ""

    if prompt_yes_no "Install Claude Code now?"; then
        log_step "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        log_success "Claude Code installed"
    else
        log_warn "Skipping Claude Code installation"
        log_info "You can install it later with: npm install -g @anthropic-ai/claude-code"
    fi
}

# =============================================================================
# TMUX CONFIGURATION
# =============================================================================

setup_tmux_config() {
    log_header "TMUX Configuration"

    local tmux_conf="$HOME/.tmux.conf"
    local source_conf="$CONFIG_DIR/.tmux.conf"

    if [[ ! -f "$source_conf" ]]; then
        log_error "Source tmux config not found: $source_conf"
        return 1
    fi

    if [[ -f "$tmux_conf" ]]; then
        log_warn "Existing .tmux.conf found at $tmux_conf"

        if diff -q "$tmux_conf" "$source_conf" &>/dev/null; then
            log_success "TMUX config is already up to date"
            return 0
        fi

        if prompt_yes_no "Backup existing and install new config?"; then
            local backup="$tmux_conf.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$tmux_conf" "$backup"
            log_info "Backed up to: $backup"
        else
            log_info "Skipping TMUX config installation"
            return 0
        fi
    fi

    log_step "Installing TMUX configuration..."
    cp "$source_conf" "$tmux_conf"
    log_success "TMUX config installed to $tmux_conf"
}

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

setup_shell_config() {
    log_header "Shell Configuration"

    # Detect shell
    local shell_rc=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
    else
        log_warn "Unknown shell: $SHELL"
        shell_rc="$HOME/.bashrc"
    fi

    log_info "Configuring shell: $shell_rc"

    # Check if already configured
    if grep -q "CLITOPHONE" "$shell_rc" 2>/dev/null; then
        log_success "CLITOPHONE already configured in $shell_rc"
        return 0
    fi

    # Get machine emoji
    local emoji="$DEFAULT_EMOJI"
    echo ""
    echo -e "${CYAN}Choose a machine identifier emoji for this device:${NC}"
    echo "  This will appear in your tmux status bar and help identify"
    echo "  which machine you're connected to."
    echo ""
    echo "  Suggestions: 🖥️ (desktop), 💻 (laptop), 🏠 (home), 🏢 (work)"
    echo "               🌙 (night), ☀️ (day), 🔥 (fast), 🐢 (slow)"
    echo ""
    read -p "Enter emoji [$DEFAULT_EMOJI]: " user_emoji

    if [[ -n "$user_emoji" ]]; then
        emoji="$user_emoji"
    fi

    # Prepare configuration block
    local config_block
    config_block=$(cat << EOF

# =============================================================================
# CLITOPHONE Configuration
# Remote Claude Code access setup
# =============================================================================

# Machine identifier (shows in tmux status bar)
export CLITOPHONE_EMOJI="$emoji"
export CLITOPHONE_MACHINE="$(hostname -s 2>/dev/null || hostname)"

# Add CLITOPHONE scripts to PATH
export PATH="$SCRIPT_DIR:\$PATH"

# Aliases for Claude Code sessions
alias cc='cc-continue'
alias ccs='cc-start'

# ANTHROPIC_API_KEY - Uncomment and add your key, or use a secrets manager
# export ANTHROPIC_API_KEY="your-api-key-here"

# Auto-start tmux for SSH sessions (optional)
# Uncomment to automatically attach to tmux when connecting via SSH
# if [[ -n "\$SSH_CONNECTION" ]] && [[ -z "\$TMUX" ]]; then
#     tmux attach-session -t main 2>/dev/null || tmux new-session -s main
# fi

# =============================================================================
EOF
)

    # Add to shell config
    log_step "Adding CLITOPHONE configuration to $shell_rc..."
    echo "$config_block" >> "$shell_rc"
    log_success "Shell configuration added"

    log_info "Configuration added:"
    echo -e "  ${GREEN}CLITOPHONE_EMOJI${NC}=$emoji"
    echo -e "  ${GREEN}CLITOPHONE_MACHINE${NC}=$(hostname -s 2>/dev/null || hostname)"
    echo -e "  ${GREEN}PATH${NC} includes $SCRIPT_DIR"
    echo -e "  ${GREEN}Aliases${NC}: cc, ccs"
}

# =============================================================================
# API KEY SETUP
# =============================================================================

setup_api_key() {
    log_header "API Key Configuration"

    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        log_success "ANTHROPIC_API_KEY is already set"
        return 0
    fi

    log_warn "ANTHROPIC_API_KEY is not set"
    echo ""
    log_info "Claude Code requires an Anthropic API key to function."
    log_info "You can get one from: https://console.anthropic.com/"
    echo ""
    log_info "Options for storing your API key:"
    echo ""
    echo "  1. Add to shell config (simple, less secure):"
    echo "     Edit ~/.bashrc or ~/.zshrc and add:"
    echo -e "     ${CYAN}export ANTHROPIC_API_KEY=\"your-key-here\"${NC}"
    echo ""
    echo "  2. Use a secrets manager (recommended for security):"
    echo "     - 1Password CLI: op read 'op://vault/anthropic/api-key'"
    echo "     - Pass: pass show anthropic/api-key"
    echo "     - Keychain (macOS): security find-generic-password ..."
    echo ""
    echo "  3. Environment file (medium security):"
    echo "     Create ~/.clitophone_secrets (chmod 600) and source it"
    echo ""

    if prompt_yes_no "Would you like to enter your API key now?" "n"; then
        read -sp "Enter your ANTHROPIC_API_KEY: " api_key
        echo ""

        if [[ -n "$api_key" ]]; then
            # Store in secrets file
            local secrets_file="$HOME/.clitophone_secrets"
            echo "export ANTHROPIC_API_KEY=\"$api_key\"" > "$secrets_file"
            chmod 600 "$secrets_file"

            # Add source to shell config
            local shell_rc="$HOME/.bashrc"
            [[ "$SHELL" == *"zsh"* ]] && shell_rc="$HOME/.zshrc"

            if ! grep -q "clitophone_secrets" "$shell_rc" 2>/dev/null; then
                echo "" >> "$shell_rc"
                echo "# Load CLITOPHONE secrets" >> "$shell_rc"
                echo "[[ -f ~/.clitophone_secrets ]] && source ~/.clitophone_secrets" >> "$shell_rc"
            fi

            log_success "API key stored in ~/.clitophone_secrets"
            log_info "File permissions set to 600 (owner only)"

            # Export for current session
            export ANTHROPIC_API_KEY="$api_key"
        fi
    else
        log_info "Skipping API key setup"
        log_info "Remember to set ANTHROPIC_API_KEY before using Claude Code"
    fi
}

# =============================================================================
# SSH SETUP
# =============================================================================

setup_ssh() {
    log_header "SSH Configuration"

    local ssh_dir="$HOME/.ssh"
    local authorized_keys="$ssh_dir/authorized_keys"

    # Create .ssh directory if needed
    if [[ ! -d "$ssh_dir" ]]; then
        log_step "Creating .ssh directory..."
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi

    # Create authorized_keys if needed
    if [[ ! -f "$authorized_keys" ]]; then
        log_step "Creating authorized_keys file..."
        touch "$authorized_keys"
        chmod 600 "$authorized_keys"
    fi

    log_success "SSH directory configured"
    log_info "authorized_keys location: $authorized_keys"

    echo ""
    log_info "To add your phone's SSH key:"
    echo ""
    echo "  1. Generate a key on your phone (in Blink or Termux):"
    echo -e "     ${CYAN}ssh-keygen -t ed25519 -C \"phone\"${NC}"
    echo ""
    echo "  2. Copy the public key to this machine:"
    echo -e "     ${CYAN}ssh-copy-id user@$(hostname)${NC}"
    echo ""
    echo "  Or manually add your public key to:"
    echo -e "     ${CYAN}$authorized_keys${NC}"
    echo ""

    # Show current authorized keys
    if [[ -s "$authorized_keys" ]]; then
        local key_count
        key_count=$(wc -l < "$authorized_keys")
        log_info "Current authorized keys: $key_count"
    else
        log_warn "No SSH keys configured yet"
    fi
}

# =============================================================================
# MOSH SETUP
# =============================================================================

setup_mosh() {
    log_header "Mosh Server Configuration"

    if command_exists mosh-server; then
        log_success "Mosh server is installed"
        mosh-server --version 2>&1 | head -1 || true
    else
        log_error "Mosh server is not installed"
        return 1
    fi

    echo ""
    log_info "Mosh port requirements:"
    echo ""
    echo "  Mosh uses UDP ports 60000-61000 for connections."
    echo "  If using Tailscale, these ports are usually accessible by default."
    echo ""
    echo "  For Windows Firewall, you may need to allow these ports."
    echo "  See docs/TROUBLESHOOTING.md for firewall configuration."
    echo ""

    log_success "Mosh is ready to use"
}

# =============================================================================
# FINAL VERIFICATION
# =============================================================================

final_check() {
    log_header "Setup Verification"

    local all_ok=true

    echo ""
    echo -e "${BOLD}Checking installation...${NC}"
    echo ""

    # Check required commands
    local checks=(
        "tmux:Required for session management"
        "mosh-server:Required for persistent connections"
        "node:Required for Claude Code"
        "npm:Required for installing packages"
    )

    for check in "${checks[@]}"; do
        local cmd="${check%%:*}"
        local desc="${check#*:}"

        if command_exists "$cmd"; then
            echo -e "  ${GREEN}✓${NC} $cmd - $desc"
        else
            echo -e "  ${RED}✗${NC} $cmd - $desc"
            all_ok=false
        fi
    done

    # Check optional commands
    echo ""
    local optional_checks=(
        "claude:Claude Code CLI"
        "fzf:Interactive session picker"
    )

    for check in "${optional_checks[@]}"; do
        local cmd="${check%%:*}"
        local desc="${check#*:}"

        if command_exists "$cmd"; then
            echo -e "  ${GREEN}✓${NC} $cmd - $desc"
        else
            echo -e "  ${YELLOW}○${NC} $cmd - $desc (optional)"
        fi
    done

    # Check configuration
    echo ""
    echo -e "${BOLD}Checking configuration...${NC}"
    echo ""

    if [[ -f "$HOME/.tmux.conf" ]]; then
        echo -e "  ${GREEN}✓${NC} ~/.tmux.conf exists"
    else
        echo -e "  ${YELLOW}○${NC} ~/.tmux.conf not found"
    fi

    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        echo -e "  ${GREEN}✓${NC} ANTHROPIC_API_KEY is set"
    else
        echo -e "  ${YELLOW}○${NC} ANTHROPIC_API_KEY not set (required for Claude Code)"
    fi

    if [[ -n "${CLITOPHONE_EMOJI:-}" ]]; then
        echo -e "  ${GREEN}✓${NC} CLITOPHONE_EMOJI is set: $CLITOPHONE_EMOJI"
    else
        echo -e "  ${YELLOW}○${NC} CLITOPHONE_EMOJI not set"
    fi

    echo ""

    if $all_ok; then
        log_success "All required components are installed!"
    else
        log_error "Some required components are missing"
    fi

    return 0
}

show_next_steps() {
    log_header "Next Steps"

    echo ""
    echo -e "${BOLD}Your CLITOPHONE setup is complete!${NC}"
    echo ""
    echo "To get started:"
    echo ""
    echo -e "  1. ${CYAN}Reload your shell:${NC}"
    echo "     source ~/.bashrc  # or ~/.zshrc"
    echo ""
    echo -e "  2. ${CYAN}Start Claude Code:${NC}"
    echo "     cc              # Resume or start a session"
    echo "     ccs myproject   # Start a named session"
    echo ""
    echo -e "  3. ${CYAN}From your phone:${NC}"
    echo "     mosh user@$(hostname --short 2>/dev/null || hostname) -- tmux attach"
    echo ""
    echo -e "  4. ${CYAN}Session management:${NC}"
    echo "     tm              # Interactive session picker"
    echo "     tm list         # List all sessions"
    echo "     tm new project  # Create new session"
    echo ""
    echo "See docs/ for detailed setup guides for Blink (iOS) and Termux (Android)."
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    echo -e "${CYAN}${BOLD}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  CLITOPHONE Setup"
    echo "  Remote Claude Code Access for Mobile Devices"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"

    # Check if running in WSL
    check_wsl || true

    # Install packages
    if prompt_yes_no "Install/update required packages?"; then
        install_packages
    fi

    # Verify packages
    verify_packages || true

    # Install Claude Code
    install_claude_code

    # Setup TMUX config
    setup_tmux_config

    # Setup shell configuration
    setup_shell_config

    # Setup API key
    setup_api_key

    # Setup SSH
    setup_ssh

    # Setup Mosh
    setup_mosh

    # Final verification
    final_check

    # Show next steps
    show_next_steps

    log_success "Setup complete!"
    echo ""
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
