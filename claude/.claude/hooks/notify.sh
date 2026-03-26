#!/bin/bash
# Notification hook for Claude permission requests
# Adds pane context (title or project) to the notification

set -e

INPUT=$(cat)
MSG=$(echo "$INPUT" | jq -r '.message // "Claude needs attention"')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Project name from cwd
PROJECT=$(basename "$CWD" 2>/dev/null || echo "")

# Title from /title skill (keyed by CWD)
TITLE=""
CWD_KEY=$(echo "$CWD" | tr '/' '_')
if [ -n "$CWD_KEY" ] && [ -f "$HOME/.cache/claude-code/titles/$CWD_KEY" ]; then
    TITLE=$(cat "$HOME/.cache/claude-code/titles/$CWD_KEY" 2>/dev/null || true)
fi

# Build context prefix
CTX=""
if [ -n "$TITLE" ]; then
    CTX="[$TITLE] "
elif [ -n "$PROJECT" ]; then
    CTX="[$PROJECT] "
fi

FULL_MSG="$CTX$MSG"
NOTIFY_TITLE="${TITLE:-Claude Code}"

# Find a writable tty for escape sequences
TTY="${SSH_TTY:-}"
[ -z "$TTY" ] && TTY="/dev/tty"

# 1. TTY available: bell + OSC 777 (propagates through SSH/tmux to local terminal)
if [ -w "$TTY" ]; then
    printf '\a' > "$TTY" 2>/dev/null || true
    printf '\033]777;notify;%s;%s\033\\' "$NOTIFY_TITLE" "$FULL_MSG" > "$TTY" 2>/dev/null || true
# 2. FIFO pipe
elif [ -p "/run/claude-notify/pipe" ]; then
    echo "${NOTIFY_TITLE}|${FULL_MSG}" > "/run/claude-notify/pipe" 2>/dev/null || true
# 3. Desktop notification
else
    case $(uname) in
        Darwin) terminal-notifier -title "$NOTIFY_TITLE" -message "$FULL_MSG" -sound Glass 2>/dev/null || true ;;
        *) [ -n "$DISPLAY$WAYLAND_DISPLAY" ] && notify-send "$NOTIFY_TITLE" "$FULL_MSG" 2>/dev/null || true ;;
    esac
fi
