# Top-attached Noctalia dock

An opt-in **Noctalia 5.3+ / Hyprland 0.56 Lua** preset. It uses the shared Dotfiles palette with a native Noctalia bar.

## Design and behavior

- Native custom `Dotfiles` palette with numbered, equal workspace pills.
  The Chocolatier dark background is `#281F11`; the Windows dock background
  is `#2A201A`, with teal `#7EA69F`.
- Battery on the left; time and date (`HH:MM · Fri 07 Nov`) on the right.
  No launcher/settings owl buttons, following Zebar's minimal utility layout.
- Native attached bar surface, not a capsule group: flat top corners and 12px
  rounded lower corners, 36px high, flush with the screen edge.
- Battery uses the left lane, workspaces the center lane, and clock/date the
  right lane, spreading content within the existing width with 16px horizontal
  padding at each end. Workspace pills stay
  centered independently of side content and use a 3px pill radius.
- The native surface requires pixel insets on installed Noctalia: 530px per
  side produces a compact 476px dock on the current 1536px logical display.
  This is not automatic fit-to-content; adjust insets on other monitors.
- Network, audio and other utilities remain available through control center
  (`Super+X` in the original keybindings); the dock omits their individual widgets
  and control-center button to keep the workspace indicator central.
- Opaque native surface with a subtle outline and shadow, without compositor blur.
- Passive widgets: no clicks, scrolling, hover highlights, or tooltips. This
  disables widget interaction, not the host surface's input region: it does not
  guarantee that clicks reach windows behind the dock. Edge-hover reveal remains.
- No window title, media title or system-monitor cluster competing with workspaces.
- The Coniston photo is used as a static wallpaper; wallpaper automation is
  disabled. Shell mode follows the selected shared theme.
- GTK and Qt theme templates remain enabled. Native Kitty and Alacritty
  templates are disabled so they do not overwrite the shared managed colours.
- Auto-hide and native workspace-switch reveal, with no reserved desktop space.
- Hold either **Super** key to reveal the bar on all monitors. It stays visible
  until both Super keys are released, then retracts. Existing Super shortcuts
  remain usable: the bindings are non-consuming and ignore other modifiers.
- Pointer auto-hide is temporarily disabled during the hold, restored on release.
  These IPC overrides are runtime-only; no settings files are rewritten.

Installed Noctalia 5.3 silently falls back to 100px for percentage `margin_ends`
values, so use integer pixel insets. The native bar exposes independent corner
radii (unlike capsule groups), matching the flat-top/rounded-bottom attached
panel geometry. It is not an actual dropdown panel or automatically sized surface.
Noctalia controls workspace-peek timing. `auto_hide_delay_ms = 1200` applies only to pointer leave;
Super release retracts immediately. Native edge-hover reveal still works.

## Install

**This replaces the Noctalia configuration, not just its bar section.** Setup
backs up existing files. Setup clears saved appearance overrides owned by the
preset, preserves unrelated Noctalia state, and selects the Coniston wallpaper
for the default, last, and existing per-monitor paths. It backs up changed
`settings.toml` before migration; repeat runs do not create another backup when
there is no change. The preset does not merge future customizations automatically.

```bash
cd ~/dotfiles
noctalia config validate "$PWD/desktop/.config/noctalia/config.toml"
./setup.sh --only desktop --dry-run
./setup.sh --only desktop
```

The desktop profile links:

- `~/.config/noctalia/config.toml`
- `~/.config/hypr/dotfiles-dock.lua`
- `~/.local/share/wallpapers/dotfiles/coniston.jpg`

For Super-held reveal, **load the hook once**, at the end of
`~/.config/hypr/hyprland.lua` (back up that file first):

```lua
dofile(os.getenv("HOME") .. "/.config/hypr/dotfiles-dock.lua")
```

Then reload:

```bash
hyprctl reload
hyprctl configerrors
noctalia msg config-reload
```

The loader was added to the current machine when this feature was applied.
Setup links the hook but deliberately does not edit an existing compositor
configuration on new machines. Do not load the hook twice. If Hyprland or
Noctalia reloads while Super is held, release and press Super again to resync.
The hook assumes this preset's `auto_hide = true`; remove the hook if switching
to an always-visible bar.

Noctalia already starts from the CachyOS Hyprland autostart module. This does not
start a second shell or install any packages. Noctalia can hot-reload the linked
config immediately. Default setup still excludes desktop changes.

To keep windows below the bar, set `reserve_space = true`. To keep the bar
visible, remove the Super hook and set `auto_hide = false`. Edits through the
installed symlinks modify this checkout; review `git diff` after GUI changes too.

## Roll back

Remove the `dofile(...)` line from `~/.config/hypr/hyprland.lua` and reload
Hyprland. Remove the installed links, then restore the exact backup paths
printed by setup. For example:

```bash
rm ~/.config/noctalia/config.toml
mv ~/.config/noctalia/config.toml.bak.YYYYMMDD-HHMMSS ~/.config/noctalia/config.toml
rm ~/.config/hypr/dotfiles-dock.lua
rm ~/.local/share/wallpapers/dotfiles/coniston.jpg
# Restore the exact settings backup printed by setup, if one was created:
cp ~/.local/state/noctalia/settings.toml.bak.UNIQUE/original ~/.local/state/noctalia/settings.toml
hyprctl reload
noctalia msg config-reload
```

Use the exact printed settings backup path, including its unique directory.
The state path uses `NOCTALIA_STATE_HOME`, then `XDG_STATE_HOME`, then
`~/.local/state`; if setup created settings without a prior file, remove that
new settings file to restore absence. Restore any printed hook or wallpaper link
backups too. If there was no prior Noctalia config, remove its symlink and reload
to use defaults. Other Noctalia and Hyprland files are left alone.

## Validation

```bash
python3 -m unittest discover -s tests -v
noctalia config validate "$PWD/desktop/.config/noctalia/config.toml"
```

The Lua behavior test covers press/release, repeated presses, overlapping left
and right Super holds, and non-consuming bindings. Actual keyboard routing and
visual appearance still require a live desktop check.
