# CachyOS dotfiles

Personal CachyOS terminal and development configuration, ported from
[maxnaro/wsl-dotfiles](https://github.com/maxnaro/wsl-dotfiles).

Includes the same Fish prompt, eza shortcuts, bat man pages, FZF search and
previews, zoxide navigation, automatic Python environments, LazyVim, and tmux
styling/navigation. Zsh retains the installed CachyOS configuration and adds the
shared terminal helpers. Bash remains usable directly; it does not launch Fish.
No Windows paths, Debian bootstrap, or downloaded replacements for native CLI
packages are included.

## Setup

From this checkout:

```bash
cd ~/dotfiles
./setup.sh --dry-run
./setup.sh --install-packages
```

`--install-packages` performs a full package upgrade with
`sudo pacman -Syu --needed`, using `packages/pacman.txt`. Pacman asks for
confirmation as usual. Without installation flags, setup only links configuration
and works offline. Package installation applies to the full tool list even when
selecting fewer profiles.

Default profiles are `bash,fish,zsh,nvim,tmux`. To install a subset:

```bash
./setup.sh --only zsh,nvim,tmux --dry-run
./setup.sh --only zsh,nvim,tmux
```

Open a new terminal after installation. The installer does not change your
login shell; run `fish`, `zsh`, or `bash` to try one. The Zsh profile sources
`/usr/share/cachyos-zsh-config/cachyos-config.zsh` when installed, with a basic
fallback on other Arch installations. Neovim downloads its pinned plugins on
first launch and needs network access. The inherited Live Share plugin uses
Tailscale; install and configure Tailscale separately if you use those commands.

The config layout uses the standard `$HOME/.config` location. Keep the checkout
at its installed location, since configurations link back to it.

## Files and backups

| Profile | Configuration |
| --- | --- |
| Bash | `.bashrc`, `.bash_profile`, `.inputrc`, `.blerc` |
| Fish | `config.fish`, prompt and `conf.d` helpers, linked individually |
| Zsh | `.zshrc`, keeping CachyOS completion, theme and suggestions |
| Neovim | `.config/nvim`, including the existing plugin lockfile |
| tmux | `.config/tmux`, Alt navigation and OSC 52 clipboard |
| Git (opt-in) | `.gitconfig`, retaining the identity from the WSL repo |

Bash and Zsh also link `.bash_aliases`, `.config/dotfiles/terminal.sh`, and
`.scripts/auto_venv.sh`. `.blerc` is retained for an optional existing ble.sh
installation; setup does not install or enable ble.sh.

Existing files, directories, and broken symlinks move to unique sibling backups
such as `.bashrc.bak.20261017-150000`. Repeat installs skip links already pointing
to this checkout. The installer refuses to write through a symlinked parent
directory into another checkout; move that parent link aside first if migrating
from a directory-based dotfiles setup.

Fish history, universal variables, unrelated functions, and other personal
configuration stay in place. To restore a configuration, remove its installed
symlink and move its backup to the original name. For example, using the actual
backup name printed by setup:

```bash
rm ~/.bashrc
mv ~/.bashrc.bak.20261017-150000 ~/.bashrc
```

For Fish, restore individual files in the same way. Setup does not modify desktop
configuration such as Hyprland, Noctalia, Kitty, or KDE.

## Personal additions

Use `~/.bashrc.local`, `~/.zshrc.local`, or `~/.config/fish/local.fish` for local
shell additions. These are sourced after the managed settings. Fish's local
file stays beside its individually linked configuration.

Git is deliberately opt-in so installing the shell configuration preserves an
existing Git identity and credential setup:

```bash
./setup.sh --only git --dry-run
./setup.sh --only git
```

The port omits the original plaintext `credential.helper=store` setting. Put
machine-specific Git settings in `~/.gitconfig.local`, which is included by the
managed Git configuration.

Existing NVM installations are lazy-loaded in Bash/Zsh. Existing pyenv, Go and
Rust paths are supported; setup does not install language version managers.
Python `.venv`, `venv`, and `env` directories activate automatically on directory
changes (Bash checks before its next prompt). The environment remains active
inside its project and deactivates when leaving. Manually activated environments
are preserved.

## tmux prefix help

The original submodule is retained at the same commit, using an HTTPS URL so a
new machine can clone it without GitHub SSH keys. It is optional: tmux skips
loading the help plugin until its entrypoint and release executable exist. Initialize and build it
before using the popup:

```bash
# If you do not already have a working Rust toolchain:
sudo pacman -Syu --needed base-devel rustup
rustup toolchain install stable --profile minimal

# Use stable explicitly without changing an existing default toolchain:
RUSTUP_TOOLCHAIN=stable ./setup.sh --only tmux --with-prefix-help
```

If Cargo is already provided by a suitable system Rust installation, use
`./setup.sh --only tmux --with-prefix-help` directly. This fetches the pinned
submodule and runs `cargo build --release --locked`; it does not change Rust
defaults. Re-run after updating the submodule, then reload tmux configuration.
`@prefix-help-delay` retains the original 500 ms setting.

Press `Ctrl+b` or `Ctrl+a` and pause for 500 ms to show the help popup. The next
shortcut closes the popup and runs the binding; `Esc` dismisses it and `?` opens
the complete binding list.

## Greeting

Bash, Fish, and Zsh use `pokemon-greeting --speed 0` when available and otherwise
run Fastfetch. Zsh prints the greeting before Powerlevel10k's instant prompt.
Install the same upstream greeter used by the WSL setup with:

```bash
./setup.sh --with-pokemon
```

Setup reuses an installed `pokemon-greeting` or clones the installer into
`${XDG_DATA_HOME:-$HOME/.local/share}/pokemon-terminal-greeting` and runs it with
`--no-hook`. The dotfiles manage greeting hooks, so the upstream installer does
not append its own hooks to shell configuration. Downloading it requires network
access; its upstream installation dependencies still apply.

To install both extras after configuring Rust as described above:

```bash
./setup.sh --with-pokemon --with-prefix-help --dry-run
RUSTUP_TOOLCHAIN=stable ./setup.sh --with-pokemon --with-prefix-help
```

## Validation

```bash
python3 -m unittest discover -s tests -v
```

The offline tests use temporary homes and cover backup preservation, repeat
installation, broken links, profile selection, Fish state preservation, linked
parent protection, shell syntax, and Python environment boundaries/ownership.
They do not install system packages, fetch plugins, or alter the live home.
