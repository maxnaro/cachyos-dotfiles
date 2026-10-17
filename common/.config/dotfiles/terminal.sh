# Shared Bash/Zsh terminal settings; loaded only in interactive shells.
export PATH="$HOME/.local/bin:${GOPATH:-$HOME/go}/bin:$PATH"
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
if command -v bat >/dev/null && command -v col >/dev/null; then
    export MANROFFOPT=-c
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
if command -v fzf >/dev/null; then
    if command -v fd >/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
    fi
    export FZF_DEFAULT_OPTS="--style=full --layout=reverse --height=60% --border=rounded --border-label=' 󰍉 Search ' --border-label-pos=2 --info=inline-right --prompt='❯ ' --pointer='◆' --marker='✓'"
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || cat {}'"
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons=always {} 2>/dev/null || command ls -la {}'"
fi
# Register lazy wrappers only when NVM actually exists.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _dotfiles_load_nvm() {
        unset -f nvm node npm npx pnpm yarn _dotfiles_load_nvm
        source "$NVM_DIR/nvm.sh"
    }
    for _dotfiles_cmd in nvm node npm npx pnpm yarn; do
        eval "$_dotfiles_cmd() { _dotfiles_load_nvm; $_dotfiles_cmd \"\$@\"; }"
    done
    unset _dotfiles_cmd
fi
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [[ -d "$PYENV_ROOT/bin" ]]; then
    export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
fi
source "$HOME/.bash_aliases"
source "$HOME/.scripts/auto_venv.sh"
