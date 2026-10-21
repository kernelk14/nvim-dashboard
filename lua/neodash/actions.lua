local util = require("neodash.util")

local M = {}

local registry = {}

local function installed(relpath)
  local files = vim.api.nvim_get_runtime_file(relpath, false)
  return #files > 0
end

local pickers = {
  snacks = {
    file = "lua/snacks/picker/init.lua",
    module = "snacks.picker",
    files = "files",
    recent = "recent",
  },
  telescope = {
    file = "lua/telescope/builtin/init.lua",
    module = "telescope.builtin",
    files = "find_files",
    recent = "oldfiles",
  },
  ["fzf-lua"] = {
    file = "lua/fzf-lua/init.lua",
    module = "fzf-lua",
    files = "files",
    recent = "oldfiles",
  },
  ["mini.pick"] = {
    file = "lua/mini/pick/init.lua",
    module = "mini.pick",
    files = "builtin.files",
    recent = "builtin.oldfiles",
  },
}

local picker_order = { "snacks", "telescope", "fzf-lua", "mini.pick" }

local function pick(kind)
  local cfg = require("neodash.config").get()
  local order = picker_order
  if cfg.picker ~= "auto" and pickers[cfg.picker] then
    order = { cfg.picker }
  end
  for _, name in ipairs(order) do
    local picker = pickers[name]
    if picker and installed(picker.file) then
      local ok, mod = pcall(require, picker.module)
      if ok and type(mod) == "table" then
        local target = mod
        for part in picker[kind]:gmatch("[^%.]+") do
          target = target and target[part]
        end
        if type(target) == "function" then
          return (target())
        end
      end
    end
  end
  return nil
end

local function edit(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

function M.open_file(path)
  edit(path)
end

function M.find_files()
  if pick("files") then
    return
  end
  vim.ui.input({ prompt = "Find file: ", completion = "file" }, function(input)
    if input and input ~= "" then
      edit(vim.fn.expand(input))
    end
  end)
end

function M.recent_files()
  if pick("recent") then
    return
  end
  local files = vim.v.oldfiles or {}
  local items = {}
  local seen = {}
  for _, path in ipairs(files) do
    local full = vim.fn.fnamemodify(path, ":p")
    if not seen[full] and vim.fn.filereadable(full) == 1 then
      seen[full] = true
      items[#items + 1] = full
    end
  end
  if #items == 0 then
    util.notify("no recent files yet", vim.log.levels.WARN)
    return
  end
  vim.ui.select(items, { prompt = "Recent files: " }, function(choice)
    if choice then
      edit(choice)
    end
  end)
end

function M.new_file()
  vim.ui.input({ prompt = "New file: ", completion = "file" }, function(input)
    if not input or input == "" then
      return
    end
    local path = vim.fn.expand(input)
    if path:sub(-1) == "/" then
      path = path .. "untitled"
    end
    local dir = vim.fn.fnamemodify(path, ":h")
    if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
    edit(path)
  end)
end

function M.edit_config()
  local dir = vim.fn.stdpath("config")
  local candidates = { dir .. "/init.lua", dir .. "/init.vim", dir .. "/nvim.lua" }
  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then
      edit(path)
      return
    end
  end
  if vim.fn.isdirectory(dir) == 1 then
    edit(dir)
  else
    util.notify("config directory not found", vim.log.levels.WARN)
  end
end

function M.lazy()
  if installed("lua/lazy/init.lua") then
    vim.cmd("Lazy")
  else
    util.notify("lazy.nvim is not installed", vim.log.levels.WARN)
  end
end

function M.explore_cwd()
  edit(vim.fn.getcwd())
end

function M.quit()
  vim.cmd("qa")
end

function M.help()
  local ok = pcall(vim.cmd, "help neodash")
  if not ok then
    util.notify("help file not installed", vim.log.levels.WARN)
  end
end

function M.session_path()
  return vim.fn.stdpath("state") .. "/neodash/session.vim"
end

function M.save_session()
  local path = M.session_path()
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local ok = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(path))
  if ok then
    util.notify("session saved")
  else
    util.notify("could not save session", vim.log.levels.WARN)
  end
end

function M.restore_session()
  local path = M.session_path()
  if vim.fn.filereadable(path) == 1 then
    vim.cmd("source " .. vim.fn.fnameescape(path))
  else
    util.notify("no saved session found", vim.log.levels.WARN)
  end
end

function M.register(name, fn)
  registry[name] = fn
end

function M.resolve(spec)
  if type(spec) == "function" then
    return spec
  end
  if type(spec) == "string" then
    return registry[spec]
  end
  return nil
end

function M.names()
  local keys = {}
  for name in pairs(registry) do
    keys[#keys + 1] = name
  end
  table.sort(keys)
  return keys
end

registry.find_files = M.find_files
registry.recent_files = M.recent_files
registry.new_file = M.new_file
registry.edit_config = M.edit_config
registry.lazy = M.lazy
registry.explore_cwd = M.explore_cwd
registry.quit = M.quit
registry.help = M.help
registry.save_session = M.save_session
registry.restore_session = M.restore_session

return M
