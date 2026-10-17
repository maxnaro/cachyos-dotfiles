# CachyOS Bash profile. Keep Bash available alongside Fish and Zsh.
[[ $- == *i* ]] || return
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend checkwinsize
[[ -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
source "$HOME/.config/dotfiles/terminal.sh"
if command -v fzf >/dev/null; then
    eval "$(fzf --bash)"
fi
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
_dotfiles_git_branch() {
    local branch
    branch=$(git branch --show-current 2>/dev/null)
    [[ -z $branch ]] || printf ' (%s)' "$branch"
}
PS1='\w$(_dotfiles_git_branch)\n❯ '
# PROMPT_COMMAND supports arrays in the packaged Bash version.
if [[ ! " ${PROMPT_COMMAND[*]} " == *' _dotfiles_auto_venv '* ]]; then
    PROMPT_COMMAND+=(_dotfiles_auto_venv)
fi
if command -v pokemon-greeting >/dev/null; then
    pokemon-greeting --speed 0
elif command -v fastfetch >/dev/null; then
    fastfetch
fi
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
. "$HOME/.cargo/env"
