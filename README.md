# CachyOS dotfiles

Personal CachyOS terminal and development configuration sharing shell, theme,
tmux, and Neovim modules with [WSL dotfiles](https://github.com/maxnaro/wsl-dotfiles).
See [module ownership and updates](docs/modules.md) for their sources and pins.

## Setup

Clone with submodules, or initialize them in an existing checkout:

```bash
git submodule update --init --recursive
./setup.sh --dry-run
./setup.sh --install-packages
```

`--install-packages` runs `sudo pacman -Syu --needed` using
`packages/pacman.txt`; package installation covers the full list regardless of
profile selection. Without installation flags, setup links configuration offline.
The default profiles are `bash,fish,zsh,nvim,tmux`; choose a subset with, for
example, `./setup.sh --only zsh,nvim,tmux`. The theme is linked automatically
with shell, tmux, or Neovim profiles. Desktop and Git are opt-in; Git retains the
WSL identity, so review it before use.

Interactive Bash hands off to Fish when available. Bash and Fish attach to or
start tmux on a terminal. Set `DOTFILES_NO_FISH=1` to stay in Bash, or
`DOTFILES_NO_TMUX=1` to suppress automatic tmux. Setup does not change the login
shell. Zsh retains CachyOS configuration when installed and adds shared helpers.
Local additions belong in `~/.bashrc.local`, `~/.zshrc.local`, or
`~/.config/fish/local.fish`.

Neovim downloads its pinned plugins on first launch. Live Share requires a
separately configured Tailscale installation. Keep the checkout in place because
installed configurations link back to it.

## Theme and desktop

`dotfiles-theme dark`, `light`, `toggle`, `apply`, and `status` select and inspect
the shared palette; dark is the default. Generated files live under
`${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/theme`. Theme-enabled profiles link Kitty and Alacritty configuration, including the
managed colours, 75% opacity, and JetBrainsMono RunCat v7 at 11pt. Install
the RunCat font with the optional tmux plugin setup below. See the
[Neovim theme guide](docs/neovim.md) and [desktop guide](docs/desktop.md) for
live updates and the opt-in Noctalia dock.

## tmux plugins

The configuration starts without initialized or built plugins. To initialize
all four pinned plugins, build RunCat and prefix help, and build/install the
RunCat font, use:

```bash
./setup.sh --only tmux --with-tmux-plugins --dry-run
./setup.sh --only tmux --with-tmux-plugins
```

This needs Git, Cargo with a Rust toolchain, and Python 3.11 or newer. Select
`JetBrainsMono RunCat v7` in the terminal if necessary. `--with-prefix-help`
remains available for initializing and building only prefix help. Press Ctrl+b
or Ctrl+a and pause for 500 ms for the help popup; Esc dismisses it and `?`
opens the complete binding list. The workspace popup additionally uses `sesh`,
`fzf`, and `zoxide`.

## Backups and personal configuration

Existing files, directories, and broken symlinks move to unique sibling backups
such as `.bashrc.bak.20261017-150000`. Repeat installs skip correct links. The
installer refuses to write through a symlinked parent into another checkout;
move the parent link aside before migrating. Fish history, universal variables,
and unrelated functions remain in place. To restore a file, remove its installed
link and move the printed backup back to its original name.

`./setup.sh --only desktop` backs up and links the Noctalia preset and Hyprland
hook and Coniston wallpaper, and backs up and migrates saved Noctalia appearance
state; it does not edit `hyprland.lua`. Follow the [desktop guide](docs/desktop.md)
to load the hook. `./setup.sh --with-pokemon` optionally installs the upstream
greeter. Existing pyenv, Go, Rust and NVM installations are supported; setup does
not install language version managers. Project Python environments activate and
deactivate when entering and leaving their directories, while manually activated
environments are preserved.

## Validation

```bash
python3 -m unittest discover -s tests -v
python3 -m unittest discover -s modules/shell/tests -v
python3 -m unittest discover -s modules/theme/tests -v
python3 -m unittest discover -s tmux/.config/tmux/tests -v
python3 modules/theme/scripts/render.py --check
```

Tests use temporary homes and private tmux sockets; they do not install packages
or alter the live home. Some integration checks require their corresponding
programs. See each module's README for additional tests.
