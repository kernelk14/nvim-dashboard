-- The colour themes of the dashboard.
--
-- The shared core is optional. When neocore is installed the dashboard and the
-- other neo plugins share one palette implementation, when it is not the
-- vendored copy below is used. `tests/conformance.lua` makes sure the two
-- implementations agree.

local util = require("neodash.util")

local M = {}

-- The shared core, when it happens to be installed.
local has_core, core = pcall(require, "neocore.palette")

--- True when the shared core is being used.
---@return boolean
function M.using_core()
  return has_core
end

M.themes = {
  aurora = {
    bg = "#0b1020",
    surface = "#131c33",
    surface_alt = "#1b2745",
    border = "#2a3555",
    text = "#c9d5f3",
    muted = "#7f8cb3",
    dim = "#4b5578",
    accent = "#7aa2f7",
    accent2 = "#bb9af7",
    accent3 = "#7dcfff",
    green = "#9ece6a",
    yellow = "#e0af68",
    red = "#f7768e",
    cyan = "#7dcfff",
  },
  mocha = {
    bg = "#11111b",
    surface = "#1e1e2e",
    surface_alt = "#26263a",
    border = "#33334a",
    text = "#cdd6f4",
    muted = "#838ba7",
    dim = "#5c6078",
    accent = "#89b4fa",
    accent2 = "#cba6f7",
    accent3 = "#94e2d5",
    green = "#a6e3a1",
    yellow = "#f9e2af",
    red = "#f38ba8",
    cyan = "#89dceb",
  },
  nord = {
    bg = "#2e3440",
    surface = "#3b4252",
    surface_alt = "#434c5e",
    border = "#4c566a",
    text = "#eceff4",
    muted = "#93a1bd",
    dim = "#616e88",
    accent = "#88c0d0",
    accent2 = "#b48ead",
    accent3 = "#81a1c1",
    green = "#a3be8c",
    yellow = "#ebcb8b",
    red = "#bf616a",
    cyan = "#8fbcbb",
  },
  ember = {
    bg = "#12100e",
    surface = "#1c1815",
    surface_alt = "#241f1b",
    border = "#342c25",
    text = "#efe4d8",
    muted = "#a1907f",
    dim = "#6d5f53",
    accent = "#ff9f43",
    accent2 = "#ff6b81",
    accent3 = "#ffd166",
    green = "#b8cc8a",
    yellow = "#ffd166",
    red = "#ff6b6b",
    cyan = "#7fd1c0",
  },
  mono = {
    bg = "#0d0d0f",
    surface = "#17171a",
    surface_alt = "#212127",
    border = "#2e2e36",
    text = "#e6e6ea",
    muted = "#8b8b95",
    dim = "#55555f",
    accent = "#d9d9e3",
    accent2 = "#a3a3b0",
    accent3 = "#c6c6d2",
    green = "#b6d7a8",
    yellow = "#e5c07b",
    red = "#e06c75",
    cyan = "#98c379",
  },
  daylight = {
    bg = "#f6f3ec",
    surface = "#ece7db",
    surface_alt = "#e2dccd",
    border = "#d0c9b6",
    text = "#3f3a33",
    muted = "#7b746a",
    dim = "#a79f92",
    accent = "#3b6ea5",
    accent2 = "#8250df",
    accent3 = "#2a7f7f",
    green = "#3f7d3f",
    yellow = "#a97a1e",
    red = "#b4383b",
    cyan = "#2a7f7f",
  },
}

local gradient_steps = 12

local function hl_fg(name)
  local ok, res = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and res and res.fg then
    return string.format("#%06x", res.fg)
  end
  return nil
end

local function hl_bg(name)
  local ok, res = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and res and res.bg then
    return string.format("#%06x", res.bg)
  end
  return nil
end

--- The palette derived from the active colorscheme.
--- This is the vendored implementation, it matches the one in neocore.
---@return table
local function vendored_auto_palette()
  local bg = hl_bg("Normal") or "#0b1020"
  local fg = hl_fg("Normal") or "#c9d5f3"
  local light = (
    vim.fn.str2nr(bg:sub(2, 2), 16) * 299
    + vim.fn.str2nr(bg:sub(4, 4), 16) * 587
    + vim.fn.str2nr(bg:sub(6, 6), 16) * 114
  )
      / 1000
    > 128
  local palette = {
    bg = bg,
    surface = util.blend(bg, fg, light and 0.04 or 0.06),
    surface_alt = util.blend(bg, fg, light and 0.08 or 0.11),
    border = util.blend(bg, fg, light and 0.18 or 0.2),
    text = fg,
    muted = hl_fg("Comment") or util.blend(bg, fg, 0.55),
    dim = util.blend(bg, fg, 0.35),
    accent = hl_fg("Function") or hl_fg("DiagnosticInfo") or "#7aa2f7",
    accent2 = hl_fg("Statement") or hl_fg("DiagnosticHint") or "#bb9af7",
    accent3 = hl_fg("Constant") or hl_fg("Type") or "#7dcfff",
    green = hl_fg("DiagnosticOk") or hl_fg("String") or "#9ece6a",
    yellow = hl_fg("DiagnosticWarn") or "#e0af68",
    red = hl_fg("DiagnosticError") or "#f7768e",
    cyan = hl_fg("DiagnosticInfo") or "#7dcfff",
  }
  return palette
