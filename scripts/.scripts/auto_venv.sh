# Bash/Zsh prompt hook. Only deactivate environments activated by this hook.
_dotfiles_auto_venv() {
    local candidate
    if [[ -n ${VIRTUAL_ENV:-} && ${VIRTUAL_ENV:-} != "${_DOTFILES_AUTO_VENV:-}" ]]; then
        return 0
    fi
    for candidate in .venv venv env; do
        if [[ -f "$PWD/$candidate/bin/activate" ]]; then
            candidate="$PWD/$candidate"
            if [[ ${VIRTUAL_ENV:-} != "$candidate" ]]; then
                if [[ -n ${_DOTFILES_AUTO_VENV:-} ]] && typeset -f deactivate >/dev/null; then
                    deactivate
                fi
                source "$candidate/bin/activate"
                _DOTFILES_AUTO_VENV="$candidate"
            fi
            return 0
        fi
    done
    if [[ -n ${_DOTFILES_AUTO_VENV:-} && -n ${VIRTUAL_ENV:-} ]]; then
        case "$PWD/" in
            "${_DOTFILES_AUTO_VENV%/*}/"*) ;;
            *)
                typeset -f deactivate >/dev/null && deactivate
                unset _DOTFILES_AUTO_VENV
                ;;
        esac
    fi
    return 0
}
