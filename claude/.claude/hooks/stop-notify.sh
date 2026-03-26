#!/bin/bash
# Notification hook for Claude Stop event
# Extracts project, title (from /title skill), and first user message (the task)

set -e

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Project name from cwd
PROJECT=$(basename "$CWD" 2>/dev/null || echo "unknown")

# Title from /title skill (keyed by CWD)
TITLE=""
CWD_KEY=$(echo "$CWD" | tr '/' '_')
if [ -n "$CWD_KEY" ] && [ -f "$HOME/.cache/claude-code/titles/$CWD_KEY" ]; then
    TITLE=$(cat "$HOME/.cache/claude-code/titles/$CWD_KEY" 2>/dev/null || true)
fi

# First user message = the task (efficient: head + first match)
TASK=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    TASK=$(head -100 "$TRANSCRIPT" | jq -r 'select(.type == "user") | .message.content[0].text // empty' 2>/dev/null | head -1 | cut -c1-80)
fi

# Build message: TITLE overrides TASK
MSG="$PROJECT"
if [ -n "$TITLE" ]; then
    MSG="$TITLE | $MSG"
elif [ -n "$TASK" ]; then
    MSG="$MSG: $TASK"
else
    MSG="$MSG: Ready"
fi

NOTIFY_TITLE="${TITLE:-Claude Code}"

# Find a writable tty for escape sequences
TTY="${SSH_TTY:-}"
[ -z "$TTY" ] && TTY="/dev/tty"

# 1. TTY available: bell + OSC 777 (propagates through SSH/tmux to local terminal)
if [ -w "$TTY" ]; then
    printf '\a' > "$TTY" 2>/dev/null || true
    printf '\033]777;notify;%s;%s\033\\' "$NOTIFY_TITLE" "$MSG" > "$TTY" 2>/dev/null || true
# 2. FIFO pipe
elif [ -p "/run/claude-notify/pipe" ]; then
    echo "${NOTIFY_TITLE}|${MSG}" > "/run/claude-notify/pipe" 2>/dev/null || true
# 3. Desktop notification
else
    case $(uname) in
        Darwin) terminal-notifier -title "$NOTIFY_TITLE" -message "$MSG" -sound Glass 2>/dev/null || true ;;
        *) [ -n "$DISPLAY$WAYLAND_DISPLAY" ] && notify-send "$NOTIFY_TITLE" "$MSG" 2>/dev/null || true ;;
    esac
fi
