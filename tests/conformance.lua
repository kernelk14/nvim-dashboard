-- Makes sure the vendored palette of the dashboard and the one in neocore
-- agree, so the two plugins never drift apart.
--
-- The core is optional. When it is not on the runtime path only the vendored
-- implementation is checked. Set NEO_CORE_PATH to the checkout of
-- nvim-workbench to compare the two.

local root = vim.fn.getcwd()
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  root .. "/?.lua",
  package.path,
}, ";")
vim.opt.rtp:append(root)

-- The core has to be on the path before the dashboard is loaded, the theme
-- module looks for it while it is being required.
local core_path = vim.env.NEO_CORE_PATH
if core_path and core_path ~= "" then
  package.path = table.concat({
    core_path .. "/lua/?.lua",
    core_path .. "/lua/?/init.lua",
    package.path,
  }, ";")
  vim.opt.rtp:append(core_path)
end

local theme = require("neodash.theme")

local failures = 0
local checks = 0

local function check(name, ok, extra)
  checks = checks + 1
  if ok then
    print("ok   - " .. name)
  else
    failures = failures + 1
    print("FAIL - " .. name .. (extra and ("  (" .. tostring(extra) .. ")") or ""))
  end
end

print("-- the vendored palette")

for _, name in ipairs({ "aurora", "mocha", "nord", "ember", "mono", "daylight" }) do
  local palette = theme.vendored_palette(name)
  check("the theme " .. name .. " has a background", type(palette.bg) == "string", palette.bg)
  check("the theme " .. name .. " has an accent", type(palette.accent) == "string", palette.accent)
end

local transparent = theme.vendored_palette("aurora", true)
check("a transparent palette has no background", transparent.bg == "NONE", transparent.bg)
check("an unknown theme falls back to aurora", theme.vendored_palette("nope").bg == theme.themes.aurora.bg)

-- The highlight groups a colorscheme sets, defined here so the test does not
-- depend on the colorschemes that ship with Neovim, they differ between the
-- versions.
local function use_colors(fg, bg)
  for _, name in ipairs({
    "Normal",
    "Comment",
    "Function",
    "Statement",
    "Constant",
    "Type",
    "String",
    "DiagnosticError",
    "DiagnosticWarn",
    "DiagnosticInfo",
    "DiagnosticOk",
    "DiagnosticHint",
  }) do
    vim.api.nvim_set_hl(0, name, { fg = fg, bg = bg })
  end
end

use_colors("#c9d5f3", "#0b1020")
local dark = theme.vendored_auto_palette()
use_colors("#3f3a33", "#f6f3ec")
local light = theme.vendored_auto_palette()
check("the vendored palette follows the colorscheme", dark.bg ~= light.bg, dark.bg .. " vs " .. light.bg)

print("-- the shared core")

local has_core, core = pcall(require, "neocore.palette")

if not has_core then
  print("skip - neocore is not installed, the two implementations cannot be compared")
else
  check("the dashboard uses the shared core", theme.using_core() == true)

  for _, name in ipairs({ "aurora", "mocha", "nord", "ember", "mono", "daylight" }) do
    check(
      "the theme " .. name .. " matches the core",
      vim.deep_equal(theme.vendored_palette(name), core.palette(name)),
      vim.inspect(theme.vendored_palette(name)) .. " vs " .. vim.inspect(core.palette(name))
    )
  end

  use_colors("#c9d5f3", "#0b1020")
  check(
    "the auto palette matches the core",
    vim.deep_equal(theme.vendored_auto_palette(), core.auto_palette()),
    vim.inspect(theme.vendored_auto_palette()) .. " vs " .. vim.inspect(core.auto_palette())
  )

  check(
    "the palette of the dashboard is the one of the core",
    vim.deep_equal(theme.palette("auto"), core.palette("auto"))
  )
  check("the names match the core", vim.deep_equal(theme.names(), core.names()))
end

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
  vim.cmd("cquit 1")
end
