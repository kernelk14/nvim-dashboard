local M = {}

local health = vim.health or require("health")

local function check_git()
  if vim.fn.executable("git") == 1 then
    health.ok("git executable found")
  else
    health.warn("git executable not found", { "The project card will not show branch information" })
  end
end

local function check_picker()
  local found = false
  for _, name in ipairs({ "snacks", "telescope", "fzf-lua", "mini.pick" }) do
    local file = ({
      ["snacks"] = "lua/snacks/picker/init.lua",
      ["telescope"] = "lua/telescope/builtin/init.lua",
      ["fzf-lua"] = "lua/fzf-lua/init.lua",
      ["mini.pick"] = "lua/mini/pick/init.lua",
    })[name]
    if #vim.api.nvim_get_runtime_file(file, false) > 0 then
      health.ok("file picker available: " .. name)
      found = true
    end
  end
  if not found then
    health.info("no file picker found", { "neodash falls back to a plain prompt" })
  end
end

function M.check()
  health.start("neodash")

  if vim.fn.has("nvim-0.10") == 1 then
    health.ok("neovim version is supported")
  else
    health.error("neovim 0.10 or newer is required")
  end

  local theme = require("neodash.theme")
  health.ok("themes available: " .. table.concat(theme.names(), ", "))

  check_git()
  check_picker()
end

return M
