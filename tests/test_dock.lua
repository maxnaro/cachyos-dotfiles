-- Offline behavior test: lua tests/test_dock.lua
local binds, commands = {}, {}
hl = {
    bind = function(key, callback, options)
        assert(options.non_consuming and options.ignore_mods)
        binds[key .. (options.release and ":up" or ":down")] = callback
    end,
    exec_cmd = function(command) commands[#commands + 1] = command end,
}
dofile("desktop/.config/hypr/dotfiles-dock.lua")
assert(binds["Super_L:down"] and binds["Super_R:up"])
binds["Super_L:down"]()
assert(#commands == 1 and commands[1]:find("bar%-auto%-hide%-set off default"))
binds["Super_L:down"]() -- ignore duplicate presses
binds["Super_R:down"]() -- both Super keys held
binds["Super_L:up"]() -- do not hide while right Super is still held
assert(#commands == 1)
binds["Super_R:up"]()
assert(#commands == 2)
assert(commands[2] == "noctalia msg bar-auto-hide-set on default && noctalia msg bar-hide default")
binds["Super_R:down"]()
binds["Super_R:up"]()
assert(#commands == 4)
print("Super hold bindings: ok")
