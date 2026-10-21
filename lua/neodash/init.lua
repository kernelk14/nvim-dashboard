local config = require("neodash.config")
local util = require("neodash.util")

local M = {}

M.config = config

local state = {
  buf = nil,
  win = nil,
  doc = nil,
  ns = nil,
  regions = {},
  winopts = nil,
  timer = nil,
}

local saved_options = {
  "number",
  "relativenumber",
  "signcolumn",
  "foldcolumn",
  "cursorline",
  "wrap",
  "list",
  "spell",
  "colorcolumn",
  "winhighlight",
}

local function window_height()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return math.max(1, vim.api.nvim_win_get_height(state.win))
  end
  local rows = vim.o.lines - vim.o.cmdheight
  if vim.o.laststatus > 0 then
    rows = rows - 1
  end
  return math.max(1, rows)
end

local function save_window_options()
  local win = vim.api.nvim_get_current_win()
  local values = {}
  for _, name in ipairs(saved_options) do
    local ok, value = pcall(vim.api.nvim_get_option_value, name, { win = win })
    if ok then
      values[name] = value
    end
  end
  return { win = win, values = values }
end

local function apply_window_options()
  local win = vim.api.nvim_get_current_win()
  pcall(vim.api.nvim_set_option_value, "number", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "relativenumber", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "signcolumn", "no", { win = win })
  pcall(vim.api.nvim_set_option_value, "foldcolumn", "0", { win = win })
  pcall(vim.api.nvim_set_option_value, "cursorline", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "wrap", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "list", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "spell", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "colorcolumn", "", { win = win })
  pcall(vim.api.nvim_set_option_value, "winhighlight", "Normal:NeodashNormal,NormalNC:NeodashNormal", { win = win })
end

local function restore_window_options()
  local saved = state.winopts
  state.winopts = nil
  if not saved then
    return
  end
  if not vim.api.nvim_win_is_valid(saved.win) then
    return
  end
  for name, value in pairs(saved.values) do
    pcall(vim.api.nvim_set_option_value, name, value, { win = saved.win })
  end
end

local function acquire_buffer()
  local current = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(current)
  if name == "" and vim.bo[current].buftype == "" and not vim.bo[current].modified then
    local lines = vim.api.nvim_buf_get_lines(current, 0, 1, false)
    if #lines == 1 and (lines[1] or "") == "" then
      return current
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  return buf
end

