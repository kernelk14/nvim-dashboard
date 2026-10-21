local util = require("neodash.util")

local M = {}

M.defaults = {
  auto_open = true,
  max_width = 100,
  padding = 2,
  gap = 3,
  theme = "aurora",
  transparent = false,
  two_column = true,
  min_two_column_width = 48,
  max_single_width = 50,
  date_format = "%a, %b %d",
  time_format = "%H:%M",
  header = {
    style = "auto",
    tagline = "make something wonderful",
    art = nil,
    gradient = true,
  },
  footer = {
    enabled = true,
    show_date = true,
    show_time = true,
    show_version = true,
    show_hint = true,
    live = true,
    update_interval = 30000,
  },
  keys = {
    close = "q",
    help = "?",
    refresh = "R",
  },
  menu = {
    title = "Actions",
    icon = "󰘳",
    items = {
      { icon = "󰈞", label = "Find file", key = "f", action = "find_files" },
      { icon = "󰝒", label = "New file", key = "n", action = "new_file" },
      { icon = "󰋚", label = "Recent files", key = "r", action = "recent_files" },
      { icon = "󰒓", label = "Open config", key = ",", action = "edit_config" },
      { icon = "󰅚", label = "Quit Neovim", key = "q", action = "quit" },
    },
  },
  recent = {
    title = "Recent",
    icon = "󰋚",
    limit = 5,
    show_time = true,
    show_parent = true,
    exclude = {},
  },
  project = {
    title = "Project",
    icon = "󰉋",
    show_path = true,
  },
  sections = {
    left = { "menu" },
    right = { "project", "recent" },
    bottom = {},
    custom = {},
  },
  git = {
    enabled = true,
    ttl = 15000,
  },
  picker = "auto",
  session = {
    enabled = false,
    autosave = false,
  },
  on_open = nil,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = util.merge(M.defaults, opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M
