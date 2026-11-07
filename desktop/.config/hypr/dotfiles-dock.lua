-- Load once from hyprland.lua:
-- dofile(os.getenv("HOME") .. "/.config/hypr/dotfiles-dock.lua")
-- Hyprland 0.56 Lua API. No key grab, polling, daemon, or shell settings writes.
local held = {}
for _, key in ipairs({ "Super_L", "Super_R" }) do
    hl.bind(key, function()
        if held[key] then return end
        local already_held = next(held) ~= nil
        held[key] = true
        if not already_held then
            -- Temporarily disable pointer auto-hide so moving the mouse cannot
            -- dismiss the bar while Super is down. IPC overrides are transient.
            hl.exec_cmd("noctalia msg bar-auto-hide-set off default")
        end
    end, { non_consuming = true, ignore_mods = true })

    hl.bind(key, function()
        held[key] = nil
        if next(held) == nil then
            -- One process preserves command order. Restore configured auto-hide
            -- and retract; edge hover and workspace-change peeks still work.
            hl.exec_cmd("noctalia msg bar-auto-hide-set on default && noctalia msg bar-hide default")
        end
    end, { release = true, non_consuming = true, ignore_mods = true })
end