local function render_document(buf)
  local layout = require("neodash.layout")
  local opts = config.get()

  local doc = layout.render(opts, {
    columns = vim.o.columns,
    rows = window_height(),
    on_update = function()
      if state.buf == buf and vim.api.nvim_buf_is_valid(buf) then
        vim.schedule(function()
          M.refresh()
        end)
      end
    end,
  })

  state.doc = doc

  local texts = {}
  for _, line in ipairs(doc.lines) do
    local parts = {}
    for _, seg in ipairs(line.segs or {}) do
      parts[#parts + 1] = seg.text or ""
    end
    texts[#texts + 1] = table.concat(parts)
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(buf, state.ns, 0, -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, texts)

  for index, line in ipairs(doc.lines) do
    local col = 0
    for _, seg in ipairs(line.segs or {}) do
      local text = seg.text or ""
      if seg.hl and text ~= "" then
        vim.api.nvim_buf_set_extmark(buf, state.ns, index - 1, col, {
          end_col = col + #text,
          hl_group = seg.hl,
        })
      end
      col = col + #text
    end
  end

  vim.bo[buf].modifiable = false

  state.regions = {}
  for index, line in ipairs(doc.lines) do
    if line.regions and #line.regions > 0 then
      state.regions[index] = line.regions
    end
  end
end

local function action_lines()
  local lines = {}
  for index = 1, 400 do
    if state.regions[index] then
      lines[#lines + 1] = index
    end
  end
  return lines
end

local function move_cursor(delta)
  local lines = action_lines()
  if #lines == 0 then
    return
  end
  local current = vim.api.nvim_win_get_cursor(0)[1]
  local target = nil
  if delta > 0 then
    for _, line in ipairs(lines) do
      if line > current then
        target = line
        break
      end
    end
    target = target or lines[1]
  else
    for index = #lines, 1, -1 do
      if lines[index] < current then
        target = lines[index]
        break
      end
    end
    target = target or lines[#lines]
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { target, 0 })
end

local function run_at(line)
  for _, region in ipairs(state.regions[line] or {}) do
    if type(region[3]) == "function" then
      region[3]()
      return
    end
  end
end

local function setup_keymaps(buf)
  local opts = config.get()
  local actions = require("neodash.actions")

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true, desc = desc })
  end

  if opts.keys.close and opts.keys.close ~= "" then
    map(opts.keys.close, M.close, "close dashboard")
  end
  if opts.keys.help and opts.keys.help ~= "" then
    map(opts.keys.help, actions.help, "help")
  end
  if opts.keys.refresh and opts.keys.refresh ~= "" then
    map(opts.keys.refresh, M.refresh, "refresh dashboard")
  end

  local items = require("neodash.sections").menu_items(opts)
  for _, item in ipairs(items or {}) do
    if item.key and item.key ~= "" then
      local fn = actions.resolve(item.action)
      if fn then
        map(item.key, fn, item.label)
      end
    end
  end

  map("<LeftMouse>", function()
    local pos = vim.fn.getmousepos()
    if not pos or not pos.line or pos.line == 0 then
      return
    end
    local col = math.max(0, (pos.col or 1) - 1)
    for _, region in ipairs(state.regions[pos.line] or {}) do
      if col >= region[1] and col <= region[2] then
        if type(region[3]) == "function" then
          region[3]()
        end
        return
      end
    end
  end, "click action")

  map("<CR>", function()
    run_at(vim.api.nvim_win_get_cursor(0)[1])
  end, "run action")

  map("j", function()
    move_cursor(1)
  end, "next action")

  map("k", function()
    move_cursor(-1)
  end, "previous action")

  map("<Esc>", M.close, "close dashboard")
end

local function stop_clock()
  if state.timer then
    pcall(function()
      state.timer:stop()
      state.timer:close()
    end)
    state.timer = nil
  end
end

local function update_clock()
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local doc = state.doc
  if not doc or not doc.footer then
    return
  end
  local segs = require("neodash.layout").footer_segs(config.get(), doc.footer.width)
  if not segs then
    return
  end
  local centered = util.center(segs, doc.footer.width)
  local parts = { { text = string.rep(" ", doc.footer.indent) } }
  for _, seg in ipairs(centered) do
    parts[#parts + 1] = seg
  end

  local text = {}
  for _, seg in ipairs(parts) do
    text[#text + 1] = seg.text or ""
  end

  local line = doc.footer.line
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, line - 1, line, false, { table.concat(text) })
  vim.api.nvim_buf_clear_namespace(buf, state.ns, line - 1, line)
  local col = 0
  for _, seg in ipairs(parts) do
    local value = seg.text or ""
    if seg.hl and value ~= "" then
      vim.api.nvim_buf_set_extmark(buf, state.ns, line - 1, col, {
        end_col = col + #value,
        hl_group = seg.hl,
      })
    end
    col = col + #value
  end
  vim.bo[buf].modifiable = false
end

local function start_clock()
  stop_clock()
  local opts = config.get()
  if not (opts.footer and opts.footer.live and opts.footer.show_time) then
    return
  end
  local interval = opts.footer.update_interval or 30000
  state.timer = (vim.uv or vim.loop).new_timer()
  state.timer:start(interval, interval, vim.schedule_wrap(function()
    update_clock()
  end))
end

local function cleanup(buf)
  if state.buf == buf then
    stop_clock()
    restore_window_options()
    state.buf = nil
    state.win = nil
    state.doc = nil
    state.regions = {}
  end
end

function M.setup(opts)
  config.setup(opts)
  local theme = require("neodash.theme")
  theme.apply(config.get().theme, config.get().transparent)

  state.ns = state.ns or vim.api.nvim_create_namespace("neodash")

  local group = vim.api.nvim_create_augroup("Neodash", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      local auto = config.get().auto_open
      if type(auto) == "function" then
        auto = auto()
      end
      if not auto then
        return
      end
      if vim.fn.argc() > 0 then
        return
      end
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      if #lines > 1 or (lines[1] or "") ~= "" then
        return
      end
      vim.schedule(function()
        M.open()
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if state.buf then
        vim.schedule(function()
          M.refresh()
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      if state.buf then
        vim.schedule(function()
          M.refresh()
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if config.get().theme ~= "auto" then
        return
      end
      theme.apply("auto", config.get().transparent)
      if state.buf then
        vim.schedule(function()
          M.refresh()
        end)
      end
    end,
  })

  if config.get().session.autosave then
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = function()
        require("neodash.actions").save_session()
      end,
    })
  end
end

function M.is_open()
  return state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf)
end

function M.open()
  if M.is_open() then
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_set_current_win(state.win)
    end
    return state.buf
  end

  local opts = config.get()
  require("neodash.theme").apply(opts.theme, opts.transparent)

  local buf = acquire_buffer()
  state.buf = buf
  state.ns = state.ns or vim.api.nvim_create_namespace("neodash")

  state.winopts = save_window_options()
  state.win = state.winopts.win
  apply_window_options()

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].undolevels = -1
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "neodash"

  render_document(buf)
  setup_keymaps(buf)

  local buffer_group = vim.api.nvim_create_augroup("NeodashBuffer" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = buffer_group,
    buffer = buf,
    callback = function()
      cleanup(buf)
    end,
  })

  local lines = action_lines()
  if #lines > 0 then
    pcall(vim.api.nvim_win_set_cursor, 0, { lines[1], 0 })
  end

  start_clock()

  if type(opts.on_open) == "function" then
    opts.on_open()
  end

  return buf
end

function M.refresh()
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local cursor = { 1, 0 }
  local ok, pos = pcall(vim.api.nvim_win_get_cursor, 0)
  if ok then
    cursor = pos
  end
  render_document(buf)
  local count = vim.api.nvim_buf_line_count(buf)
  pcall(vim.api.nvim_win_set_cursor, 0, { math.min(cursor[1], count), cursor[2] })
end

function M.close()
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local win = state.win
  if win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() == win then
    vim.cmd("enew")
  else
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.set_theme(name)
  local theme = require("neodash.theme")
  if not vim.tbl_contains(theme.names(), name) then
    util.notify("unknown theme: " .. tostring(name), vim.log.levels.WARN)
    return
  end
  config.get().theme = name
  theme.apply(name, config.get().transparent)
  if M.is_open() then
    M.refresh()
  end
end

function M.register_section(name, spec)
  require("neodash.sections").register(name, spec)
end

function M.session_path()
  return require("neodash.actions").session_path()
end

return M
