status is-interactive; or return
function _dotfiles_auto_venv --on-variable PWD --description 'Manage project Python environments'
    if test -n "$VIRTUAL_ENV"; and test "$VIRTUAL_ENV" != "$_DOTFILES_AUTO_VENV"
        return
    end
    for candidate in .venv venv env
        set -l target "$PWD/$candidate"
        if test -f "$target/bin/activate.fish"
            if test "$VIRTUAL_ENV" != "$target"
                if test -n "$_DOTFILES_AUTO_VENV"; and functions -q deactivate
                    deactivate
                end
                source "$target/bin/activate.fish"
                set -g _DOTFILES_AUTO_VENV "$target"
            end
            return
        end
    end
    if test -n "$_DOTFILES_AUTO_VENV"; and test -n "$VIRTUAL_ENV"
        set -l parent (path dirname "$_DOTFILES_AUTO_VENV")
        if test "$PWD" != "$parent"; and not string match -q -- "$parent/*" "$PWD/"
            if functions -q deactivate
                deactivate
            end
            set -e _DOTFILES_AUTO_VENV
        end
    end
end
