local root = vim.fn.getcwd()
vim.opt.rtp:append(root)
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

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

local neodash = require("neodash")

local number_before = vim.wo.number
local highlight_before = vim.wo.winhighlight

neodash.setup({ auto_open = false, footer = { update_interval = 150 } })
neodash.open()

local buf = vim.api.nvim_get_current_buf()
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

check("dashboard buffer is active", vim.api.nvim_get_current_buf() == buf)
check("filetype is neodash", vim.bo[buf].filetype == "neodash", vim.bo[buf].filetype)
check("buffer is not modifiable", vim.bo[buf].modifiable == false)
check("buffer is not listed", vim.bo[buf].buflisted == false)
check("rendered lines exist", #lines > 5, #lines)
check("contains actions card", vim.iter(lines):any(function(l)
  return l:find("Actions", 1, true) ~= nil
end))
check("contains recent card", vim.iter(lines):any(function(l)
  return l:find("Recent", 1, true) ~= nil
end))
check("contains footer", vim.iter(lines):any(function(l)
  return l:find("neovim", 1, true) ~= nil
end))
check("no unknown option markers", not vim.iter(lines):any(function(l)
  return l:find("E%d+:") ~= nil
end))

vim.wait(700)
local clock_after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
check("live clock keeps the buffer stable", #clock_after == #lines, #clock_after .. " vs " .. #lines)
check("live clock keeps the footer", vim.iter(clock_after):any(function(l)
  return l:find("neovim", 1, true) ~= nil
end))

local function has_map(lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if map.lhs == lhs then
      return true
    end
  end
  return false
end

local function find_map(lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if map.lhs == lhs then
      return map
    end
  end
end

check("menu keymap f", has_map("f"))
check("menu keymap n", has_map("n"))
check("menu keymap r", has_map("r"))
check("help keymap", has_map("?"))
check("refresh keymap", has_map("R"))
check("click handler", has_map("<LeftMouse>"))

local jmap = find_map("j")
check("j has a callback", jmap ~= nil and type(jmap.callback) == "function")
if jmap and type(jmap.callback) == "function" then
  local before = vim.api.nvim_win_get_cursor(0)[1]
  jmap.callback()
  local after = vim.api.nvim_win_get_cursor(0)[1]
  check("j moves to the next action", after > before, before .. " -> " .. after)
  local kmap = find_map("k")
  kmap.callback()
  check("k moves back", vim.api.nvim_win_get_cursor(0)[1] == before)
end

local state_regions = 0
for _, line in ipairs(lines) do
  state_regions = state_regions
end

neodash.refresh()
local after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
check("refresh keeps the buffer alive", vim.api.nvim_buf_is_valid(buf))
check("refresh is stable", #after == #lines, #after .. " vs " .. #lines)

neodash.set_theme("mocha")
check("theme switch keeps rendering", vim.api.nvim_buf_line_count(buf) > 0)
neodash.set_theme("invalid-theme-should-not-exist")
check("unknown theme is rejected", neodash.config.get().theme == "mocha", neodash.config.get().theme)

neodash.register_section("custom_demo", {
  title = "Custom",
  icon = "◆",
  lines = { { segs = { { text = "custom line", hl = "NeodashText" } } } },
})
neodash.config.get().sections.right = { "project", "recent", "custom_demo" }
neodash.refresh()
local with_custom = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
check("custom section renders", vim.iter(with_custom):any(function(l)
  return l:find("custom line", 1, true) ~= nil
end))
neodash.config.get().sections.right = { "project", "recent" }

vim.cmd("colorscheme habamax")
neodash.set_theme("auto")
neodash.refresh()
local auto_hl = vim.api.nvim_get_hl(0, { name = "NeodashNormal" })
check("auto theme derives a background", auto_hl.bg ~= nil, vim.inspect(auto_hl))
check("auto theme keeps rendering", vim.api.nvim_buf_line_count(buf) > 0)

vim.cmd("colorscheme morning")
neodash.set_theme("auto")
local light_hl = vim.api.nvim_get_hl(0, { name = "NeodashNormal" })
check("auto theme follows light colorschemes", light_hl.bg ~= nil, vim.inspect(light_hl))
neodash.set_theme("aurora")

neodash.close()
check("dashboard closes", not neodash.is_open())
check("closing restores the window", vim.wo.number == number_before, tostring(vim.wo.number) .. " vs " .. tostring(number_before))
check("closing restores winhighlight", vim.wo.winhighlight == highlight_before, vim.wo.winhighlight)

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
  vim.cmd("cquit 1")
end
