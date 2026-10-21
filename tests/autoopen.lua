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

local append = string.format("lua vim.opt.rtp:append([[%s]])", root)
local setup = "lua require('neodash').setup()"
local probe = table.concat({
  "lua vim.defer_fn(function()",
  "print('NEODASH_PROBE filetype=' .. vim.bo.filetype .. ' open=' .. tostring(require('neodash').is_open()))",
  "vim.cmd('qa!')",
  "end, 800)",
}, " ")

local function run(extra)
  local args = { "nvim", "--clean", "--headless", "--cmd", append }
  for _, cmd in ipairs(extra or {}) do
    args[#args + 1] = "--cmd"
    args[#args + 1] = cmd
  end
  args[#args + 1] = "--cmd"
  args[#args + 1] = probe
  return vim.fn.system(args)
end

local output = run({ setup })
check("dashboard opens on VimEnter", output:find("NEODASH_PROBE filetype=neodash open=true", 1, true) ~= nil, output)

local output_off = run({ "lua require('neodash').setup({auto_open = false})" })
check("auto_open=false keeps the buffer clean", output_off:find("NEODASH_PROBE filetype= open=false", 1, true) ~= nil, output_off)

print(failures == 0 and "\nautoopen ok" or ("\n" .. failures .. " autoopen failures"))
if failures > 0 then
  vim.cmd("cquit 1")
end
