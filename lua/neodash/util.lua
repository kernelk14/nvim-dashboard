local M = {}

function M.swidth(text)
  return vim.fn.strdisplaywidth(text or "")
end

function M.truncate(text, width)
  text = text or ""
  if width <= 0 then
    return ""
  end
  if M.swidth(text) <= width then
    return text
  end
  local ellipsis = "…"
  local budget = width - M.swidth(ellipsis)
  if budget <= 0 then
    return ellipsis
  end
  local chars = vim.fn.strchars(text)
  local out = {}
  local used = 0
  for i = 0, chars - 1 do
    local ch = vim.fn.strcharpart(text, i, 1)
    local w = M.swidth(ch)
    if used + w > budget then
      break
    end
    out[#out + 1] = ch
    used = used + w
  end
  return table.concat(out) .. ellipsis
end

function M.norm_segs(value)
  if value == nil then
    return {}
  end
  if type(value) == "string" then
    return { { text = value } }
  end
  if value.text ~= nil then
    return { value }
  end
  return value
end

function M.segs_width(segs)
  local width = 0
  for _, seg in ipairs(segs or {}) do
    width = width + M.swidth(seg.text or "")
  end
  return width
end

function M.segs_bytes(segs)
  local bytes = 0
  for _, seg in ipairs(segs or {}) do
    bytes = bytes + #(seg.text or "")
  end
  return bytes
end

function M.clip_segs(segs, width)
  local out = {}
  local used = 0
  for _, seg in ipairs(segs or {}) do
    if used >= width then
      break
    end
    local w = M.swidth(seg.text or "")
    if used + w <= width then
      out[#out + 1] = seg
      used = used + w
    else
      local text = M.truncate(seg.text or "", width - used)
      if text ~= "" then
        out[#out + 1] = { text = text, hl = seg.hl }
      end
      used = width
    end
  end
  return out
end

function M.row(left, right, width, opts)
  opts = opts or {}
  local l = M.norm_segs(left)
  local r = M.norm_segs(right)
  local lw = M.segs_width(l)
  local rw = M.segs_width(r)
  local gap = width - lw - rw
  if gap < 1 then
    if opts.clip == "right" then
      r = M.clip_segs(r, math.max(0, rw + gap - 1))
      rw = M.segs_width(r)
      gap = width - lw - rw
      if gap < 1 then
        l = M.clip_segs(l, math.max(0, lw + gap - 1))
        lw = M.segs_width(l)
        gap = width - lw - rw
      end
    else
      l = M.clip_segs(l, math.max(0, lw + gap - 1))
      lw = M.segs_width(l)
      gap = width - lw - rw
      if gap < 0 then
        r = M.clip_segs(r, math.max(0, rw + gap))
        rw = M.segs_width(r)
        gap = width - lw - rw
      end
    end
  end
  local segs = {}
  for _, seg in ipairs(l) do
    segs[#segs + 1] = seg
  end
  if gap > 0 then
    segs[#segs + 1] = { text = string.rep(" ", gap) }
  end
  for _, seg in ipairs(r) do
    segs[#segs + 1] = seg
  end
  return segs
end

function M.center(segs, width)
  local used = M.segs_width(segs)
  local left = math.max(0, math.floor((width - used) / 2))
  local out = { { text = string.rep(" ", left) } }
  for _, seg in ipairs(segs or {}) do
    out[#out + 1] = seg
  end
  return out
end

function M.parse_hex(hex)
  hex = tostring(hex):gsub("#", "")
  if #hex == 3 then
    hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
  end
  return {
    tonumber(hex:sub(1, 2), 16) or 0,
    tonumber(hex:sub(3, 4), 16) or 0,
    tonumber(hex:sub(5, 6), 16) or 0,
  }
end

function M.fmt_hex(color)
  return string.format("#%02x%02x%02x", math.floor(color[1] + 0.5), math.floor(color[2] + 0.5), math.floor(color[3] + 0.5))
end

function M.blend(from, to, ratio)
  local a = M.parse_hex(from)
  local b = M.parse_hex(to)
  return M.fmt_hex({
    a[1] + (b[1] - a[1]) * ratio,
    a[2] + (b[2] - a[2]) * ratio,
    a[3] + (b[3] - a[3]) * ratio,
  })
end

function M.mix(stops, ratio)
  if #stops == 1 then
    return stops[1]
  end
  local segments = #stops - 1
  local pos = math.max(0, math.min(1, ratio)) * segments
  local index = math.floor(pos) + 1
  local frac = pos - (index - 1)
  if index >= segments then
    return stops[#stops]
  end
  return M.blend(stops[index], stops[index + 1], frac)
end

function M.is_list(value)
  if type(value) ~= "table" then
    return false
  end
  local count = 0
  for key in pairs(value) do
    if type(key) ~= "number" then
      return false
    end
    count = count + 1
  end
  return count > 0
end

function M.merge(base, override)
  local out = {}
  for key, value in pairs(base) do
    out[key] = type(value) == "table" and vim.deepcopy(value) or value
  end
  for key, value in pairs(override or {}) do
    if type(value) == "table" and type(out[key]) == "table" and not M.is_list(value) and not M.is_list(out[key]) then
      out[key] = M.merge(out[key], value)
    else
      out[key] = type(value) == "table" and vim.deepcopy(value) or value
    end
  end
  return out
end

function M.notify(msg, level)
  vim.notify("neodash: " .. msg, level or vim.log.levels.INFO)
end

return M
