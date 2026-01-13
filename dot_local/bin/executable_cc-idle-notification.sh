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
        # Not in tmux, just send macOS notification
        send_macos_notification
        return 0
    fi

    # Get current window index (use -t to target the pane where this script runs)
    local current_window
    current_window=$(tmux display-message -t "$TMUX_PANE" -p '#I')

    # Skip notification if user is already viewing this window
    # We can't use #{window_active} directly as it's always 1 from within the pane
    # Instead, check which window is actually active in the session
    local active_window
    active_window=$(tmux list-windows -F '#{window_index}:#{window_active}' | grep ':1$' | cut -d: -f1)
    if [[ "$current_window" == "$active_window" ]]; then
        return 0
    fi

    # Send macOS notification (only when user is not viewing this window)
    send_macos_notification

    # Send bell to trigger visual/audio alert (works with monitor-bell)
    # The bell character triggers tmux's bell-action and monitor-bell
    printf '\a'

    # Set alert flag on the window using tmux's built-in alert system
    # This will be shown based on window-status-alert-style
    tmux set-window-option -t "${current_window}" monitor-bell on 2>/dev/null || true

    # Display a brief message in tmux status line
    tmux display-message "Claude Code is idle - waiting for input" 2>/dev/null || true

    # Add a visual marker to window name (prefix with 🔔)
    local original_name
    original_name=$(tmux display-message -t "$TMUX_PANE" -p '#W')

    # Remove stale emoji and hook if present (cleanup from previous failed attempts)
    original_name="${original_name#🔔}"
    tmux set-hook -uw -t "${current_window}" pane-focus-in 2>/dev/null || true

    tmux rename-window -t "${current_window}" "🔔${original_name}" 2>/dev/null || true

    # Set up a hook to remove the emoji when user focuses on this window
    # The hook removes itself after firing once
    tmux set-hook -w -t "${current_window}" pane-focus-in "run-shell 'name=\$(tmux display-message -p \"#W\"); case \"\$name\" in 🔔*) tmux rename-window \"\${name#🔔}\";; esac'; set-hook -uw pane-focus-in" 2>/dev/null || true
}

# --- Main ---
main() {
    send_tmux_notification
}

main "$@"
