# Ujjwal's dotfiles

Personal Arch Linux desktop configuration: Hyprland with a continuous Waybar,
square edges, switchable Rosé Pine / Gruvbox Muted colours, and transparent
terminal applications.
The existing i3/Polybar configuration remains available alongside Plasma Wayland.

## Included

- **Hyprland:** Lua configuration for 0.57.2, wallpaper, idle lock, square
  launcher/notifications, volume and brightness feedback, and lid-aware displays.
- **Waybar:** clock, weather, workspaces and Lucide SVG system controls. Icons
  use fixed 22 px slots and an 8 px text gap, independent of font fallback.
  Upstream attribution and license are included under `.config/waybar/icons/lucide/`.
  Weather shows a condition icon and temperature, with details in its tooltip.
  Icons follow the reported condition and use day/night variants; the
  lockscreen uses matching transparent PNGs from the same SVG artwork.
- **Kitty / Starship:** Cascadia Mono, 86% background opacity, compact prompt,
  4 pt top padding and 10 pt side/bottom padding. Codex’s input and submitted-message backgrounds use
  88% opacity through Kitty’s
  exact-colour transparency setting. Both profiles cover the computed Codex
  background colours from either palette when switching existing terminals.
- **Neovim:** both palettes, transparent editor, square popups and pinned plugins.
  See [.config/nvim/README.md](.config/nvim/README.md) for coding workflows.
- **Yazi:** matching icons and syntax previews for both palettes, transparent panels, and a
  foreground-only selection in the left pane.
- **GTK / Qt:** a local square GTK theme; Qt follows GTK only in Hyprland.
- **Firefox:** preference-only settings for 125% scaling; no browser profile.
- **i3 / Polybar:** the existing X11 alternative, including its compositor scripts.

## Switch appearance

Search **Desktop Theme** in Rofi, or run:

```sh
desktop-theme             # Open the two-choice picker
desktop-theme gruvbox     # Gruvbox Muted
desktop-theme rose-pine   # Rosé Pine
desktop-theme current    # Show the selected profile
desktop-theme --check    # Validate both profiles without changing anything
```

The active profile is a relative symlink at `.config/desktop-themes/current`.
Fonts, shortcuts, application choices, window/bar geometry, display handling,
and the wallpaper remain shared. Theme assets live in separate profile folders;
Kitty, Hyprland, Rofi, Hyprlock, Waybar and Yazi read their selected colours there.
Starship's palette selector and Mako's colour fields are updated without replacing
their other settings. Each switch validates the profile, saves the previous small
configuration files under `.local/state/desktop-theme/backups`, and rolls back
file changes if applying the selection fails.

Switching reloads Hyprland, Kitty and Mako, restarts Waybar, and refreshes the
cached weather icon. Starship updates at the next prompt. Neovim follows a changed
profile on refocus or `:DesktopThemeReload`; sessions started before installing
this integration need one restart. Reopen Yazi and GTK/Qt applications to load the
new theme. After the initial installation, launching GTK/Qt apps from Rofi picks
up the new `Desktop-Square` theme environment; older shells may retain their old
GTK environment until reopened. Self-styled applications may ignore GTK themes.
The lockscreen updates next time it is opened.

The old local Plasma theme manager is preserved as `desktop-theme-plasma` where
it was already installed. Historical Plasma theme names still delegate to it;
`rose-pine` and `gruvbox` never change Plasma settings. That legacy manager and
its local theme collection are not prerequisites for this repository.

## Restore carefully

This repository mirrors selected paths under `$HOME`. It is a personal snapshot,
not a distribution installer. Clone it to a separate directory, compare changes,
and back up each destination before copying the files you want. Do not force a
Git checkout over your home directory or copy every hidden file wholesale.

```sh
git clone git@github.com:ujjwalbasumatary/dotfiles.git ~/dotfiles-github
```

The colour profiles are a dependency of the themed applications. Restore
`.config/desktop-themes` before restoring any application configuration, and use
`cp -a` to preserve the relative symlinks. For example, to restore Kitty and its
profile dependency after reviewing the files:

```sh
mkdir -p ~/.local/state/dotfiles-backups
cp -a ~/.config/kitty ~/.local/state/dotfiles-backups/kitty-$(date +%Y%m%d-%H%M%S)
cp -a ~/dotfiles-github/.config/desktop-themes ~/.config/
cp -a ~/dotfiles-github/.config/kitty/. ~/.config/kitty/
```

