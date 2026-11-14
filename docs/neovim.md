# Neovim theme

The shared [Neovim module](https://github.com/maxnaro/nvim-config) follows the
shared `dotfiles-theme` palette, with Chocolatier dark by default and Kimbie
Light available through `dotfiles-theme light`. Its palette source is
`~/.config/dotfiles/theme/palette.json` (under `$XDG_CONFIG_HOME` when set),
and the current mode lives in `${XDG_STATE_HOME:-~/.local/state}/dotfiles/theme`.
The theme module is linked automatically with the Neovim profile.

Open editors watch the theme state and refresh when it changes; focusing the
editor also checks for updates. The configuration falls back to its bundled
palette if shared files are absent. It does not depend on Noctalia's generated
Kitty palette or its former polling integration. See the module README for
plugin setup and tests.
