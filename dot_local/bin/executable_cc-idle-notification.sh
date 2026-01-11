#!/bin/bash -eu

# Claude Code idle notification script
# This script sends a notification when Claude Code has been idle for 60 seconds.

# Gather context information
CWD="${PWD}"
DIR_NAME="${PWD##*/}"
TMUX_SESSION=""
TMUX_WINDOW=""

if [[ -n "${TMUX:-}" ]]; then
    TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")
    TMUX_WINDOW=$(tmux display-message -p '#W' 2>/dev/null || echo "")
fi

# --- macOS Notification ---
send_macos_notification() {
    if [[ "$(uname)" != "Darwin" ]]; then
        return 0
    fi

    local title="Claude Code Idle"
    local message="Session is waiting for input"
    local subtitle=""

    # Build context subtitle
    if [[ -n "$TMUX_SESSION" ]]; then
        subtitle="tmux: ${TMUX_SESSION}/${TMUX_WINDOW} • ${DIR_NAME}"
    else
        subtitle="${CWD}"
    fi

    # Use osascript to send notification (built-in, no dependencies)
    osascript -e "display notification \"${message}\" with title \"${title}\" subtitle \"${subtitle}\" sound name \"Glass\""
}

# --- tmux Notification ---
send_tmux_notification() {
    if [[ -z "${TMUX:-}" ]]; then
        return 0
    fi

    # Get current window index
    local current_window
    current_window=$(tmux display-message -p '#I')

    # Send bell to trigger visual/audio alert (works with monitor-bell)
    # The bell character triggers tmux's bell-action and monitor-bell
    printf '\a'

    # Set alert flag on the window using tmux's built-in alert system
    # This will be shown based on window-status-alert-style
    tmux set-window-option -t "${current_window}" monitor-bell on 2>/dev/null || true

    # Display a brief message in tmux status line
    tmux display-message "Claude Code is idle - waiting for input" 2>/dev/null || true

    # Optional: Add a visual marker to window name (prefix with !)
    # The user can clear this by running any command or we restore it
    local original_name
    original_name=$(tmux display-message -p '#W')

    # Only add marker if not already present
    if [[ "${original_name}" != "🔔"* ]]; then
        tmux rename-window "🔔${original_name}" 2>/dev/null || true
    fi
}

# --- Main ---
main() {
    send_macos_notification
    send_tmux_notification
}

main "$@"
