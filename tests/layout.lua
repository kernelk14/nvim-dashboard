local root = vim.fn.getcwd()
vim.opt.rtp:append(root)
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local neodash = require("neodash")
local layout = require("neodash.layout")
local util = require("neodash.util")

neodash.setup({ auto_open = false })

local failures = 0

local function check(name, ok, extra)
  if ok then
    print("ok   - " .. name)
  else
    failures = failures + 1
    print("FAIL - " .. name .. (extra and ("  (" .. tostring(extra) .. ")") or ""))
  end
end

local sizes = {
  { columns = 40, rows = 12 },
  { columns = 60, rows = 20 },
  { columns = 80, rows = 24 },
  { columns = 100, rows = 30 },
  { columns = 120, rows = 40 },
  { columns = 200, rows = 60 },
}

for _, size in ipairs(sizes) do
  local doc = layout.render(neodash.config.get(), { columns = size.columns, rows = size.rows })
  local widest = 0
  for _, line in ipairs(doc.lines) do
    widest = math.max(widest, util.segs_width(line.segs or {}))
  end
  local label = size.columns .. "x" .. size.rows
  check("fits width " .. label, widest <= size.columns, widest)
  check("fits height " .. label, #doc.lines <= size.rows, #doc.lines)
end

local doc = layout.render(neodash.config.get(), { columns = 80, rows = 24 })
local text = {}
for _, line in ipairs(doc.lines) do
  local parts = {}
  for _, seg in ipairs(line.segs or {}) do
    parts[#parts + 1] = seg.text or ""
  end
  text[#text + 1] = table.concat(parts)
end
check("cards are rendered", vim.iter(text):any(function(l)
  return l:find("Actions", 1, true) ~= nil
end))
check("cards are aligned", vim.iter(text):any(function(l)
  return l:find("│") ~= nil
end))

local region_ok = false
for _, line in ipairs(doc.lines) do
  local parts = {}
  for _, seg in ipairs(line.segs or {}) do
    parts[#parts + 1] = seg.text or ""
  end
  local joined = table.concat(parts)
  local at = joined:find("Find file", 1, true)
  if at and line.regions and line.regions[1] then
    local region = line.regions[1]
    region_ok = at - 1 >= region[1] and (at - 1) < region[2]
  end
end
check("click region covers the label", region_ok)

print(failures == 0 and "\nlayout ok" or ("\n" .. failures .. " layout failures"))
if failures > 0 then
  vim.cmd("cquit 1")
end
