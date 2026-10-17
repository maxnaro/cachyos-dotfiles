#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
install_packages=false
prefix_help=false
pokemon=false
profiles=bash,fish,zsh,nvim,tmux
usage() {
    cat <<'EOF'
Usage: ./setup.sh [options]
  --dry-run             Preview all actions without writing files or networking
  --only LIST           Comma-separated bash,fish,zsh,nvim,tmux,git profiles
                        Default: bash,fish,zsh,nvim,tmux; Git config is opt-in
  --install-packages    Run sudo pacman -Syu --needed with packages/pacman.txt
  --with-prefix-help    Fetch the pinned tmux submodule and build it with Cargo
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
    case "$profile" in bash|fish|zsh|nvim|tmux|git) ;; *) die "Unknown profile: $profile" ;; esac
done
# Shared files are required by both shell profiles, including Zsh without Bash.
sources=()
destinations=()
add_link() {
    [[ -e "$DOTFILES_DIR/$1" ]] || die "Missing source: $1"
    sources+=("$DOTFILES_DIR/$1")
    destinations+=("$HOME/$2")
}
for profile in "${selected[@]}"; do
    case "$profile" in
        bash)
            for file in .bashrc .bash_profile .inputrc .blerc; do add_link "bash/$file" "$file"; done
            ;;
        zsh) add_link zsh/.zshrc .zshrc ;;
        fish)
            # Link files individually so history, universal variables and unrelated
            # functions remain on the machine rather than entering version control.
            while IFS= read -r -d '' file; do
                relative=${file#"$DOTFILES_DIR/fish/"}
                add_link "fish/$relative" "$relative"
            done < <(find "$DOTFILES_DIR/fish" -type f -print0)
            ;;
        nvim|tmux) add_link "$profile/.config/$profile" ".config/$profile" ;;
        git) add_link git/.gitconfig .gitconfig ;;
    esac
done
if [[ ,$profiles, == *,bash,* || ,$profiles, == *,zsh,* ]]; then
    add_link common/.config/dotfiles/terminal.sh .config/dotfiles/terminal.sh
    add_link bash/.bash_aliases .bash_aliases
    add_link scripts/.scripts/auto_venv.sh .scripts/auto_venv.sh
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
if $install_packages; then
    command -v pacman >/dev/null || die 'Package installation requires CachyOS/Arch and pacman'
    mapfile -t packages < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$DOTFILES_DIR/packages/pacman.txt")
    if $dry_run; then
        printf 'Would run: sudo pacman -Syu --needed %s\n' "${packages[*]}"
    else
        sudo pacman -Syu --needed "${packages[@]}"
    fi
fi
if $prefix_help; then
    if $dry_run; then
        printf 'Would initialize the pinned tmux-prefix-help submodule and build it with Cargo.\n'
    else
        command -v cc >/dev/null || die 'Prefix help needs a C linker; install base-devel'
        command -v cargo >/dev/null || die 'Prefix help needs Cargo; install/configure a Rust toolchain first (see README)'
        git -C "$DOTFILES_DIR" submodule update --init --recursive
        plugin="$DOTFILES_DIR/tmux/.config/tmux/plugins/tmux-prefix-help"
        cargo build --release --locked --manifest-path "$plugin/Cargo.toml" --target-dir "$plugin/target"
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
    if [[ -L $dst && $(readlink -- "$dst") == "$src" ]]; then
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
printf 'Done. Open a new shell to load the selected profiles.\n'
