local M = {}

local cache = {}

local function parse(stdout)
  local branch
  local changes = 0
  local lines = vim.split(stdout or "", "\n", { plain = true })
  for _, line in ipairs(lines) do
    if line:sub(1, 2) == "##" then
      local name = line:match("^##%s+No commits yet on%s+(%S+)")
      if not name then
        name = line:match("^##%s+([^%s]+)")
      end
      if name then
        branch = name:gsub("%.%..*$", "")
        if branch == "HEAD" then
          branch = "detached HEAD"
        end
      end
    elseif line ~= "" then
      changes = changes + 1
    end
  end
  return { branch = branch, changes = changes }
end

function M.get(cwd, on_update)
  local entry = cache[cwd]
  if
    entry
    and entry.data
    and entry.at
    and (os.time() - entry.at) * 1000 < (require("neodash.config").get().git.ttl or 15000)
  then
    return entry.data
  end
  if not entry then
    entry = {}
    cache[cwd] = entry
  end
  if not entry.inflight then
    entry.inflight = true
    local cmd = { "git", "-C", cwd, "status", "--porcelain=v1", "--branch" }
    local ok = pcall(vim.system, cmd, { text = true }, function(result)
      entry.inflight = false
      entry.at = os.time()
      if result and result.code == 0 then
        entry.data = parse(result.stdout)
      else
        entry.data = { branch = nil, changes = 0, repo = false }
      end
      if on_update then
        vim.schedule(on_update)
      end
    end)
    if not ok then
      entry.inflight = false
      entry.at = os.time()
      entry.data = { branch = nil, changes = 0, repo = false }
    end
  end
  return entry.data
end

function M.clear()
  cache = {}
end

return M
