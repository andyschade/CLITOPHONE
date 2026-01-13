#!/usr/bin/env bash
#
# unlock.sh - Credential and Keychain Management
# Handles unlocking credentials for headless/remote operation
#
# Usage:
#   ./unlock.sh          Interactive unlock
#   ./unlock.sh --check  Verify unlock status
#   ./unlock.sh --ssh    Unlock SSH agent only
#   ./unlock.sh --api    Unlock API keys only
#

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../.env" ]]; then
    source "$SCRIPT_DIR/../.env"
fi

# Defaults
KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-anthropic-api}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

print_status() {
    local status="$1"
    local message="$2"

    if [[ "$status" == "ok" ]]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [[ "$status" == "warn" ]]; then
        echo -e "${YELLOW}!${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
}

# Check if SSH agent is running and has keys
check_ssh_agent() {
    if ssh-add -l &>/dev/null; then
        local key_count=$(ssh-add -l | wc -l)
        print_status "ok" "SSH agent: $key_count key(s) loaded"
        return 0
    else
        print_status "fail" "SSH agent: no keys loaded"
        return 1
    fi
}

# Unlock SSH agent
unlock_ssh() {
    echo -e "${BLUE}Unlocking SSH agent...${NC}"

    # Start agent if not running
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        eval "$(ssh-agent -s)"
    fi

    # Add default key
    if [[ -f "$SSH_KEY_PATH" ]]; then
        if [[ "$OS" == "macos" ]]; then
            # Use macOS keychain for passphrase
            ssh-add --apple-use-keychain "$SSH_KEY_PATH" 2>/dev/null || ssh-add "$SSH_KEY_PATH"
        else
            ssh-add "$SSH_KEY_PATH"
        fi
        print_status "ok" "Added SSH key: $SSH_KEY_PATH"
    else
        print_status "warn" "SSH key not found: $SSH_KEY_PATH"
    fi
}

# Check API key availability
check_api_key() {
    if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
        print_status "ok" "ANTHROPIC_API_KEY: set in environment"
        return 0
    fi

    if [[ "$OS" == "macos" ]]; then
        if security find-generic-password -s "$KEYCHAIN_SERVICE" &>/dev/null; then
            print_status "ok" "API key: available in keychain"
            return 0
        fi
    fi

    print_status "fail" "API key: not found"
    return 1
}

# Unlock/retrieve API key from keychain (macOS)
unlock_api_macos() {
    echo -e "${BLUE}Retrieving API key from keychain...${NC}"

    local api_key
    api_key=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null) || {
        print_status "fail" "Could not retrieve API key from keychain"
        echo ""
        echo "To store your API key in keychain:"
        echo "  security add-generic-password -s '$KEYCHAIN_SERVICE' -a '\$USER' -w 'YOUR_API_KEY'"
        return 1
    }

    export ANTHROPIC_API_KEY="$api_key"
    print_status "ok" "API key loaded from keychain"
}

# Unlock API key on Linux (from encrypted file or prompt)
unlock_api_linux() {
    echo -e "${BLUE}Loading API key...${NC}"

    local key_file="$HOME/.config/anthropic/api_key.gpg"

    if [[ -f "$key_file" ]]; then
        local api_key
        api_key=$(gpg --quiet --decrypt "$key_file" 2>/dev/null) || {
            print_status "fail" "Could not decrypt API key"
            return 1
        }
        export ANTHROPIC_API_KEY="$api_key"
        print_status "ok" "API key loaded from encrypted file"
    else
        print_status "warn" "No encrypted key file found at $key_file"
        echo "Enter your Anthropic API key:"
        read -rs api_key
        export ANTHROPIC_API_KEY="$api_key"
        print_status "ok" "API key set from input"
    fi
}

unlock_api() {
    case "$OS" in
        macos)  unlock_api_macos ;;
        linux)  unlock_api_linux ;;
        *)
            print_status "warn" "Manual API key entry required on this platform"
            echo "Enter your Anthropic API key:"
            read -rs api_key
            export ANTHROPIC_API_KEY="$api_key"
            ;;
    esac
}

# Full status check
check_all() {
    echo -e "${BLUE}Credential Status${NC}"
    echo "─────────────────"

    local all_ok=true

    check_ssh_agent || all_ok=false
    check_api_key || all_ok=false

    echo ""

    if $all_ok; then
        echo -e "${GREEN}All credentials ready${NC}"
        return 0
    else
        echo -e "${YELLOW}Some credentials need attention${NC}"
        echo "Run './unlock.sh' to unlock"
        return 1
    fi
}

# Full unlock
unlock_all() {
    echo -e "${BLUE}Unlocking credentials...${NC}"
    echo ""

    unlock_ssh
    echo ""
    unlock_api

    echo ""
    echo -e "${GREEN}Unlock complete${NC}"
}

# Parse arguments
case "${1:-}" in
    --check|-c)
        check_all
        ;;
    --ssh|-s)
        unlock_ssh
        ;;
    --api|-a)
        unlock_api
        ;;
    --help|-h)
        echo "unlock.sh - Credential and Keychain Management"
        echo ""
        echo "Usage:"
        echo "  ./unlock.sh          Interactive unlock (SSH + API)"
        echo "  ./unlock.sh --check  Verify unlock status"
        echo "  ./unlock.sh --ssh    Unlock SSH agent only"
        echo "  ./unlock.sh --api    Unlock API keys only"
        ;;
    *)
        unlock_all
        ;;
esac
