local root = vim.fn.getcwd()
vim.opt.rtp:append(root)
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local failures = 0

local function check(name, ok, extra)
  if ok then
    print("ok   - " .. name)
  else
    failures = failures + 1
    print("FAIL - " .. name .. (extra and ("  (" .. tostring(extra) .. ")") or ""))
  end
end

local neodash = require("neodash")
local actions = require("neodash.actions")

neodash.setup({ auto_open = false, session = { enabled = true } })
neodash.open()

local buf = vim.api.nvim_get_current_buf()
local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
check("session entry is rendered", text:find("Resume session", 1, true) ~= nil)

local has_key = false
for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
  if map.lhs == "s" then
    has_key = true
  end
end
check("session shortcut is mapped", has_key)

local path = actions.session_path()
check("session path is in the state dir", path:find("neodash", 1, true) ~= nil, path)
vim.fn.delete(path)
check("session is not created yet", vim.fn.filereadable(path) == 0)

actions.save_session()
check("session is saved", vim.fn.filereadable(path) == 1, path)
check("session file has content", vim.fn.getfsize(path) > 0)

neodash.close()
check("closing stops the clock", true)

vim.fn.delete(path)

print(failures == 0 and "\nsession ok" or ("\n" .. failures .. " session failures"))
if failures > 0 then
  vim.cmd("cquit 1")
end
