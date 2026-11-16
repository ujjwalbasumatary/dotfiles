#!/usr/bin/env bash
# One bar per output, managed only within this user's current i3 X11 display.
set -euo pipefail
umask 077

if [[ -z ${DISPLAY:-} || ${XDG_SESSION_TYPE:-} == wayland || -n ${WAYLAND_DISPLAY:-} ]]; then
    printf '%s\n' 'Polybar is only started in an i3 X11 session.' >&2
    exit 0
fi
if ! timeout 3s i3-msg -t get_version >/dev/null 2>&1; then
    printf '%s\n' 'No working i3 IPC connection; leaving the current desktop alone.' >&2
    exit 0
fi

config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
polybar_bin=$(readlink -f -- "$(command -v polybar)")
display_key=$(printf '%s' "$DISPLAY" | sha256sum)
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/polybar/display-${display_key:0:16}"
mkdir -p -- "$state_dir"
exec 9>"$state_dir/launch.lock"
flock -w 5 9 || { printf '%s\n' 'Another Polybar launch is still in progress.' >&2; exit 1; }

# Check ownership, executable and kernel start time before signalling a saved PID.
is_our_bar() {
    local pid=$1 started=$2 executable
    [[ $pid =~ ^[0-9]+$ && $started =~ ^[0-9]+$ && -O /proc/$pid ]] || return 1
    executable=$(readlink -- "/proc/$pid/exe" 2>/dev/null) || return 1
    [[ $executable == "$polybar_bin" || $executable == "$polybar_bin (deleted)" ]] || return 1
    [[ $(awk '{print $22}' "/proc/$pid/stat" 2>/dev/null) == "$started" ]]
}

declare -a previous=()
if [[ -r $state_dir/bars.pids ]]; then
    while read -r pid started; do
        if is_our_bar "$pid" "$started"; then
            previous+=("$pid $started")
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done < "$state_dir/bars.pids"
fi
for ((attempt = 0; attempt < 30; attempt++)); do
    running=false
    for entry in "${previous[@]}"; do
        read -r pid started <<< "$entry"
        if is_our_bar "$pid" "$started"; then running=true; break; fi
    done
    [[ $running == true ]] || break
    sleep 0.1
done
if [[ ${running:-false} == true ]]; then
    printf '%s\n' 'A previous Polybar did not stop; refusing to create duplicates.' >&2
    exit 1
fi

monitor_list=$(polybar --list-monitors)
[[ -n $monitor_list ]] || { printf '%s\n' 'No active monitors found.' >&2; exit 1; }
mapfile -t monitors <<< "$monitor_list"
primary=${monitors[0]%%:*}
for entry in "${monitors[@]}"; do
    if [[ $entry == *'(primary)'* ]]; then primary=${entry%%:*}; break; fi
done

: > "$state_dir/bars.pids"
for entry in "${monitors[@]}"; do
    monitor=${entry%%:*}
    modules_right='pulseaudio wlan ethernet battery'
    [[ $monitor != "$primary" ]] || modules_right+=' tray'
    modules_right+=' date lock'
    log_name=${monitor//[^a-zA-Z0-9_.-]/_}
    # Children must not inherit the launch lock or terminal descriptors.
    MONITOR=$monitor POLYBAR_MODULES_RIGHT=$modules_right "$polybar_bin" --config="$config_dir/config.ini" bar1 \
        9>&- </dev/null >"$state_dir/$log_name.log" 2>&1 &
    pid=$!
    started=$(awk '{print $22}' "/proc/$pid/stat" 2>/dev/null) || continue
    printf '%s %s\n' "$pid" "$started" >> "$state_dir/bars.pids"
done
printf 'Polybar logs: %s\n' "$state_dir"