Use the same selected-directory approach for Hyprland, Waybar, Neovim and Yazi.
Copy `.local/bin/desktop-theme`, `.local/share/applications/desktop-theme.desktop`,
and the `.local/share/themes/Desktop-Square` symlink to their matching home paths.
The standalone `RosePine-Square` directory remains available as a legacy theme.
Restore `.config/starship.toml` and `.config/hypr/mako.conf` for the theme switcher;
its preflight checks stop if expected palette fields have been removed.
The Firefox `user.js` lives under `.config/firefox` here as a portable template:
merge its two preferences into the active Firefox profile's `user.js`, found
through `about:profiles`. Restart Firefox normally to apply them.

### Machine-specific settings

Paths currently target `/home/ujjwal`. Review them before using another account.
The laptop is `eDP-1` (1920×1080 at 144 Hz); the external display is `HDMI-A-1`
(2560×1600 at 60 Hz). Both use scale 1. The external monitor extends above the
centered laptop panel with the lid open. Closing the lid while an external
display is active disables the laptop panel; reopening or disconnecting the
external display restores it. Normal logind suspend behaviour is retained.

Other hardware identifiers: backlight `amdgpu_bl1`, battery `BAT1`, adapter `ACAD`.
Plasma's global settings are not managed here. Existing applications need to be
reopened to inherit Hyprland's GTK/Qt theme and cursor environment.

Wallpapers are not redistributed. Supply `~/Pictures/evening-sky.png` for
Hyprland and its lock screen; review the additional image paths in i3/Polybar.
Fonts/cursor assets are also external dependencies: CaskaydiaMono Nerd Font Mono,
JuliaMono fallback, Papirus-Dark icons and Catppuccin-Macchiato-Rosewater-Cursors.

### Weather

After restoring the weather configuration, run
`~/.config/hypr/scripts/weather --icon` once before locking to prime the cached
lockscreen icon. Waybar and the weather label maintain it afterward.

Waybar and Hyprlock share a keyless [Open-Meteo](https://open-meteo.com/) helper.
Configure your city locally; the location file and cache are excluded from Git.
Copy `.config/weather/location.example.json` to `~/.config/weather/location.json`
and fill in the coordinates/time zone using Open-Meteo's geocoding API.

```sh
~/.config/hypr/scripts/weather --refresh
~/.config/hypr/scripts/weather --plain
```

Weather is cached for 15 minutes. During network failures, a reading up to six
hours old is marked as cached; older data is shown as unavailable. Hyprlock shows
the clock, date and weather above the password field. It never needs an API key.
The legacy Polybar provider optionally reads `OPENWEATHERMAP_API_KEY` and
`WEATHER_CITY` from its environment; no key is included in this repository.

## Shortcuts and dependencies

`Super+Return`: terminal; `Super+D` or `Ctrl+D`: toggle launcher; `Ctrl+Alt+L`: lock;
`Super+Shift+E`: logout prompt; `Super+1..0`: workspace;
`Super+Shift+C`: reload. The global `Ctrl+D` launcher binding replaces the terminal
EOF shortcut; remove that binding if you prefer shell EOF. Waybar's `idle` toggle
changes to `awake` to pause
automatic locking/display sleep. Media keys and bar scrolling show a short OSD.

Core tools: Hyprland, Waybar, hyprpaper, hypridle, hyprlock, mako, Kitty, Rofi,
Python 3, PipeWire/WirePlumber (`wpctl`), brightnessctl, libnotify (`notify-send`),
NetworkManager, bluez-utils, playerctl, grim, slurp, wl-clipboard and the GTK/Qt
platform integration packages. The X11 alternative also needs i3, Polybar,
picom, feh, xss-lock, i3lock, maim and xclip. Shell configuration assumes Zsh,
Oh My Zsh, Starship and zsh-syntax-highlighting; review optional local tool paths.

Theme attribution and licences live beside the relevant files. Waybar's layout
is inspired by [m-vikanshu/nix-config](https://github.com/m-vikanshu/nix-config),
following an earlier [HANCORE V2.1](https://github.com/HANCORE-linux/waybar-themes)
adaptation. The muted Gruvbox colour direction is inspired by
[suresh-meena/desktop-dotfiles](https://github.com/suresh-meena/desktop-dotfiles);
its installer, keybindings, services and machine settings are not imported.
Theme profiles retain source metadata and upstream licences.
