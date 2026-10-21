local M = {}

function M.rel_time(sec)
  if not sec then
    return ""
  end
  local delta = os.time() - sec
  if delta < 0 then
    delta = 0
  end
  if delta < 60 then
    return "now"
  end
  if delta < 3600 then
    return math.floor(delta / 60) .. "m"
  end
  if delta < 86400 then
    return math.floor(delta / 3600) .. "h"
  end
  if delta < 604800 then
    return math.floor(delta / 86400) .. "d"
  end
  return os.date("%b %d", sec)
end

function M.recent(limit, exclude, oldfiles)
  local out = {}
  local seen = {}
  oldfiles = oldfiles or vim.v.oldfiles or {}
  exclude = exclude or {}
  for _, raw in ipairs(oldfiles) do
    if #out >= limit then
      break
    end
    local path = vim.fn.fnamemodify(raw, ":p")
    if path ~= "" and not seen[path] and vim.fn.filereadable(path) == 1 and vim.fn.isdirectory(path) == 0 then
      local skip = false
      for _, pattern in ipairs(exclude) do
        if path:find(pattern, 1, true) then
          skip = true
          break
        end
      end
      if not skip then
        seen[path] = true
        local stat = (vim.uv or vim.loop).fs_stat(path)
        out[#out + 1] = {
          path = path,
          name = vim.fn.fnamemodify(path, ":t"),
          dir = vim.fn.fnamemodify(path, ":h:t"),
          mtime = stat and stat.mtime and stat.mtime.sec or nil,
        }
      end
    end
  end
  return out
end

function M.project()
  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")
  if name == "" or name == "." then
    name = cwd
  end
  local path = vim.fn.fnamemodify(cwd, ":~")
  if path == "" then
    path = cwd
  end
  return { name = name, path = path, cwd = cwd }
end

return M
