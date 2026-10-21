local M = {}

local by_ext = {
  lua = { "󰢱", "NeodashIconPurple" },
  js = { "󰌞", "NeodashIconYellow" },
  jsx = { "󰜽", "NeodashIconCyan" },
  ts = { "󰛦", "NeodashIconBlue" },
  tsx = { "󰛦", "NeodashIconBlue" },
  py = { "󰌠", "NeodashIconGreen" },
  go = { "󰟓", "NeodashIconCyan" },
  rs = { "󰌾", "NeodashIconRed" },
  rb = { "󰜹", "NeodashIconRed" },
  c = { "󰲋", "NeodashIconBlue" },
  h = { "󰋢", "NeodashIconBlue" },
  cpp = { "󰼭", "NeodashIconBlue" },
  cs = { "󰌛", "NeodashIconGreen" },
  java = { "󰗫", "NeodashIconRed" },
  php = { "󰞘", "NeodashIconPurple" },
  html = { "󰌝", "NeodashIconRed" },
  css = { "󰌜", "NeodashIconBlue" },
  scss = { "󰌜", "NeodashIconBlue" },
  json = { "󰘦", "NeodashIconYellow" },
  yaml = { "󰈙", "NeodashIconCyan" },
  yml = { "󰈙", "NeodashIconCyan" },
  toml = { "󰈙", "NeodashIconCyan" },
  xml = { "󰎨", "NeodashIconCyan" },
  md = { "󰍔", "NeodashIconBlue" },
  markdown = { "󰍔", "NeodashIconBlue" },
  sh = { "󰊄", "NeodashIconGreen" },
  bash = { "󰊄", "NeodashIconGreen" },
  zsh = { "󰊄", "NeodashIconGreen" },
  fish = { "󰊄", "NeodashIconGreen" },
  vim = { "󰫧", "NeodashIconGreen" },
  nix = { "󰣊", "NeodashIconCyan" },
  zig = { "󰓛", "NeodashIconYellow" },
  dockerfile = { "󰡨", "NeodashIconBlue" },
  zip = { "󰐝", "NeodashIconYellow" },
  png = { "󰋩", "NeodashIconPurple" },
  jpg = { "󰋩", "NeodashIconPurple" },
  jpeg = { "󰋩", "NeodashIconPurple" },
  svg = { "󰋩", "NeodashIconPurple" },
  pdf = { "󰭎", "NeodashIconRed" },
  txt = { "󰈙", "NeodashIconDim" },
}

local by_name = {
  ["init.lua"] = { "󰢱", "NeodashIconPurple" },
  [".gitignore"] = { "󰊢", "NeodashIconRed" },
  [".gitattributes"] = { "󰊢", "NeodashIconRed" },
  [".gitconfig"] = { "󰊢", "NeodashIconRed" },
  [".npmrc"] = { "󰒋", "NeodashIconRed" },
  [".env"] = { "󰙅", "NeodashIconYellow" },
  ["docker-compose.yml"] = { "󰡨", "NeodashIconBlue" },
  ["package.json"] = { "󰏗", "NeodashIconRed" },
  ["package-lock.json"] = { "󰏗", "NeodashIconRed" },
  ["Cargo.toml"] = { "󰓛", "NeodashIconYellow" },
  ["README.md"] = { "󰍔", "NeodashIconBlue" },
}

function M.lookup(path)
  local name = vim.fn.fnamemodify(path or "", ":t")
  local named = by_name[name]
  if named then
    return named[1], named[2]
  end
  local ext = name:match("%.([^.]+)$")
  local lowered = ext and ext:lower() or nil
  local found = lowered and by_ext[lowered] or nil
  if found then
    return found[1], found[2]
  end
  return "󰈙", "NeodashIconDim"
end

function M.glyph(path)
  return (M.lookup(path))
end

function M.group(path)
  local _, group = M.lookup(path)
  return group
end

return M
