#!/usr/bin/env bash
# Preserve the existing provider/key; keep the bar compact and bound network waits.
set -u
script="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/polybar-scripts/openweathermap.sh"
[[ -x $script ]] || exit 0
output=$(timeout --kill-after=2s 12s "$script" 2>/dev/null) || exit 0
awk 'NF >= 2 { print $1 " " $2; exit }' <<< "$output"
