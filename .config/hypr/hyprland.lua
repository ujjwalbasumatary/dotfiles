-- Shared Hyprland configuration for 0.57.2; colour profiles are selected separately.
-- Reference: https://github.com/hyprwm/Hyprland/blob/v0.57.2/example/hyprland.lua
-- Deployed from the saved bundle in ~/.local/share/hyprland-prepared/.
local desktop_theme = dofile("/home/ujjwal/.config/desktop-themes/current/hyprland.lua")
local rofi_theme = "/home/ujjwal/.config/hypr/rofi.rasi"
-- While the launcher has focus, Rofi handles the same keys as cancel actions.
local launcher = "rofi -no-config -show drun -show-icons -icon-theme Papirus-Dark -global-kb "
    .. "-kb-cancel Escape,Control+g,Control+bracketleft,MouseSecondary,Control+d,Super+d "
    .. "-kb-remove-char-forward Delete -theme " .. rofi_theme

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.env("GTK_THEME", "Desktop-Square")
-- Qt uses the same GTK palette and dialogs only within this session.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("XCURSOR_THEME", "Catppuccin-Macchiato-Rosewater-Cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { desktop_theme.active_border }, angle = 0 },
            inactive_border = desktop_theme.inactive_border,
        },
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 14, render_power = 3, color = desktop_theme.shadow },
        blur = { enabled = true, size = 3, passes = 2 },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    input = { kb_layout = "us", follow_mouse = 1, touchpad = { natural_scroll = true } },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true, background_color = desktop_theme.background },
})

-- Short, restrained transitions; application opacity comes from Kitty itself.
hl.curve("gentle", { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "gentle", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "gentle" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "gentle", style = "slide" })

-- Real sessions start their own services once. Isolated previews opt out so
-- they cannot claim the current desktop's notification bus or lock its session.
-- No portal overrides or globally enabled user services are written here.
if os.getenv("HYPRLAND_PREVIEW") ~= "1" then
    hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
        hl.exec_cmd("hyprpaper")
        hl.exec_cmd("mako --config /home/ujjwal/.config/hypr/mako.conf")
        hl.exec_cmd("hypridle")
        hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    end)
end

hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + D", hl.dsp.exec_cmd(launcher))
hl.bind("CTRL + D", hl.dsp.exec_cmd(launcher))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind("SUPER + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + E", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(
    [[printf 'Cancel\nLog out\n' | rofi -no-config -dmenu -no-custom -theme /home/ujjwal/.config/hypr/logout.rasi | grep -qx 'Log out' && hyprctl dispatch 'hl.dsp.exit()']]
))

for key, direction in pairs({ H = "left", J = "down", K = "up", L = "right",
                              Left = "left", Down = "down", Up = "up", Right = "right" }) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end
for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = false }))
end

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("/home/ujjwal/.config/hypr/scripts/desktop-control volume up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("/home/ujjwal/.config/hypr/scripts/desktop-control volume down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("/home/ujjwal/.config/hypr/scripts/desktop-control volume toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("/home/ujjwal/.config/hypr/scripts/desktop-control mic toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("/home/ujjwal/.config/hypr/scripts/desktop-control brightness up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("/home/ujjwal/.config/hypr/scripts/desktop-control brightness down"), { locked = true, repeating = true })
hl.bind("Print", hl.dsp.exec_cmd([[mkdir -p "$HOME/screenshots" && grim "$HOME/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"]]))
hl.bind("ALT + SHIFT + C", hl.dsp.exec_cmd([[region=$(slurp) && grim -g "$region" - | wl-copy]]))

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

-- Detailed bar settings are explicit menu actions, kept out of the tile layout.
hl.window_rule({
    name = "bar-audio-network-settings",
    match = { class = "(?i)^(org[.]pulseaudio[.]pavucontrol|pavucontrol|nm-connection-editor)$" },
    float = true,
    size = { 760, 520 },
    move = { "monitor_w-window_w-20", 56 },
})
hl.window_rule({
    name = "bar-network-bluetooth-terminal",
    match = { class = "^waybar-(network|bluetooth)$" },
    float = true,
    size = { 840, 540 },
    move = { "monitor_w-window_w-20", 56 },
})

-- Docking is scoped to this Hyprland session. Logind keeps its normal laptop
-- suspend behaviour when no external monitor is connected.
if os.getenv("HYPRLAND_PREVIEW") ~= "1" then
    local display_layout = "/home/ujjwal/.config/hypr/scripts/display-layout"
    local function refresh_displays() hl.exec_cmd(display_layout) end
    hl.on("hyprland.start", refresh_displays)
    hl.on("config.reloaded", refresh_displays)
    hl.on("monitor.added", function(_) refresh_displays() end)
    hl.on("monitor.removed", function(_) refresh_displays() end)
    hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(display_layout .. " --lid closed"),
        { locked = true, ignore_mods = true, submap_universal = true })
    hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(display_layout .. " --lid open"),
        { locked = true, ignore_mods = true, submap_universal = true })
end
