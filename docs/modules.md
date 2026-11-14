# Shared modules

The parent checkout pins each module as a Git submodule. Initialize recursively
because tmux contains four pinned plugin submodules:

```bash
git submodule update --init --recursive
```

| Path | Canonical repository | Owns |
| --- | --- | --- |
| `modules/theme` | [dotfiles-theme](https://github.com/maxnaro/dotfiles-theme) | Palettes, generated assets, theme command and installer |
| `modules/shell` | [dotfiles-shell](https://github.com/maxnaro/dotfiles-shell) | Shared Bash/Fish configuration and helper manifest |
| `tmux/.config/tmux` | [dotfiles-tmux](https://github.com/maxnaro/dotfiles-tmux) | tmux configuration, workspace script and plugin pins |
| `nvim/.config/nvim` | [nvim-config](https://github.com/maxnaro/nvim-config) | Neovim configuration and plugin lockfile |

The CachyOS parent owns profile selection, native package setup, desktop config,
and links into the home directory. WSL has its own parent installer. Updating a
module inside one parent does not automatically change the other parent's pin.

To change a module, work and test inside that repository, commit and publish its
commit, then update the gitlink in each parent as a separate reviewed change.
For example, after fetching the desired published commit:

```bash
git -C modules/theme fetch origin
git -C modules/theme checkout <commit>
git add modules/theme
git diff --cached --submodule=log
```

Run the parent and relevant module tests before committing the pin. For tmux,
initialize nested submodules at their recorded pins after changing its gitlink.
Never rely on an uncommitted module working tree: a fresh recursive checkout
only receives committed module content.
