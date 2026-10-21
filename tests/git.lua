local root = vim.fn.getcwd()
vim.opt.rtp:append(root)
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
vim.fn.system({ "git", "-C", tmp, "init", "-q" })
vim.fn.system({ "git", "-C", tmp, "config", "user.email", "test@example.com" })
vim.fn.system({ "git", "-C", tmp, "config", "user.name", "Test" })
vim.fn.writefile({ "print('hi')" }, tmp .. "/main.lua")
vim.fn.system({ "git", "-C", tmp, "add", "." })
vim.fn.system({ "git", "-C", tmp, "commit", "-q", "-m", "init" })
vim.fn.system({ "git", "-C", tmp, "branch", "-m", "feature/dashboard" })
vim.fn.writefile({ "print('changed')" }, tmp .. "/main.lua")

vim.cmd("cd " .. vim.fn.fnameescape(tmp))

local neodash = require("neodash")
neodash.setup({ auto_open = false })
neodash.open()

local function buffer_text()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

print("before wait:")
print(buffer_text())

vim.wait(3000, function()
  return buffer_text():find("feature/dashboard", 1, true) ~= nil
end, 50)

print("after wait:")
print(buffer_text())

local ok = buffer_text():find("feature/dashboard", 1, true) ~= nil
print("git branch detected: " .. tostring(ok))
print("dirty marker: " .. tostring(buffer_text():find("changed", 1, true) ~= nil))
if not ok then
  vim.cmd("cquit 1")
end
print("\ngit ok")
