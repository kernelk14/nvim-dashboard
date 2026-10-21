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

local data = require("neodash.data")
local layout = require("neodash.layout")
local neodash = require("neodash")

neodash.setup({ auto_open = false })

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/nested", "p")
vim.fn.writefile({ "x" }, tmp .. "/alpha.lua")
vim.fn.writefile({ "x" }, tmp .. "/nested/beta.lua")

local files = data.recent(5, {}, { tmp .. "/alpha.lua", tmp .. "/nested/beta.lua", tmp .. "/missing.lua" })
check("recent finds existing files", #files == 2, #files)
check("recent keeps the order", files[1] and files[1].name == "alpha.lua", files[1] and files[1].name)
check(
  "recent reports the parent",
  files[1] and files[1].dir == tmp:match("[^\\/]+$") or false,
  files[1] and files[1].dir
)
check("recent skips missing files", not vim.iter(files):any(function(f)
  return f.name == "missing.lua"
end))

local excluded = data.recent(5, { "alpha" }, { tmp .. "/alpha.lua", tmp .. "/nested/beta.lua" })
check("recent honours excludes", #excluded == 1, #excluded)

local doc = layout.render(neodash.config.get(), {
  columns = 100,
  rows = 30,
  oldfiles = { tmp .. "/alpha.lua", tmp .. "/nested/beta.lua" },
})
local text = {}
for _, line in ipairs(doc.lines) do
  local parts = {}
  for _, seg in ipairs(line.segs or {}) do
    parts[#parts + 1] = seg.text or ""
  end
  text[#text + 1] = table.concat(parts)
end
check(
  "recent file is listed",
  vim.iter(text):any(function(l)
    return l:find("alpha.lua", 1, true) ~= nil
  end)
)
check(
  "recent file is clickable",
  vim.iter(doc.lines):any(function(line)
    if line.regions and line.regions[1] then
      local parts = {}
      for _, seg in ipairs(line.segs or {}) do
        parts[#parts + 1] = seg.text or ""
      end
      return table.concat(parts):find("alpha.lua", 1, true) ~= nil
    end
    return false
  end)
)

print(failures == 0 and "\nrecent ok" or ("\n" .. failures .. " recent failures"))
if failures > 0 then
  vim.cmd("cquit 1")
end
