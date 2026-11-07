-- Offline: nvim --headless -u NONE -l tests/test_nvim_theme.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/nvim/.config/nvim")
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/kitty/themes", "p")
vim.env.XDG_CONFIG_HOME = root
local path = root .. "/kitty/themes/noctalia.conf"
local theme = require("config.noctalia")
local function normal()
  return vim.api.nvim_get_hl(0, { name = "Normal", link = false })
end
local function write_palette(bg, fg)
  local lines = {
    "background " .. bg,
    "foreground " .. fg,
    "selection_background #42474e",
    "selection_foreground #c2c7cf",
    "active_border_color #9acbfa",
  }
  for i = 0, 15 do
    lines[#lines + 1] = "color" .. i .. " #9acbfa"
  end
  vim.fn.writefile(lines, path)
end

theme.setup()
assert(vim.g.colors_name == "noctalia", "missing palette should fall back without errors")
write_palette("#101418", "#e0e2e8")
assert(vim.wait(3500, function() return normal().bg == 0x101418 end), "must pick up a newly created palette")
assert(normal().fg == 0xe0e2e8 and vim.o.background == "dark")
assert(vim.g.terminal_color_0 == "#9acbfa")
assert(vim.api.nvim_get_hl(0, { name = "Function" }).fg == 0x9acbfa)
write_palette("#fafafa", "#101418")
assert(vim.wait(3500, function() return normal().bg == 0xfafafa end), "must reload changed palettes")
assert(normal().fg == 0x101418 and vim.o.background == "light")
vim.fn.writefile({ "background #ffffff" }, path)
vim.wait(2200, function() return false end)
assert(normal().bg == 0xfafafa, "incomplete writes must not replace the palette")
vim.cmd.colorscheme("habamax")
write_palette("#101418", "#e0e2e8")
vim.wait(2200, function() return false end)
assert(vim.g.colors_name == "habamax", "must respect manual colorscheme changes")
vim.fn.delete(root, "rf")
print("Neovim Noctalia theme: ok")
vim.cmd.qa()
