# Bash login shells use the same interactive configuration.
[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
. "$HOME/.cargo/env"
