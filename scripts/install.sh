#!/usr/bin/env bash
#
# install.sh - CLITOPHONE Installation Script
#
# This script:
# 1. Checks for required dependencies
# 2. Makes scripts executable
# 3. Sets up shell integration
# 4. Creates initial configuration
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}CLITOPHONE Installer${NC}"
echo "═══════════════════════"
echo ""

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

OS=$(detect_os)
echo -e "Detected OS: ${GREEN}$OS${NC}"
echo ""

# Check dependencies
echo -e "${BLUE}Checking dependencies...${NC}"

check_command() {
    local cmd="$1"
    local install_hint="$2"

    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd"
        return 0
    else
        echo -e "  ${RED}✗${NC} $cmd - $install_hint"
        return 1
    fi
}

MISSING_DEPS=false

check_command "tmux" "brew install tmux / apt install tmux" || MISSING_DEPS=true
check_command "mosh" "brew install mosh / apt install mosh" || MISSING_DEPS=true
check_command "claude" "Install from https://claude.ai/code" || MISSING_DEPS=true
check_command "ssh" "Should be pre-installed" || MISSING_DEPS=true

# Optional but recommended
echo ""
echo -e "${BLUE}Optional dependencies:${NC}"
check_command "tailscale" "Install from https://tailscale.com" || true
check_command "gpg" "brew install gnupg / apt install gnupg" || true

echo ""

if $MISSING_DEPS; then
    echo -e "${YELLOW}Warning: Some required dependencies are missing.${NC}"
    echo "Install them before using CLITOPHONE."
    echo ""
fi

# Make scripts executable
echo -e "${BLUE}Setting up scripts...${NC}"

chmod +x "$SCRIPT_DIR/tm" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/unlock.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/cc-start" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/cc-continue" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/shell-helpers.sh" 2>/dev/null || true

echo -e "  ${GREEN}✓${NC} Scripts are executable"

# Create .env if it doesn't exist
if [[ ! -f "$PROJECT_DIR/.env" ]]; then
    if [[ -f "$PROJECT_DIR/.env.example" ]]; then
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        echo -e "  ${GREEN}✓${NC} Created .env from template"
    fi
fi

# Detect shell
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        basename "$SHELL"
    fi
}

SHELL_TYPE=$(detect_shell)
echo ""
echo -e "${BLUE}Shell integration${NC}"
echo ""

# Generate shell integration line
SHELL_LINE="source \"$PROJECT_DIR/scripts/shell-helpers.sh\""

case "$SHELL_TYPE" in
    zsh)
        RC_FILE="$HOME/.zshrc"
        ;;
    bash)
        if [[ "$OS" == "macos" ]]; then
            RC_FILE="$HOME/.bash_profile"
        else
            RC_FILE="$HOME/.bashrc"
        fi
        ;;
    *)
        RC_FILE="$HOME/.profile"
        ;;
esac

# Check if already installed
if [[ -f "$RC_FILE" ]] && grep -q "clitophone" "$RC_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Already configured in $RC_FILE"
else
    echo "Add this line to your $RC_FILE:"
    echo ""
    echo -e "  ${YELLOW}$SHELL_LINE${NC}"
    echo ""

    read -p "Add automatically? [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "" >> "$RC_FILE"
        echo "# CLITOPHONE - Remote Claude Code" >> "$RC_FILE"
        echo "$SHELL_LINE" >> "$RC_FILE"
        echo -e "${GREEN}✓${NC} Added to $RC_FILE"
        echo ""
        echo "Run this to activate now:"
        echo -e "  ${YELLOW}source $RC_FILE${NC}"
    fi
fi

# TMUX config
echo ""
echo -e "${BLUE}TMUX configuration${NC}"
echo ""

if [[ -f "$HOME/.tmux.conf" ]]; then
    echo -e "${YELLOW}!${NC} Existing ~/.tmux.conf found"
    echo "  Our config is at: $PROJECT_DIR/config/tmux.conf"
    echo "  You can include it with: source-file $PROJECT_DIR/config/tmux.conf"
else
    if [[ -f "$PROJECT_DIR/config/tmux.conf" ]]; then
        read -p "Install TMUX config to ~/.tmux.conf? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$PROJECT_DIR/config/tmux.conf" "$HOME/.tmux.conf"
            echo -e "${GREEN}✓${NC} Installed TMUX config"
        fi
    fi
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Install any missing dependencies shown above"
echo "  2. Edit $PROJECT_DIR/.env with your settings"
echo "  3. Set up Tailscale: tailscale up"
echo "  4. Restart your shell or run: source $RC_FILE"
echo ""
echo "Quick start:"
echo "  tm work         # Start a TMUX session"
echo "  cc-start        # Launch Claude Code"
echo ""
