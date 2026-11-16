#!/usr/bin/env bash
# One compositor per X display; never attach Picom to Plasma's Xwayland.
set -eu
[[ ${XDG_SESSION_TYPE:-x11} != wayland && -z ${WAYLAND_DISPLAY:-} && -n ${DISPLAY:-} ]] || exit 0
timeout 3s i3-msg -t get_version >/dev/null 2>&1 || exit 0
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/i3"
mkdir -p "$state_dir"
chmod 700 "$state_dir"
display_tag=${DISPLAY//[^a-zA-Z0-9_-]/_}
exec 9>"$state_dir/picom-$display_tag.lock"
flock -n 9 || exit 0
# The lock is deliberately inherited by Picom until it exits.
exec picom --config "$HOME/.config/i3/picom.conf"     >>"$state_dir/picom-$display_tag.log" 2>&1
