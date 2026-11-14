#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
install_packages=false
prefix_help=false
tmux_plugins=false
pokemon=false
profiles=bash,fish,zsh,nvim,tmux
usage() {
    cat <<'EOF'
Usage: ./setup.sh [options]
  --dry-run             Preview all actions without writing files or networking
  --only LIST           Comma-separated bash,fish,zsh,nvim,tmux,git,desktop profiles
                        Default: bash,fish,zsh,nvim,tmux; Git and desktop are opt-in
  --install-packages    Run sudo pacman -Syu --needed with packages/pacman.txt
  --with-prefix-help    Initialize and build tmux-prefix-help with Cargo
  --with-tmux-plugins   Build prefix help and RunCat, then install RunCat fonts
  --with-pokemon        Install the Pokémon greeter without upstream shell hooks
  -h, --help            Show this help

Existing configs are moved to unique backups before linking. No login shell is
changed. Default setup links configs only; package and plugin installs are opt-in.
EOF
}
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
while (($#)); do
    case "$1" in
        --dry-run) dry_run=true ;;
        --install-packages) install_packages=true ;;
        --with-prefix-help) prefix_help=true ;;
        --with-tmux-plugins) tmux_plugins=true ;;
        --with-pokemon) pokemon=true ;;
        --only)
            (($# > 1)) || die '--only requires a list'
            profiles=$2
            shift
            ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done
[[ -n $profiles && $profiles != ,* && $profiles != *, && $profiles != *,,* ]] || die 'Empty profile in --only'
IFS=, read -r -a selected <<< "$profiles"
for profile in "${selected[@]}"; do
    case "$profile" in bash|fish|zsh|nvim|tmux|git|desktop) ;; *) die "Unknown profile: $profile" ;; esac
done
sources=()
destinations=()
add_link() {
    [[ -e "$DOTFILES_DIR/$1" ]] || die "Missing source: $1 (run git submodule update --init --recursive if modules are missing)"
    sources+=("$DOTFILES_DIR/$1")
    destinations+=("$HOME/$2")
}
add_generated_link() {
    sources+=("$1")
    destinations+=("$HOME/$2")
}
theme=false
shell_profiles=()
for profile in "${selected[@]}"; do
    case "$profile" in
        bash|fish|zsh) shell_profiles+=("$profile"); theme=true ;;
        nvim|tmux|desktop) theme=true ;;
    esac
    case "$profile" in
        bash)
            add_link bash/.bash_profile .bash_profile
            add_link bash/.blerc .blerc
            ;;
        zsh) add_link zsh/.zshrc .zshrc ;;
        nvim)
            [[ -f "$DOTFILES_DIR/nvim/.config/nvim/init.lua" ]] || die 'Missing Neovim module; run git submodule update --init --recursive'
            add_link nvim/.config/nvim .config/nvim
            ;;
        tmux)
            [[ -f "$DOTFILES_DIR/tmux/.config/tmux/tmux.conf" ]] || die 'Missing tmux module; run git submodule update --init --recursive'
            add_link tmux/.config/tmux .config/tmux
            ;;
        git) add_link git/.gitconfig .gitconfig ;;
        desktop)
            add_link desktop/.config/noctalia/config.toml .config/noctalia/config.toml
            add_link desktop/.config/hypr/dotfiles-dock.lua .config/hypr/dotfiles-dock.lua
            add_link modules/theme/assets/coniston.jpg .local/share/wallpapers/dotfiles/coniston.jpg
            ;;
    esac
