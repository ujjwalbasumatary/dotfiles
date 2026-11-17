# Neovim for Julia, Python, LaTeX, and C/C++

This is a standalone Neovim configuration, not a LazyVim installation.
The appearance follows the desktop’s Rosé Pine or Gruvbox Muted profile. Snacks supplies file search, the
file browser, Git views, terminals, diagnostic lists, and undo history.
Yazi remains available on demand. Neo-tree and Undotree are disabled, not
uninstalled. Conform handles formatting; the selected desktop profile supplies colours.

Restart Neovim after changing its configuration or installing language tools.
Automatic plugin-update checks are off; inspect and update deliberately with
`:Lazy`. Existing plugin versions are preserved in `lazy-lock.json`.

## Appearance

Kitty uses Cascadia Mono at 18 pt with the selected desktop palette and
0.86 background opacity. Terminal Neovim inherits its font and transparency.
JuliaMono remains available as a fallback for mathematical characters.

Both palettes match the desktop and terminal while the editor, inactive splits,
gutters, file browser, and ordinary floating windows use the terminal background.
Selection, current-line, status-line, and completion-menu highlights remain
visible. Completion menus and ordinary floating windows use square borders.

One status line spans all splits, showing the mode, Git branch, filename,
diagnostic counts, and cursor position. Buffer tabs keep their filenames,
icons, and modified dots without close buttons or duplicate diagnostic counts.
An empty end of a file has no decorative tilde markers.

Diagnostic signs and underlines remain visible, but long messages are not
printed beside the code. Use `Space le` for the current line's explanation or
`Space sd` for the diagnostic list. No diagnostics are disabled or filtered.
The official `rose-pine/neovim` and `ellisonleao/gruvbox.nvim` themes are pinned
in `lazy-lock.json`. Neovim reads `~/.config/desktop-themes/current/name` at
startup and follows profile changes when it regains focus.
`:DesktopThemeReload` reapplies the desktop profile immediately. Restart an
editor already open during installation once to load this integration.

Kanagawa and Catppuccin remain available with `:colorscheme kanagawa-wave` and
`:colorscheme catppuccin-mocha`. Manual colourscheme choices survive refocus
until the desktop profile changes; the status line follows the selected theme.
`DESKTOP_THEME=rose-pine` or `DESKTOP_THEME=gruvbox` can override selection for
an isolated preview without changing the desktop.

## Everyday keys

