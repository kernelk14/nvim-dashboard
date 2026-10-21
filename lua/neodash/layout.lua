local util = require("neodash.util")
local sections = require("neodash.sections")

local M = {}

local ART = {
  "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
  "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
  "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
  "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
  "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
  "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
}

local gradient_steps = 12

local function gradient_segs(text, row_ratio)
  local segs = {}
  if text == nil or text == "" then
    return segs
  end
  local chars = vim.fn.strchars(text)
  local current
  local buf = {}
  for i = 0, chars - 1 do
    local ch = vim.fn.strcharpart(text, i, 1)
    local ratio = (i / math.max(1, chars - 1)) * 0.65 + row_ratio * 0.35
    local index = math.floor(ratio * gradient_steps + 0.5) + 1
    if index < 1 then
      index = 1
    elseif index > gradient_steps then
      index = gradient_steps
    end
    local hl = "NeodashHeader" .. index
    if hl ~= current then
      if current then
        segs[#segs + 1] = { text = table.concat(buf), hl = current }
      end
      current = hl
      buf = {}
    end
    buf[#buf + 1] = ch
  end
  if current then
    segs[#segs + 1] = { text = table.concat(buf), hl = current }
  end
  return segs
end

local function flat_segs(text, hl)
  return { { text = text, hl = hl } }
end

local function build_header(cfg, width, rows, style)
  local header = cfg.header or {}
  local lines = {}

  if style == "none" then
    return lines
  end

  local tagline = header.tagline
  local art = header.art or ART

  if style == "art" then
    local width_of_art = 0
    for _, line in ipairs(art) do
      width_of_art = math.max(width_of_art, util.swidth(line))
    end
    if width_of_art > width then
      style = "compact"
    else
      for index, line in ipairs(art) do
        local ratio = #art > 1 and (index - 1) / (#art - 1) or 0
        local segs = header.gradient == false and flat_segs(line, "NeodashHeader6") or gradient_segs(line, ratio)
        lines[#lines + 1] = { segs = segs }
      end
      if rows >= 26 and tagline and tagline ~= "" and util.swidth(tagline) + 8 <= width then
        lines[#lines + 1] = { segs = flat_segs("·  " .. tagline .. "  ·", "NeodashTagline") }
      end
      return lines
    end
  end

  if style == "compact" then
    local word = "N E O V I M"
    local segs = { { text = "◆  ", hl = "NeodashFooterAccent" } }
    for _, seg in ipairs(header.gradient == false and flat_segs(word, "NeodashHeader6") or gradient_segs(word, 0)) do
      segs[#segs + 1] = seg
    end
    segs[#segs + 1] = { text = "  ◆", hl = "NeodashFooterAccent" }
    lines[#lines + 1] = { segs = segs }
    if tagline and tagline ~= "" and util.swidth(tagline) + 14 <= width and rows >= 17 then
      lines[#lines + 1] = { segs = flat_segs("──  " .. tagline .. "  ──", "NeodashTagline") }
    end
    return lines
  end

  local segs = {}
  for _, seg in ipairs(header.gradient == false and flat_segs("NEOVIM", "NeodashHeader6") or gradient_segs("NEOVIM", 0)) do
    segs[#segs + 1] = seg
  end
  if tagline and tagline ~= "" and util.swidth(tagline) + 16 <= width then
    segs[#segs + 1] = { text = "  ·  " .. tagline, hl = "NeodashTagline" }
  end
  lines[#lines + 1] = { segs = segs }
  return lines
end

local function build_footer(cfg, width)
  local footer = cfg.footer or {}
  if not footer.enabled then
    return {}
  end

  local items = {}
  if footer.show_time then
    items[#items + 1] = { { text = "󰥔 ", hl = "NeodashFooterAccent" }, { text = os.date(cfg.time_format), hl = "NeodashFooter" } }
  end
  if footer.show_date then
    items[#items + 1] = { { text = "󰃭 ", hl = "NeodashFooterAccent" }, { text = os.date(cfg.date_format), hl = "NeodashFooter" } }
  end
  if footer.show_version then
    local version = vim.version()
    items[#items + 1] = {
      { text = "neovim ", hl = "NeodashFooterDim" },
      { text = version.major .. "." .. version.minor .. "." .. version.patch, hl = "NeodashFooter" },
    }
  end
  if footer.show_hint then
    items[#items + 1] = { { text = "press ? for help", hl = "NeodashFooterDim" } }
  end

  local separator = { { text = "   ·   ", hl = "NeodashFooterDim" } }

  local function join(list)
    local segs = {}
    for index, item in ipairs(list) do
      if index > 1 then
        for _, seg in ipairs(separator) do
          segs[#segs + 1] = seg
        end
      end
      for _, seg in ipairs(item) do
        segs[#segs + 1] = seg
      end
    end
    return segs
  end

  while #items > 1 and util.segs_width(join(items)) > width do
    table.remove(items)
  end

  if #items == 0 or util.segs_width(join(items)) > width then
    return nil
  end

  return join(items)
end

M.footer_segs = build_footer

local function card_lines(spec, inner)
  local total = inner + 4
  local out = {}

  local title = spec.title or ""
  local icon = spec.icon or ""

  local top = { { text = "╭─", hl = "NeodashBorder" } }
  if icon ~= "" then
    top[#top + 1] = { text = " " .. icon, hl = "NeodashIcon" }
  end
  if title ~= "" then
    top[#top + 1] = { text = " " .. title, hl = "NeodashCardTitle" }
    top[#top + 1] = { text = " ", hl = "NeodashCard" }
  end
  local used = util.segs_width(top)
  if used > total - 3 then
    top = { { text = "╭─", hl = "NeodashBorder" } }
    top[#top + 1] = { text = " " .. util.truncate(title, math.max(1, total - 7)), hl = "NeodashCardTitle" }
    top[#top + 1] = { text = " ", hl = "NeodashCard" }
    used = util.segs_width(top)
  end
  top[#top + 1] = { text = string.rep("─", math.max(0, total - used - 1)), hl = "NeodashBorder" }
  top[#top + 1] = { text = "╮", hl = "NeodashBorder" }
  out[#out + 1] = { segs = top }

  for _, line in ipairs(spec.lines or {}) do
    local segs = util.clip_segs(util.norm_segs(line.segs or line), inner)
    local content_width = util.segs_width(segs)
    local pad = math.max(0, inner - content_width)
    local parts = {
      { text = "│", hl = "NeodashBorder" },
      { text = " ", hl = "NeodashCard" },
    }
    for _, seg in ipairs(segs) do
      parts[#parts + 1] = { text = seg.text, hl = seg.hl or "NeodashText" }
    end
    parts[#parts + 1] = { text = string.rep(" ", pad), hl = "NeodashCard" }
    parts[#parts + 1] = { text = " ", hl = "NeodashCard" }
    parts[#parts + 1] = { text = "│", hl = "NeodashBorder" }

    local part = { segs = parts }
    if line.action then
      local start = 4
      part.regions = { { start, start + util.segs_bytes(segs), line.action } }
    end
    out[#out + 1] = part
  end

  out[#out + 1] = {
    segs = { { text = "╰" .. string.rep("─", math.max(0, total - 2)) .. "╯", hl = "NeodashBorder" } },
  }

  return out
end

local function join_parts(parts)
  local segs = {}
  local regions = {}
  local offset = 0
  for _, part in ipairs(parts) do
    for _, seg in ipairs(part.segs or {}) do
      segs[#segs + 1] = seg
    end
    if part.regions then
      for _, region in ipairs(part.regions) do
        regions[#regions + 1] = { region[1] + offset, region[2] + offset, region[3] }
      end
    end
    offset = offset + util.segs_bytes(part.segs or {})
  end
  return { segs = segs, regions = regions }
end

local function pad_part(part, width)
  local used = util.segs_width(part.segs or {})
  if used >= width then
    return part
  end
  return join_parts({ part, { segs = { { text = string.rep(" ", width - used) } } } })
end

local function build_group(ids, width, ctx)
  local out = {}
  local inner = math.max(8, width - 4)
  for index, id in ipairs(ids or {}) do
    local spec = sections.get(id, ctx.cfg)
    if spec then
      local sctx = vim.tbl_extend("force", ctx, { inner = inner })
      local ok, res
      if type(spec.render) == "function" then
        ok, res = pcall(spec.render, sctx)
      else
        ok, res = true, spec
      end
      if ok and type(res) == "table" then
        if res.title == nil then
          res.title = spec.title
        end
        if res.icon == nil then
          res.icon = spec.icon
        end
        if not res.lines and spec.lines then
          res.lines = spec.lines
        end
        if index > 1 then
          out[#out + 1] = { segs = {} }
        end
        for _, line in ipairs(card_lines(res, inner)) do
          out[#out + 1] = line
        end
      end
    end
  end
  return out
end

local function build(cfg, size, style, limit, dropped)
  local columns = size.columns
  local rows = size.rows
  local width = math.max(28, math.min(cfg.max_width, columns - cfg.padding * 2))
  local gap = math.max(1, cfg.gap)
  local parts = {}

  local header = build_header(cfg, width, rows, style)
  for _, line in ipairs(header) do
    parts[#parts + 1] = { segs = util.center(line.segs, width) }
  end
  if #header > 0 then
    parts[#parts + 1] = { segs = {} }
  end

  local ctx = { cfg = cfg, limit = limit, on_update = size.on_update, oldfiles = size.oldfiles }

  local left_ids = cfg.sections.left or {}
  local right_ids = cfg.sections.right or {}
  dropped = dropped or 0

  local visible_right = {}
  for index, id in ipairs(right_ids) do
    if index <= #right_ids - dropped then
      visible_right[#visible_right + 1] = id
    end
  end

  local two_column = cfg.two_column and #left_ids > 0 and #visible_right > 0 and width >= cfg.min_two_column_width
  local left_width = math.max(24, math.min(44, math.floor(width * 0.4)))
  local right_width = width - left_width - gap
  if right_width < 22 then
    two_column = false
  else
    right_width = math.min(right_width, math.max(40, math.floor(width * 0.42)))
  end

  if two_column then
    local left = build_group(left_ids, left_width, ctx)
    local right = build_group(visible_right, right_width, ctx)
    local height = math.max(#left, #right)
    local group_indent = math.max(0, math.floor((width - (left_width + gap + right_width)) / 2))
    for index = 1, height do
      local left_part = pad_part(left[index] or { segs = {} }, left_width)
      local right_part = pad_part(right[index] or { segs = {} }, right_width)
      parts[#parts + 1] = join_parts({
        { segs = { { text = string.rep(" ", group_indent) } } },
        left_part,
        { segs = { { text = string.rep(" ", gap) } } },
        right_part,
      })
    end
  else
    local ids = {}
    for _, id in ipairs(left_ids) do
      ids[#ids + 1] = id
    end
    for _, id in ipairs(visible_right) do
      ids[#ids + 1] = id
    end
    local card_width = math.min(width, cfg.max_single_width)
    local block = build_group(ids, card_width, ctx)
    local indent = math.floor((width - card_width) / 2)
    for _, part in ipairs(block) do
      parts[#parts + 1] = join_parts({ { segs = { { text = string.rep(" ", indent) } } }, part })
    end
  end

  local bottom_ids = cfg.sections.bottom or {}
  if #bottom_ids > 0 then
    parts[#parts + 1] = { segs = {} }
    local bottom = build_group(bottom_ids, width, ctx)
    for _, part in ipairs(bottom) do
      parts[#parts + 1] = part
    end
  end

  local footer = build_footer(cfg, width)
  if footer then
    parts[#parts + 1] = { segs = {} }
    parts[#parts + 1] = { segs = util.center(footer, width), footer = true }
  end

  return parts
end

function M.render(cfg, size)
  local columns = size.columns
  local rows = size.rows
  local width = math.max(28, math.min(cfg.max_width, columns - cfg.padding * 2))

  local style = cfg.header.style or "auto"
  local auto = style == "auto"
  if auto then
    local art_width = 0
    for _, line in ipairs(cfg.header.art or ART) do
      art_width = math.max(art_width, util.swidth(line))
    end
    if width >= art_width + 2 and rows >= 20 then
      style = "art"
    elseif width >= 34 and rows >= 14 then
      style = "compact"
    else
      style = "text"
    end
  end

  local limit = math.max(1, cfg.recent.limit or 5)
  local dropped = 0
  local footer = nil
  local parts = build(cfg, size, style, limit, dropped)

  local guard = 0
  while #parts > rows and guard < 20 do
    guard = guard + 1
    if limit > 1 then
      limit = limit - 1
    elseif auto and style == "art" then
      style = "compact"
    elseif auto and style == "compact" then
      style = "text"
    elseif auto and style == "text" then
      style = "none"
    elseif dropped < #(cfg.sections.right or {}) then
      dropped = dropped + 1
    else
      break
    end
    parts = build(cfg, size, style, limit, dropped)
  end

  local indent = math.max(0, math.floor((columns - width) / 2))
  local height = #parts
  local top = math.max(0, math.floor((rows - height) / 2))
  local bottom = math.max(0, rows - height - top)

  local lines = {}
  for _ = 1, top do
    lines[#lines + 1] = { segs = {} }
  end
  for _, part in ipairs(parts) do
    local joined = join_parts({ { segs = { { text = string.rep(" ", indent) } } }, part })
    if part.footer then
      footer = { line = #lines + 1, indent = indent, width = width }
    end
    lines[#lines + 1] = joined
  end
  for _ = 1, bottom do
    lines[#lines + 1] = { segs = {} }
  end

  return { lines = lines, width = width, footer = footer }
end

return M
