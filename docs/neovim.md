# Neovim theme

Neovim follows Noctalia's current generated terminal palette instead of using a
fixed Chocolatier theme. This includes the editor background, syntax colors,
floating windows, completion menus, diagnostics, diffs, and terminal ANSI colors.
Both light and dark palettes are supported; the editor background is opaque so
it matches the shell palette rather than the wallpaper behind the terminal.

## Palette source

Enable **Kitty** in Noctalia's theme templates. The desktop preset in this repo
already includes it. Kitty itself does not need to be installed or running:
Neovim reads the generated file directly:

```text
$XDG_CONFIG_HOME/kitty/themes/noctalia.conf
```

If `XDG_CONFIG_HOME` is unset, this is
`~/.config/kitty/themes/noctalia.conf`. Noctalia owns that file; don't edit it
manually. To generate it immediately after enabling the template, run:

```sh
noctalia msg templates-apply
```

Open Neovim instances check for palette changes every two seconds, including
wallpaper changes and light/dark switches. No restart or plugin download is
needed for this theme. Missing or invalid palettes use Neovim's bundled Habamax
at startup; incomplete updates preserve the last applied palette. When Noctalia
creates a valid palette later, Neovim picks it up automatically.

Selecting another theme with `:colorscheme ...` pauses synchronization. Use
`:colorscheme noctalia` to resume it.

## Test

Run the offline test without loading LazyVim or downloading plugins:

```sh
nvim --headless -u NONE -l tests/test_nvim_theme.lua
```
