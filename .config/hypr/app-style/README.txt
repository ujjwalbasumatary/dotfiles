Hyprland application styling

Named GTK theme: ~/.local/share/themes/RosePine-Square
Select only in the Hyprland session with GTK_THEME=RosePine-Square.
This leaves global GTK settings and Plasma preferences untouched.
The GTK3 theme imports installed Adwaita widgets and changes palette/corners.
GTK4 imports installed dark widgets plus the official Rosé Pine GTK4 palette.
Self-styled/libadwaita apps may retain parts of their own appearance.

Cursor: Catppuccin-Macchiato-Rosewater-Cursors, installed locally, size24.
Set XCURSOR_THEME; the cursor assets are Xcursor rather than Hyprcursor.

Qt: QT_QPA_PLATFORMTHEME=gtk3 is enabled only in Hyprland. The installed
Qt plugin was tested in an isolated Wayland session and inherited Rosé Pine
window/text/selection colours (#1f1d2e/#e0def4/#403d52). It also supplies GTK
file dialogs to applications that support native dialogs. Plasma keeps its
own platform theme.

Browsers: no profiles modified. Firefox/Chromium system-theme mode may inherit
GTK colours; custom browser themes override this. Existing processes need to
restart normally to inherit session variables. No browser was closed.

Rollback: remove the GTK_THEME/QT_QPA_PLATFORMTHEME/XCURSOR_THEME additions from hyprland.lua.
These new theme files do not alter any global theme by themselves.
