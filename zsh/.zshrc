# Retain CachyOS completion, highlighting, suggestions and Powerlevel10k.
[[ -o interactive ]] || return
# Print before CachyOS starts Powerlevel10k's instant prompt.
if [[ -x "$HOME/.local/bin/pokemon-greeting" ]]; then
    "$HOME/.local/bin/pokemon-greeting" --speed 0
elif command -v pokemon-greeting >/dev/null; then
    pokemon-greeting --speed 0
elif command -v fastfetch >/dev/null; then
    fastfetch
fi
if [[ -r /usr/share/cachyos-zsh-config/cachyos-config.zsh ]]; then
    source /usr/share/cachyos-zsh-config/cachyos-config.zsh
else
    autoload -Uz compinit
    compinit
    PROMPT='%~%# '
fi
source "$HOME/.config/dotfiles/terminal.sh"
# CachyOS may already load FZF through its Oh My Zsh plugin.
if command -v fzf >/dev/null && (( ! $+functions[fzf-file-widget] )); then
    eval "$(fzf --zsh)"
fi
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _dotfiles_auto_venv
_dotfiles_auto_venv
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
