local root = vim.fn.getcwd()
vim.opt.rtp:append(root)
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local columns = tonumber(os.getenv("NEODASH_COLS") or "80")
local rows = tonumber(os.getenv("NEODASH_ROWS") or "24")

local neodash = require("neodash")
local layout = require("neodash.layout")
neodash.setup({ auto_open = false })

local doc = layout.render(neodash.config.get(), { columns = columns, rows = rows })
local out = {}
for _, line in ipairs(doc.lines) do
  local parts = {}
  for _, seg in ipairs(line.segs or {}) do
    parts[#parts + 1] = seg.text or ""
  end
  out[#out + 1] = table.concat(parts)
end
io.write(table.concat(out, "\n"))
io.write("\n")