done
if ((${#shell_profiles[@]})); then
    manifest="$DOTFILES_DIR/modules/shell/manifest.json"
    [[ -f $manifest ]] || die 'Missing shell module; run git submodule update --init --recursive'
    # Capture and validate the entire manifest before any changes are made.
    entries=$(python3 - "$manifest" "${shell_profiles[@]}" <<'PYTHON'
import json, pathlib, sys
manifest = pathlib.Path(sys.argv[1])
selected = set(sys.argv[2:]) | {'shared', 'atuin', 'lazygit'}
data = json.loads(manifest.read_text())
if data.get('version') != 1:
    sys.exit('Unsupported shell manifest version')
for entry in data['files']:
    if selected.intersection(entry['profiles']):
        source, target = pathlib.PurePosixPath(entry['source']), pathlib.PurePosixPath(entry['target'])
        if any(p.is_absolute() or '..' in p.parts for p in (source, target)) or any('\t' in str(p) or '\n' in str(p) for p in (source, target)):
            sys.exit('Invalid shell manifest path')
        print(f'{source}\t{target}')
PYTHON
    ) || die 'Cannot read shell manifest; run git submodule update --init --recursive'
    while IFS=$'\t' read -r source target; do
        [[ -n $source ]] && add_link "modules/shell/$source" "$target"
    done <<< "$entries"
fi
if $theme; then
    add_link modules/theme/themes/chocolatier.json .config/dotfiles/theme/palette.json
    add_link modules/theme/scripts/.scripts/dotfiles-theme .local/bin/dotfiles-theme
    add_link modules/theme/atuin/.config/atuin/themes .config/atuin/themes
    add_link common/.config/kitty/kitty.conf .config/kitty/kitty.conf
    add_link common/.config/alacritty/alacritty.toml .config/alacritty/alacritty.toml
    state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/theme"
    add_generated_link "$state_dir/kitty.conf" .config/kitty/themes/dotfiles.conf
    add_generated_link "$state_dir/alacritty.toml" .config/alacritty/themes/dotfiles.toml
    if [[ ,$profiles, == *,desktop,* ]]; then
        add_link modules/theme/generated/noctalia.json .config/noctalia/palettes/Dotfiles.json
    fi
fi
# Refuse to write through a linked parent into another checkout. Leaf symlinks
# are handled below, but replacing files beneath a directory symlink is unsafe.
for dst in "${destinations[@]}"; do
    parent=$(dirname -- "$dst")
    while [[ $parent != "$HOME" && $parent != / ]]; do
        [[ ! -L $parent ]] || die "Destination parent is a symlink: $parent; move it aside before setup"
        parent=$(dirname -- "$parent")
    done
done
if $prefix_help || $tmux_plugins; then
    [[ -f "$DOTFILES_DIR/tmux/.config/tmux/tmux.conf" ]] || die 'Missing tmux module; run git submodule update --init --recursive'
fi
if [[ ,$profiles, == *,desktop,* ]]; then
    desktop_state="${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}/noctalia/settings.toml"
    # Validate the saved state before changing links or installing packages.
    python3 "$DOTFILES_DIR/scripts/configure_desktop.py" \
        "$DOTFILES_DIR/desktop/.config/noctalia/config.toml" "$desktop_state" \
        "$HOME/.local/share/wallpapers/dotfiles/coniston.jpg" --dry-run >/dev/null
fi
if $install_packages; then
    command -v pacman >/dev/null || die 'Package installation requires CachyOS/Arch and pacman'
    mapfile -t packages < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$DOTFILES_DIR/packages/pacman.txt")
    if $dry_run; then
        printf 'Would run: sudo pacman -Syu --needed %s\n' "${packages[*]}"
    else
        sudo pacman -Syu --needed "${packages[@]}"
    fi
fi
if $prefix_help || $tmux_plugins; then
    if $dry_run; then
        printf 'Would initialize pinned tmux plugins and build tmux-prefix-help with Cargo.\n'
        if $tmux_plugins; then printf 'Would build tmux-runcat and install its fonts.\n'; fi
    else
        command -v cc >/dev/null || die 'Prefix help needs a C linker; install base-devel'
        command -v cargo >/dev/null || die 'Prefix help needs Cargo; install/configure a Rust toolchain first (see README)'
        if $tmux_plugins; then
            git -C "$DOTFILES_DIR/tmux/.config/tmux" submodule update --init --recursive
        else
            git -C "$DOTFILES_DIR/tmux/.config/tmux" submodule update --init --recursive -- plugins/tmux-prefix-help
        fi
        plugin="$DOTFILES_DIR/tmux/.config/tmux/plugins/tmux-prefix-help"
        cargo build --release --locked --manifest-path "$plugin/Cargo.toml" --target-dir "$plugin/target"
        if $tmux_plugins; then
            runcat="$DOTFILES_DIR/tmux/.config/tmux/plugins/tmux-runcat"
            cargo build --release --locked --offline --manifest-path "$runcat/Cargo.toml" --target-dir "$runcat/target"
            env -u WSL_DISTRO_NAME bash "$runcat/fonts/setup.sh"
        fi
    fi
fi
if $pokemon; then
    if $dry_run; then
        printf 'Would install pokemon-terminal-greeting with --no-hook (or reuse an installed greeter).\n'
    elif command -v pokemon-greeting >/dev/null || [[ -x "$HOME/.local/bin/pokemon-greeting" ]]; then
        printf 'Pokémon greeter is already installed.\n'
    else
        command -v git >/dev/null || die 'Installing the Pokémon greeter requires Git'
        pokemon_dir="${XDG_DATA_HOME:-$HOME/.local/share}/pokemon-terminal-greeting"
        if [[ ! -e $pokemon_dir ]]; then
            mkdir -p -- "$(dirname -- "$pokemon_dir")"
            git clone --depth 1 https://github.com/Youpen-y/pokemon-terminal-greeting.git "$pokemon_dir"
        fi
        [[ -f "$pokemon_dir/install.sh" ]] || die "Missing Pokémon installer: $pokemon_dir/install.sh"
        bash "$pokemon_dir/install.sh" --no-hook
    fi
fi
for i in "${!sources[@]}"; do
    src=${sources[i]}
    dst=${destinations[i]}
    if [[ -L $dst && $(readlink -m -- "$dst") == $(readlink -m -- "$src") ]]; then
        printf 'Already linked: %s\n' "$dst"
        continue
    fi
    if $dry_run; then
        [[ ! -e $dst && ! -L $dst ]] || printf 'Would back up: %s\n' "$dst"
        printf 'Would link: %s -> %s\n' "$dst" "$src"
        continue
    fi
    mkdir -p -- "$(dirname -- "$dst")"
    if [[ -e $dst || -L $dst ]]; then
        backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
        suffix=0
        while [[ -e $backup || -L $backup ]]; do
            suffix=$((suffix + 1))
            backup="${dst}.bak.$(date +%Y%m%d-%H%M%S).$suffix"
        done
        mv -- "$dst" "$backup"
        printf 'Backed up: %s -> %s\n' "$dst" "$backup"
    fi
    ln -s -- "$src" "$dst"
    printf 'Linked: %s -> %s\n' "$dst" "$src"
done
if [[ ,$profiles, == *,desktop,* ]]; then
    desktop_args=()
    $dry_run && desktop_args+=(--dry-run)
    python3 "$DOTFILES_DIR/scripts/configure_desktop.py" \
        "$DOTFILES_DIR/desktop/.config/noctalia/config.toml" "$desktop_state" \
        "$HOME/.local/share/wallpapers/dotfiles/coniston.jpg" "${desktop_args[@]}"
    if ! $dry_run && [[ ${DOTFILES_THEME_NO_NOCTALIA:-0} != 1 ]] && command -v noctalia >/dev/null; then
        noctalia msg config-reload || printf 'Noctalia is offline; the preset will load at startup.\n'
    fi
fi
if $theme; then
    if $dry_run; then
        printf 'Would apply the shared theme without application changes.\n'
    else
        no_noctalia=${DOTFILES_THEME_NO_NOCTALIA:-1}
        if [[ ,$profiles, == *,desktop,* && -z ${DOTFILES_THEME_NO_NOCTALIA+x} ]]; then no_noctalia=0; fi
        DOTFILES_THEME_NO_APPS=1 DOTFILES_THEME_NO_NOCTALIA=$no_noctalia "$HOME/.local/bin/dotfiles-theme" apply
    fi
fi
if [[ ,$profiles, == *,desktop,* ]]; then
    printf 'Desktop profile: see docs/desktop.md for the Super-key hook, reload and rollback.\n'
fi
printf 'Done. Open a new shell to load the selected profiles.\n'
