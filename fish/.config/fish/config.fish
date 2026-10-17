# Native Linux paths; Fish remains an explicit shell choice.
fish_add_path "$HOME/.local/bin"
if set -q GOPATH
    fish_add_path "$GOPATH/bin"
else
    fish_add_path "$HOME/go/bin"
end
if test -d "$HOME/.pyenv/bin"
    fish_add_path "$HOME/.pyenv/shims" "$HOME/.pyenv/bin"
end
status is-interactive; or return
if type -q bat; and type -q col
    set -gx MANROFFOPT -c
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
end
if type -q eza
    alias ls='eza -al --color=always --group-directories-first --icons=always'
    alias la='eza -a --color=always --group-directories-first --icons=always'
    alias ll='eza -l --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
    alias l.="eza -a | grep -e '^\.'"
end
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
if type -q fzf
    if type -q fd
        set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
        set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        set -gx FZF_ALT_C_COMMAND 'fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
    end
    set -gx FZF_DEFAULT_OPTS "--style=full --layout=reverse --height=60% --border=rounded --border-label=' 󰍉 Search ' --border-label-pos=2 --info=inline-right --prompt='❯ ' --pointer='◆' --marker='✓'"
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || cat {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --color=always --icons=always {} 2>/dev/null || command ls -la {}'"
    fzf --fish | source
end
if type -q zoxide
    zoxide init fish | source
end
function fish_greeting
    if type -q pokemon-greeting
        pokemon-greeting --speed 0
    else if type -q fastfetch
        fastfetch
    end
end
_dotfiles_auto_venv
if test -f "$HOME/.config/fish/local.fish"
    source "$HOME/.config/fish/local.fish"
end