end

--- Resolve a palette with the vendored implementation.
---@param name string?
---@param transparent boolean?
---@return table
local function vendored_palette(name, transparent)
  local base
  if name == "auto" then
    base = vendored_auto_palette()
  else
    base = M.themes[name] or M.themes.aurora
    base = vim.deepcopy(base)
  end
  if transparent then
    base.bg = "NONE"
  end
  return base
end

-- The vendored implementation is exposed so the conformance test can compare
-- it with the one in neocore.
M.vendored_auto_palette = vendored_auto_palette
M.vendored_palette = vendored_palette

--- The palette derived from the active colorscheme.
---@return table
function M.auto_palette()
  if has_core then
    return core.auto_palette()
  end
  return vendored_auto_palette()
end

--- Resolve a palette by name.
---@param name string?
---@param transparent boolean?
---@return table
function M.palette(name, transparent)
  if has_core then
    return core.palette(name, transparent)
  end
  return vendored_palette(name, transparent)
end

--- The names of the available palettes.
---@return string[]
function M.names()
  if has_core then
    return core.names()
  end

  local names = { "auto" }
  local themes = {}
  for name in pairs(M.themes) do
    themes[#themes + 1] = name
  end
  table.sort(themes)
  for _, name in ipairs(themes) do
    names[#names + 1] = name
  end
  return names
end

local function set(name, def)
  vim.api.nvim_set_hl(0, name, def)
end

function M.apply(name, transparent)
  local p = M.palette(name, transparent)
  local bg = p.bg

  set("NeodashNormal", { fg = p.text, bg = bg })
  set("NeodashText", { fg = p.text, bg = p.surface })
  set("NeodashTitle", { fg = p.text, bg = p.surface, bold = true })
  set("NeodashMuted", { fg = p.muted, bg = p.surface })
  set("NeodashDim", { fg = p.dim, bg = p.surface })
  set("NeodashAccent", { fg = p.accent, bg = p.surface })
  set("NeodashAccent2", { fg = p.accent2, bg = p.surface })
  set("NeodashGreen", { fg = p.green, bg = p.surface })
  set("NeodashYellow", { fg = p.yellow, bg = p.surface })
  set("NeodashRed", { fg = p.red, bg = p.surface })
  set("NeodashCyan", { fg = p.cyan, bg = p.surface })
  set("NeodashCard", { fg = p.text, bg = p.surface })
  set("NeodashCardAlt", { fg = p.muted, bg = p.surface_alt })
  set("NeodashBorder", { fg = p.border, bg = p.surface })
  set("NeodashCardTitle", { fg = p.accent2, bg = p.surface, bold = true })
  set("NeodashKey", { fg = p.text, bg = p.surface_alt, bold = true })
  set("NeodashIcon", { fg = p.accent2, bg = p.surface })
  set("NeodashIconDim", { fg = p.dim, bg = p.surface })
  set("NeodashIconBlue", { fg = p.accent, bg = p.surface })
  set("NeodashIconPurple", { fg = p.accent2, bg = p.surface })
  set("NeodashIconGreen", { fg = p.green, bg = p.surface })
  set("NeodashIconYellow", { fg = p.yellow, bg = p.surface })
  set("NeodashIconRed", { fg = p.red, bg = p.surface })
  set("NeodashIconCyan", { fg = p.cyan, bg = p.surface })

  set("NeodashTagline", { fg = p.muted, bg = bg, italic = true })
  set("NeodashFooter", { fg = p.muted, bg = bg })
  set("NeodashFooterDim", { fg = p.dim, bg = bg })
  set("NeodashFooterAccent", { fg = p.accent, bg = bg })

  local stops = { p.accent, p.accent2, p.accent3 }
  for i = 1, gradient_steps do
    local ratio = (i - 1) / (gradient_steps - 1)
    set("NeodashHeader" .. i, { fg = util.mix(stops, ratio), bg = bg })
  end

  return p
end

return M
