#!/usr/bin/env python3
"""Switch colour profiles without replacing application or window-manager settings."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time
from datetime import datetime

USER_HOME = Path.home()
BASE = USER_HOME / ".config/desktop-themes"
STATE = USER_HOME / ".local/state/desktop-theme"


def atomic_text(path, text):
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(prefix="." + path.name, dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def select_link(base, choice):
    # Rename one relative link so all include readers see a complete profile.
    with tempfile.TemporaryDirectory(prefix=".select-", dir=base) as temporary:
        link = Path(temporary) / "current"
        link.symlink_to("profiles/" + choice)
        os.replace(link, base / "current")


def current(base=BASE):
    return (base / "current/name").read_text().strip()


def validate(base, choice):
    registry = json.loads((base / "themes.json").read_text())
    if choice not in registry:
        raise ValueError("Unknown theme: " + choice)
    directory = base / "profiles" / choice
    required = ["name", "palette.json", "kitty.conf", "waybar.css", "hyprland.lua",
                "hyprlock-colors.conf", "rofi-colors.rasi", "mako.json", "yazi.toml",
                "gtk/index.theme", "gtk/gtk-3.0/gtk.css", "gtk/gtk-4.0/gtk.css",
                "icons/lucide/clock.svg", "icons/lucide/weather/cloud-off.png"]
    for name in required:
        if not (directory / name).is_file():
            raise ValueError(f"Incomplete {choice} profile: missing {name}")
    if (directory / "name").read_text().strip() != choice:
        raise ValueError("Profile identifier mismatch")
    palette = json.loads((directory / "palette.json").read_text())
    if not all(re.fullmatch(r"[0-9a-fA-F]{6}", value) for value in palette.values()):
        raise ValueError("Invalid palette colour")
    json.loads((directory / "mako.json").read_text())
    return registry[choice]


def starship_text(text, palette):
    pattern = r"(?m)^palette[ \t]*=[ \t]*['\"][^'\"]+['\"][ \t]*$"
    if len(re.findall(pattern, text)) != 1 or f"[palettes.{palette}]" not in text:
        raise ValueError("Starship palette selector changed; no files modified")
    return re.sub(pattern, "palette = '" + palette + "'", text)


def mako_text(text, colours):
    section = ""
    seen = set()
    lines = text.splitlines(keepends=True)
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped
        elif "=" in line and not stripped.startswith("#"):
            key = line.split("=", 1)[0].strip()
            if key in colours.get(section, {}):
                lines[i] = key + "=" + colours[section][key] + "\n"
                seen.add((section, key))
    expected = {(section, key) for section, items in colours.items() for key in items}
    if seen != expected:
        raise ValueError("Mako colour fields changed; no files modified")
    return "".join(lines)


def kitty_text(text):
    pattern = r"(?ms)^# BEGIN_KITTY_THEME\n.*?^# END_KITTY_THEME[^\n]*"
    if len(re.findall(pattern, text)) != 1:
        raise ValueError("Kitty theme markers changed; no files modified")
    block = ("# BEGIN_KITTY_THEME\n"
             "# Palette only; font, opacity and keyboard settings stay shared.\n"
             "include ../desktop-themes/current/kitty.conf\n# END_KITTY_THEME")
    return re.sub(pattern, lambda _: block, text)


def apply_profile(base, starship, mako, state, choice, kitty=None):
    info = validate(base, choice)
    old_choice = current(base)
    old_starship, old_mako = starship.read_text(), mako.read_text()
    new_starship = starship_text(old_starship, info["starship"])
    colours = json.loads((base / "profiles" / choice / "mako.json").read_text())
    new_mako = mako_text(old_mako, colours)
    before = {starship: old_starship, mako: old_mako}
    after = {starship: new_starship, mako: new_mako}
    if kitty is not None:
        before[kitty] = kitty.read_text()
        after[kitty] = kitty_text(before[kitty])
    if old_choice == choice and before == after:
        return info
    backup = state / "backups" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup.mkdir(parents=True, mode=0o700)
    (backup / "theme").write_text(old_choice + "\n")
    for path, text in before.items():
        (backup / path.name).write_text(text)
    try:
        for path, text in after.items():
            if text != before[path]:
                atomic_text(path, text)
        select_link(base, choice)
    except BaseException:
        for path, text in before.items():
            atomic_text(path, text)
        select_link(base, old_choice)
        raise
    return info


def owned_processes(name):
    for directory in Path("/proc").iterdir():
        if not directory.name.isdecimal():
            continue
        try:
            if directory.stat().st_uid != os.getuid() or (directory / "comm").read_text().strip() != name:
                continue
            env = dict(item.split("=", 1) for item in (directory / "environ").read_bytes().decode().split("\0") if "=" in item)
            if env.get("HYPRLAND_INSTANCE_SIGNATURE") and env.get("HYPRLAND_PREVIEW") != "1":
                yield int(directory.name), env
        except (OSError, ValueError):
            continue


def run(args, env, timeout=8):
    result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Command failed: " + args[0])
    return result.stdout


def session_env():
    # Prefer the invoking session, then the actual compositor environment.
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    candidates = [env for _, env in owned_processes("waybar")]
    candidates += [env for _, env in owned_processes("kitty")]
    for env in candidates:
        if not signature or env["HYPRLAND_INSTANCE_SIGNATURE"] == signature:
            return env
    # The shell launching this command may have inherited a stale desktop env.
    return candidates[0] if candidates else None


def refresh():
    warnings = []
    weather = USER_HOME / ".config/hypr/scripts/weather"
    try:
        run([str(weather), "--icon", "--cached"], os.environ.copy())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        warnings.append("Weather icon: " + str(error))
    env = session_env()
    if env is None:
        return warnings + ["No running Hyprland session found; the theme is saved for the next session."]
    signature = env["HYPRLAND_INSTANCE_SIGNATURE"]
    for args in (["hyprctl", "reload", "config-only"], ["makoctl", "reload"]):
        try:
            run(args, env)
        except (OSError, RuntimeError, subprocess.SubprocessError) as error:
            warnings.append(str(error))
    for pid, kitty_env in owned_processes("kitty"):
        if kitty_env["HYPRLAND_INSTANCE_SIGNATURE"] != signature:
            continue
        try:
            run(["kitty", "@", "--to", f"unix:@kitty-{pid}", "load-config"], kitty_env)
        except (OSError, RuntimeError, subprocess.SubprocessError) as error:
            warnings.append(f"Kitty {pid}: {error}")
    try:
        bars = [pid for pid, e in owned_processes("waybar") if e["HYPRLAND_INSTANCE_SIGNATURE"] == signature]
        for pid in bars:
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        deadline = time.monotonic() + 3
        while any(Path(f"/proc/{pid}").exists() for pid in bars) and time.monotonic() < deadline:
            time.sleep(0.1)
        if any(Path(f"/proc/{pid}").exists() for pid in bars):
            raise RuntimeError("Waybar did not stop; run desktop-theme again to retry")
        log = USER_HOME / ".local/state/waybar/live.log"
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text("")
        # Constant shell command; no theme name or external text is interpolated.
        run(["hyprctl", "dispatch", 'hl.dsp.exec_cmd("waybar > /home/ujjwal/.local/state/waybar/live.log 2>&1")'], env)
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline and "Bar configured" not in log.read_text():
            time.sleep(0.1)
        output = log.read_text()
        # Third-party tray providers can log errors independently of bar startup.
        if "Bar configured" not in output:
            raise RuntimeError("Check ~/.local/state/waybar/live.log: Waybar did not reload cleanly")
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        warnings.append(str(error))
    return warnings


def choose_theme(registry):
    env = session_env() or os.environ.copy()
    choices = list(registry)
    result = subprocess.run(["rofi", "-no-config", "-dmenu", "-no-custom", "-format", "i",
                             "-theme", str(USER_HOME / ".config/hypr/theme-picker.rasi")],
                            input="\n".join(registry[name]["label"] for name in choices) + "\n",
                            env=env, text=True, capture_output=True)
    if result.returncode == 1:  # Escape / click outside.
        return None
    if result.returncode or not result.stdout.strip().isdecimal():
        raise RuntimeError(result.stderr.strip() or "Theme picker failed")
    return choices[int(result.stdout.strip())]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("theme", nargs="?", default="menu", help="rose-pine, gruvbox, menu, list, or current")
    parser.add_argument("--check", action="store_true", help="validate the selected profile(s), without changes")
    parser.add_argument("--no-reload", action="store_true", help="save the selection without contacting running applications")
    args = parser.parse_args()
    registry = json.loads((BASE / "themes.json").read_text())
    if args.check:
        for choice in registry if args.theme in ("menu", "list") else [args.theme]:
            validate(BASE, choice)
            print("Validated " + choice)
        return
    if args.theme == "list":
        for choice, info in registry.items():
            print(f'{choice:12} {info["label"]}')
        return
    if args.theme == "current":
        print(current())
        return
    choice = choose_theme(registry) if args.theme == "menu" else args.theme
    if choice is None:
        return
    if choice not in registry:
        # Preserve historical Plasma choices on this machine; never invoke these
        # when selecting either of the new Hyprland profiles.
        legacy = USER_HOME / ".local/bin/desktop-theme-plasma"
        manifest = USER_HOME / ".local/share/desktop-themes/themes.json"
        old_choices = json.loads(manifest.read_text()) if manifest.is_file() else {}
        if legacy.is_file() and (choice in old_choices or choice == "restore"):
            os.execv(str(legacy), [str(legacy), choice])
        raise ValueError("Unknown theme; use desktop-theme list")
    STATE.mkdir(parents=True, mode=0o700, exist_ok=True)
    with (STATE / "switch.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        info = apply_profile(BASE, USER_HOME / ".config/starship.toml", USER_HOME / ".config/hypr/mako.conf",
                             STATE, choice, USER_HOME / ".config/kitty/kitty.conf")
        warnings = [] if args.no_reload else refresh()
    print("Selected " + info["label"])
    for warning in warnings:
        print("Note: " + warning, file=sys.stderr)
    print("Neovim follows on focus; reopen Yazi and GTK/Qt apps to refresh their themes.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, IndexError, subprocess.SubprocessError) as error:
        print("Theme change stopped: " + str(error), file=sys.stderr)
        sys.exit(1)