`Space` is the leader key. The local leader for VimTeX remains `\`.

| Key | Action |
| --- | --- |
| `Space Space` | Find files |
| `Space /` | Search project text |
| `Space e` or `Ctrl-p` | File browser |
| `Space -` | Yazi at the current file |
| `Space ,` | Switch open buffers |
| `Shift-h` / `Shift-l` | Previous / next buffer |
| `Ctrl-h/j/k/l` | Move between windows |
| `Space y` | Copy a motion or visual selection to the system clipboard |
| `Space ay` | Copy the whole document without moving the cursor |
| `Space p` | Paste from the system clipboard |
| `Space w` | Save the changed file |
| `Space su` | Undo history; undo persists across editor restarts |
| `Space sk` | Search all keybindings |
| `Space gg` | Lazygit |
| `Space gs` / `Space gd` | Git status / diff |

Ordinary Vim registers retain their usual behavior. Clipboard shortcuts use
Neovim's detected provider; `wl-copy` and `wl-paste` are installed for this
Wayland desktop. `:checkhealth vim.provider` diagnoses clipboard problems.

## Language features

Completion uses Neovim's built-in LSP support, without another completion
framework. Suggestions appear while typing. `Ctrl-n` / `Ctrl-p` select a
suggestion without using arrow keys. `Tab` accepts the selected suggestion,
or selects and accepts the first one if none is selected. A single suggestion
therefore needs only one `Tab`. `Ctrl-y` also accepts a selected suggestion,
and `Ctrl-e` dismisses the menu. `Ctrl-Space` explicitly requests suggestions.
Without a completion menu or active snippet, `Tab` keeps its normal indentation behavior;
Julia's Unicode entry, such as `\alpha` followed by `Tab`, remains available.

Completion suggestions that contain snippets expand with Neovim's built-in
snippet support. For example, Julia's language server already supplies a
`for` loop with fields for the variable, collection, and body. After accepting
it, use `Tab` for the next field and `Shift-Tab` for the previous field, both
while typing and while a placeholder is selected. If a completion menu is
open, `Tab` accepts its suggestion first. No separate snippet plugin or custom
Julia template is installed.

| Key | Action |
| --- | --- |
| `K` or `Space lh` | Documentation for the symbol |
| `gd` or `Space ld` | Definition |
| `grr` | References |
| `grn` | Rename the symbol |
| `gra` | Code actions |
| `gri` / `grt` | Implementation / type definition |
| `Ctrl-s` in insert mode | Function argument help |
| `[d` / `]d` | Previous / next diagnostic |
| `Space le` | Explain the diagnostic on this line |
| `Space sd` | Search diagnostics |
| `Space ss` | Search document symbols |

Python uses Pyright for types, completion and documentation, and Ruff for
lint and code actions. Julia uses a dedicated language-server environment,
separate from calculation projects. C/C++ uses clangd; LaTeX uses texlab
alongside VimTeX. Inspect attachment and commands with `:checkhealth vim.lsp`.

Language tools installed through Mason are `pyright`, `ruff`, `clangd`,
`clang-format`, and `texlab`. Inspect them with `:Mason`. Installing a tool
does not automatically enable every available language server.

The Julia server is LanguageServer 6.0.1, installed in
`~/.julia/environments/nvim-lspconfig` for the installed Julia 1.13. It does
not install dependencies into calculation projects automatically. To change
the project used for Julia assistance explicitly, use
`:LspJuliaActivateEnv /path/to/project` in a Julia buffer.

## Formatting

Saving Python, Julia, C or C++ code formats it. Python uses Ruff, C/C++ uses
clang-format, and Julia uses its running language server. Project formatter
configuration is respected; clang-format uses its default style when no
`.clang-format` is present. Formatting does not apply all lint fixes or rewrite
LaTeX prose. Files above 20,000 lines are excluded from automatic formatting.

- `Space cf`: format explicitly (also works on a visual selection).
- `Space uf`: toggle format-on-save for the current buffer.
- `:ConformInfo`: inspect the chosen formatter and its log.

Automatic formatting has a bounded wait, so a slow or starting language
server does not hold up saving indefinitely: up to 1.2 seconds for Python/C/C++
and 10 seconds for Julia, whose first formatting request can need several
seconds to compile. Later requests are normally much faster. If a first Julia
save occurs before its server is ready, use `Space cf` after initialization.

Julia's language server uses a conservative `minimal` style by default: it
fixes indentation but preserves some existing choices, such as operator
spacing. Its configuration file is `JuliaFormat.toml`, not
`.JuliaFormatter.toml`. To choose fuller formatting for a project, add a
`JuliaFormat.toml` there containing:

```toml
style = "default"
```

## LaTeX

Opening a document alone does not start compilation. Saving a `.tex` file
starts VimTeX's continuous `latexmk` process if it is not already running.
Later changes to that document's included files cause rebuilding through the
same process. Texlab does not start a second compiler.

- `Space lv` or `\lv`: view the PDF at the current source line in Zathura.
- `Space lb`: explicitly start compilation.
- `Space lq` or `\le`: show compilation errors.
- `Space lt`: table of contents.
- `Space uv`: toggle automatic LaTeX rebuilding; disabling stops VimTeX's
  active compilers, re-enabling starts them on the next save.
- `:VimtexInfo`: inspect the detected root, compiler and PDF viewer.

VimTeX handles SyncTeX PDF/source navigation. Inverse search from a PDF needs
the viewer to be launched through VimTeX. The PDF viewer is not automatically
opened on every save. Existing `% !TEX program` and `% !TEX root` directives
and project `.latexmkrc` settings remain in effect. No shell-escape option is
added by this configuration.

## Run, REPL, and build

- `Space rr` / `:RunFile`: save and run the current Python/Julia file in a
  fresh terminal process. If a process for the project is still running,
  focus it rather than starting a duplicate.
- `Space ri` / `:OpenREPL`: reuse a persistent Python/Julia REPL for the project.
- `Space rb` / `:Build [make targets/options]`: run an existing Makefile
  asynchronously and collect compiler output in quickfix. This saves the
  current file only; save other changed source files before building.
- `:BuildStop`: interrupt a build; `:copen` shows its output.
- `[q` / `]q`: move through compiler errors.
- `Esc Esc`: leave terminal input mode without terminating its process.

Python prefers the active `VIRTUAL_ENV`, then the project's `.venv`, then
system Python. Julia uses the nearest `Project.toml`. Opening a source file
does not execute it. `:RunFile` and `:Build` are explicit requests to save and
execute code; review unfamiliar projects first. A CMake project needs an
already configured `build/Makefile`, or use its normal build commands in a
terminal. This configuration does not generate build files or guess compiler
flags. For accurate C/C++ project diagnostics, supply `compile_commands.json`
or `compile_flags.txt` through the project's normal build setup.

## Backup made before this change

`/home/ujjwal/.config/nvim-backup.HSTTkja6/`

`config/` contains the full previous Neovim directory, including Git metadata,
the changed lockfile, and the previously untracked Yazi configuration.
`julia-language-server/` contains the previous editor-only Julia environment.
To roll back, close Neovim and preserve the current directory before restoring
the complete backed-up directory. Do not merely merge the old Lua files into
the new directory: that would leave newly added plugin definitions active.
