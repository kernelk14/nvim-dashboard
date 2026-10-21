local util = require("neodash.util")
local data = require("neodash.data")
local git = require("neodash.git")
local icons = require("neodash.icons")
local actions = require("neodash.actions")

local M = {}

local registry = {}

function M.register(name, spec)
  registry[name] = spec
end

function M.get(id, cfg)
  if registry[id] then
    return registry[id]
  end
  local custom = (cfg.sections.custom or {})[id]
  if custom then
    return custom
  end
  return nil
end

function M.menu_items(cfg)
  local items = cfg.menu.items
  if type(items) == "function" then
    items = items({ cfg = cfg })
  end
  items = vim.deepcopy(items or {})

  if cfg.session and cfg.session.enabled then
    local has_session = false
    for _, item in ipairs(items) do
      if item.action == "restore_session" then
        has_session = true
      end
    end
    if not has_session then
      items[#items + 1] = { icon = "󰑮", label = "Resume session", key = "s", action = "restore_session" }
    end
  end

  return items
end

local function menu(ctx)
  local cfg = ctx.cfg
  local items = M.menu_items(cfg)
  local lines = {}
  for _, item in ipairs(items or {}) do
    local enabled = item.enabled
    if enabled == nil then
      enabled = true
    end
    if type(enabled) == "function" then
      enabled = enabled(ctx)
    end
    if enabled then
      local left = {
        { text = item.icon or "", hl = "NeodashIcon" },
        { text = "  " },
        { text = item.label or "", hl = "NeodashText" },
      }
      local right = nil
      if item.key and item.key ~= "" then
        right = { { text = " " .. item.key .. " ", hl = "NeodashKey" } }
      end
      local action = actions.resolve(item.action)
      lines[#lines + 1] = {
        segs = util.row(left, right, ctx.inner),
        action = action,
        key = item.key,
      }
    end
  end
  return {
    title = cfg.menu.title,
    icon = cfg.menu.icon,
    lines = lines,
  }
end

local function project(ctx)
  local cfg = ctx.cfg
  local info = data.project()
  local lines = {}

  lines[#lines + 1] = {
    segs = {
      { text = info.name, hl = "NeodashTitle" },
    },
  }

  if cfg.project.show_path then
    lines[#lines + 1] = {
      segs = util.row({ { text = info.path, hl = "NeodashDim" } }, nil, ctx.inner),
    }
  end

  if cfg.git.enabled then
    local status = git.get(info.cwd, ctx.on_update)
    if status and status.branch then
      local left = {
        { text = " ", hl = "NeodashIcon" },
        { text = status.branch, hl = "NeodashText" },
      }
      local right = nil
      if status.changes > 0 then
        right = { { text = "● " .. status.changes .. " changed", hl = "NeodashYellow" } }
      else
        right = { { text = "✓ clean", hl = "NeodashGreen" } }
      end
      if util.segs_width(left) + util.segs_width(right) + 3 > ctx.inner then
        right = nil
      end
      lines[#lines + 1] = {
        segs = util.row(left, right, ctx.inner, { clip = "right" }),
      }
    elseif status then
      lines[#lines + 1] = {
        segs = { { text = "not a git repository", hl = "NeodashDim" } },
      }
    else
      lines[#lines + 1] = {
        segs = { { text = "checking repository…", hl = "NeodashDim" } },
      }
    end
  end

  return {
    title = cfg.project.title,
    icon = cfg.project.icon,
    lines = lines,
  }
end

local function recent(ctx)
  local cfg = ctx.cfg
  local limit = ctx.limit or cfg.recent.limit
  local files = data.recent(limit, cfg.recent.exclude or {}, ctx.oldfiles)
  local lines = {}

  if #files == 0 then
    lines[#lines + 1] = {
      segs = { { text = "no recent files yet", hl = "NeodashDim" } },
    }
  else
    for _, file in ipairs(files) do
      local left = {
        { text = icons.glyph(file.path), hl = icons.group(file.path) },
        { text = "  " },
        { text = file.name, hl = "NeodashText" },
      }
      local right = nil
      if cfg.recent.show_time then
        right = { { text = data.rel_time(file.mtime), hl = "NeodashMuted" } }
      end
      if cfg.recent.show_parent and file.dir ~= "" then
        local parent = { { text = "  " .. file.dir, hl = "NeodashDim" } }
        if util.segs_width(left) + util.segs_width(parent) + util.segs_width(right) + 2 <= ctx.inner then
          left[#left + 1] = parent[1]
        end
      end
      lines[#lines + 1] = {
        segs = util.row(left, right, ctx.inner, { clip = "right" }),
        action = function()
          actions.open_file(file.path)
        end,
      }
    end
  end

  return {
    title = cfg.recent.title,
    icon = cfg.recent.icon,
    lines = lines,
  }
end

registry.menu = { render = menu }
registry.project = { render = project }
registry.recent = { render = recent }

return M
