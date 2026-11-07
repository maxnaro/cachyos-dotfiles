local M = {}
local timer
local applied

-- Read Noctalia's generated output, not kitty.conf (which may contain user overrides).
local function palette()
  local root = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
  local ok, lines = pcall(vim.fn.readfile, root .. "/kitty/themes/noctalia.conf")
  if not ok then
    return
  end
  local colors = {}
  for _, line in ipairs(lines) do
    local key, value = line:match("^%s*([%w_]+)%s+(#%x%x%x%x%x%x)%s*$")
    if key then
      colors[key] = value
    end
  end
  -- Ignore incomplete/partially written palettes and retain the current theme.
  for _, key in ipairs({ "background", "foreground", "selection_background", "selection_foreground", "active_border_color" }) do
    if not colors[key] then
      return
    end
  end
  for i = 0, 15 do
    if not colors["color" .. i] then
      return
    end
  end
  return colors, table.concat(lines, "\n")
end

function M.load()
  local c, contents = palette()
  -- A bundled, dependency-free fallback also supplies groups we don't override.
  vim.cmd.colorscheme("habamax")
  vim.g.colors_name = "noctalia"
  applied = contents
  if not c then
    return
  end

  local function luminance(hex)
    return tonumber(hex:sub(2, 3), 16) * 0.299
      + tonumber(hex:sub(4, 5), 16) * 0.587
      + tonumber(hex:sub(6, 7), 16) * 0.114
  end
  vim.o.background = luminance(c.background) > luminance(c.foreground) and "light" or "dark"
  local function hl(name, fg, bg, extra)
    vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", { fg = fg, bg = bg }, extra or {}))
  end
  local bg, fg, muted = c.background, c.foreground, c.color8
  local surface, accent = c.selection_background, c.active_border_color
  hl("Normal", fg, bg)
  hl("NormalNC", fg, bg)
  hl("NormalFloat", fg, bg)
  hl("FloatBorder", accent, bg)
  hl("FloatTitle", accent, bg, { bold = true })
  hl("Visual", c.selection_foreground, surface)
  hl("Cursor", c.cursor_text_color or bg, c.cursor or fg)
  hl("CursorLine", nil, surface)
  hl("CursorColumn", nil, surface)
  hl("LineNr", muted, bg)
  hl("CursorLineNr", accent, surface, { bold = true })
  hl("SignColumn", fg, bg)
  hl("FoldColumn", muted, bg)
  hl("Folded", muted, surface)
  hl("WinSeparator", surface, bg)
  hl("StatusLine", fg, surface)
  hl("StatusLineNC", muted, bg)
  hl("TabLine", muted, surface)
  hl("TabLineFill", fg, bg)
  hl("TabLineSel", bg, accent, { bold = true })
  hl("Pmenu", fg, surface)
  hl("PmenuSel", bg, accent)
  hl("PmenuSbar", nil, surface)
  hl("PmenuThumb", nil, muted)
  hl("Search", bg, c.color3)
  hl("IncSearch", bg, accent)
  hl("CurSearch", bg, accent)
  hl("MatchParen", accent, surface, { bold = true })
  hl("NonText", surface)
  hl("Whitespace", surface)
  hl("EndOfBuffer", surface)
  hl("Directory", accent)
  hl("Title", accent, nil, { bold = true })
  hl("Comment", muted, nil, { italic = true })
  hl("Constant", c.color3)
  hl("String", c.color2)
  hl("Identifier", fg)
  hl("Function", c.color4)
  hl("Statement", c.color5)
  hl("Operator", c.color6)
  hl("PreProc", c.color6)
  hl("Type", c.color3)
  hl("Special", c.color4)
  hl("Delimiter", c.color6)
  hl("Error", c.color1)
  hl("ErrorMsg", c.color1)
  hl("WarningMsg", c.color3)
  hl("Todo", bg, c.color3, { bold = true })
  for name, color in pairs({ Error = c.color1, Warn = c.color3, Info = c.color4, Hint = c.color6, Ok = c.color2 }) do
    hl("Diagnostic" .. name, color)
    hl("DiagnosticUnderline" .. name, nil, nil, { sp = color, undercurl = true })
  end
  for name, color in pairs({ Add = c.color2, Change = c.color3, Delete = c.color1, Text = c.color4 }) do
    hl("Diff" .. name, color, surface)
  end
  for name, color in pairs({ Add = c.color2, Change = c.color3, Delete = c.color1 }) do
    hl("GitSigns" .. name, color, bg)
  end
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = c["color" .. i]
  end
end

function M.setup()
  vim.opt.termguicolors = true
  vim.cmd.colorscheme("noctalia")
  if timer then
    return
  end
  -- Polling also handles atomic file replacement and a palette created after startup.
  timer = assert((vim.uv or vim.loop).new_timer())
  timer:start(2000, 2000, vim.schedule_wrap(function()
    if vim.g.colors_name ~= "noctalia" then
      return -- Respect an explicitly selected alternative colorscheme.
    end
    local _, contents = palette()
    if contents and contents ~= applied then
      vim.cmd.colorscheme("noctalia")
    end
  end))
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("noctalia_theme", { clear = true }),
    once = true,
    callback = function()
      timer:stop()
      timer:close()
    end,
  })
end

return M
