#!/usr/bin/env bash
#
# shell-helpers.sh - Shell integration for CLITOPHONE
# Source this file in your .bashrc or .zshrc
#
# Usage:
#   source ~/clitophone/scripts/shell-helpers.sh
#

# Determine script location
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    CLITOPHONE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
elif [[ -n "$ZSH_VERSION" ]]; then
    CLITOPHONE_DIR="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
else
    CLITOPHONE_DIR="$HOME/clitophone"
fi

# Load environment
if [[ -f "$CLITOPHONE_DIR/.env" ]]; then
    set -a
    source "$CLITOPHONE_DIR/.env"
    set +a
fi

# Add scripts to PATH
export PATH="$CLITOPHONE_DIR/scripts:$PATH"

# Aliases
alias tm="$CLITOPHONE_DIR/scripts/tm"
alias unlock="$CLITOPHONE_DIR/scripts/unlock.sh"
alias cc-start="$CLITOPHONE_DIR/scripts/cc-start"
alias cc-continue="$CLITOPHONE_DIR/scripts/cc-continue"

# Convenience aliases
alias ccs="cc-start"
alias ccc="cc-continue"

# Quick unlock and start
cc() {
    # Ensure credentials are available
    if ! "$CLITOPHONE_DIR/scripts/unlock.sh" --check &>/dev/null; then
        "$CLITOPHONE_DIR/scripts/unlock.sh"
    fi

    # Start Claude Code
    if [[ $# -gt 0 ]]; then
        cc-start "$@"
    else
        cc-start
    fi
}

# TMUX quick helpers
t() {
    tm "${1:-dev}"
}

# Show status on shell start (optional)
clitophone_status() {
    echo "CLITOPHONE Remote Claude Code"
    echo "────────────────────────────"
    echo "Commands: tm, cc, cc-start, cc-continue, unlock"
    echo ""
    "$CLITOPHONE_DIR/scripts/unlock.sh" --check 2>/dev/null || true
}

# Uncomment to show status on every new shell:
# clitophone_status
