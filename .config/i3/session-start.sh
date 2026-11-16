#!/usr/bin/env bash
# Explicit i3 helpers; Plasma starts its own services.
set -eu
[[ ${XDG_SESSION_TYPE:-x11} != wayland && -z ${WAYLAND_DISPLAY:-} && -n ${DISPLAY:-} ]] || exit 0
timeout 3s i3-msg -t get_version >/dev/null 2>&1 || exit 0
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/i3"
mkdir -p "$state_dir" "$HOME/screenshots"
chmod 700 "$state_dir"
exec >>"$state_dir/session.log" 2>&1
if command -v nm-applet >/dev/null; then
    nm-applet &
fi
if [[ -x /usr/lib/polkit-kde-authentication-agent-1 ]]; then
    /usr/lib/polkit-kde-authentication-agent-1 &
fi
# Keep the user's note app autostart when installed.
if command -v xpad >/dev/null; then
    xpad &
fi
