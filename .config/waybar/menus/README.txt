Native Waybar GTK menus

Implemented against the locally installed Waybar 0.16 menu API, documented in:
  man 5 waybar-menu
  /usr/share/man/man5/waybar-menu.5.gz

Each XML file contains GtkMenu id="menu" and a disabled title.
The config uses menu="on-click" plus menu-file and menu-actions, without an
on-click command. Right-click audio mute and existing scroll handlers are
preserved. Commands run only when the corresponding menu item is activated.
GTK styling is scoped to GtkMenu widgets named waybar-controls-menu.

The staged config uses final ~/.config/waybar/menus paths. Testing before
installation should rewrite menu-file paths in a temporary config copy.
