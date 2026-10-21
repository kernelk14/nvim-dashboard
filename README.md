# neodash.nvim

A feature rich, dependency free start screen for Neovim with a responsive card
layout, gradient wordmark, live project information and a fully customisable
menu.

```
               ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
               ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
               ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
               ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
               ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
               ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
                                             ·  make something wonderful  ·

                 ╭─ 󰘳 Actions ──────────────────────────╮   ╭─ 󰉋 Project ────────────────────────────╮
                 │ 󰈞  Find file                      f  │   │ nvim-dashboard                         │
                 │ 󰝒  New file                       n  │   │ ~/Documents/Codes/nvim-dashboard       │
                 │ 󰋚  Recent files                   r  │   │  main  ·  ✓ clean                    │
                 │ 󰒓  Open config                    ,  │   ╰────────────────────────────────────────╯
                 │ 󰅚  Quit Neovim                    q  │                                             
                 ╰──────────────────────────────────────╯   ╭─ 󰋚 Recent ─────────────────────────────╮
                                                            │ 󰢱  init.lua              neodash    2h  │
                                                            │ 󰢱  config.lua            neodash    1d  │
                                                            ╰────────────────────────────────────────╯

                         󰥔 18:26   ·   󰃭 Wed, Oct 21   ·   neovim 0.11.3   ·   press ? for help
```

## Features

- **Responsive layout** – two columns on wide terminals, a single stacked
  column on narrow ones, and the header degrades from a full wordmark to a
  compact lockup when space runs out.
- **Six built in themes** plus `auto`, which derives a palette from your
  current colorscheme and follows `:colorscheme` changes.
- **Gradient wordmark** rendered with a per character gradient, or bring your
  own ASCII art.
- **Live project card** with the git branch and dirty state, resolved
  asynchronously so startup is never blocked.
- **Live clock** in the footer that ticks without re-rendering the dashboard.
- **Recent files** with per file type icons and relative timestamps, sourced
  from `v:oldfiles`.
- **Clickable dashboard** – every menu entry and recent file is a real
  clickable region, plus `j`/`k` navigation with `<CR>`.
- **Picker aware** – file and recent pickers are routed to `snacks.nvim`,
  `telescope.nvim`, `fzf-lua` or `mini.pick` when they are installed, with a
  built in fallback.
- **Extensible** – register your own sections, menu items and actions from
  Lua.
- **Lightweight** – no dependencies, no background timers, no blocking
  commands, and the whole plugin is a handful of small Lua modules.

## Requirements

- Neovim 0.10 or newer
- A [Nerd Font](https://www.nerdfonts.com) for the icons (optional, the layout
  still works without one)

## Installation

<details open>
<summary>lazy.nvim</summary>

```lua
{
  "kernelk14/nvim-dashboard",
  opts = {},
}
```

</details>

<details>
<summary>packer.nvim</summary>

```lua
use({
  "kernelk14/nvim-dashboard",
  config = function()
    require("neodash").setup()
  end,
})
```

</details>

<details>
<summary>vim-plug</summary>

```vim
Plug 'kernelk14/nvim-dashboard'
lua require('neodash').setup()
```

</details>

<details>
<summary>Manual</summary>

```sh
git clone https://github.com/kernelk14/nvim-dashboard \
  ~/.local/share/nvim/site/pack/packer/start/nvim-dashboard
```

```lua
lua require('neodash').setup()
```

</details>

## Configuration

The defaults are intentionally small, everything is optional.

```lua
require("neodash").setup({
  auto_open = true,
  theme = "aurora", -- aurora | mocha | nord | ember | mono | daylight | auto
  transparent = false,
  max_width = 100,
  padding = 2,
  gap = 3,
  two_column = true,
  header = {
    style = "auto", -- auto | art | compact | text | none
    tagline = "make something wonderful",
    art = nil, -- your own ASCII art
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
    exclude = {}, -- plain substrings that are skipped
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
  keys = {
    close = "q",
    help = "?",
    refresh = "R",
  },
})
```

### Menu items

A menu item accepts an `icon`, a `label`, a `key` shortcut, an `action` and an
optional `enabled` predicate.

```lua
menu = {
  items = {
    {
      icon = "󰃨",
      label = "Projects",
      key = "p",
      action = function()
        require("telescope.builtin").find_files({ cwd = require("neodash").session_path() })
      end,
      enabled = function()
        return vim.fn.isdirectory(vim.fn.expand("~/projects")) == 1
      end,
    },
  },
}
```

`action` may be a function or the name of a built in action: `find_files`,
`recent_files`, `new_file`, `edit_config`, `lazy`, `explore_cwd`, `quit`,
`help`, `save_session`, `restore_session`.

### Custom sections

Register a section once, then reference it by name in `sections`.

```lua
require("neodash").register_section("sessions", {
  title = "Sessions",
  icon = "󰑮",
  render = function(ctx)
    local lines = {}
    for _, session in ipairs(vim.fn.readdir(vim.fn.stdpath("data") .. "/sessions")) do
      lines[#lines + 1] = { text = session }
    end
    return { title = "Sessions", icon = "󰑮", lines = lines }
  end,
})

require("neodash").setup({
  sections = { left = { "menu" }, right = { "project", "recent", "sessions" } },
})
```

A renderer receives a context table with `cfg`, `inner` (the usable width of
the card) and `limit`. It returns a table with `title`, `icon` and `lines`,
where every line is either a string or a table of `{ text = ..., hl = ... }`
segments.

Static sections can also be declared inline.

```lua
require("neodash").setup({
  sections = {
    custom = {
      todo = {
        title = "Todo",
        icon = "󰄡",
        lines = { "ship the dashboard", "write the docs" },
      },
    },
    right = { "project", "recent", "todo" },
  },
})
```

## Commands

| Command         | Description                          |
| --------------- | ------------------------------------ |
| `:Neodash`      | Open the dashboard                   |
| `:NeodashClose` | Close the dashboard                  |
| `:NeodashRefresh` | Re-render the dashboard            |
| `:NeodashTheme` | Switch theme (`aurora`, `mocha`, ...) |

## Keymaps

| Key      | Action                          |
| -------- | ------------------------------- |
| `f`      | Find file                       |
| `n`      | New file                        |
| `r`      | Recent files                    |
| `,`      | Open the config                 |
| `q`      | Quit Neovim                     |
| `j` / `k` | Move between clickable actions |
| `<CR>`   | Run the action under the cursor |
| `R`      | Refresh                         |
| `?`      | Open this help                  |
| `<Esc>`  | Close the dashboard             |

## API

```lua
local neodash = require("neodash")

neodash.setup(opts)        -- configure the plugin
neodash.open()             -- open the dashboard
neodash.close()            -- close the dashboard
neodash.toggle()           -- toggle the dashboard
neodash.refresh()          -- re-render the dashboard
neodash.is_open()          -- is the dashboard open?
neodash.set_theme(name)    -- switch the theme at runtime
neodash.register_section(name, spec)
neodash.session_path()
```

## Theming

`auto` samples the current colorscheme (`Normal`, `Comment`, `Function`,
`Statement`, `String`, `Diagnostic*`) and rebuilds the palette. It is
re-applied whenever `:colorscheme` runs.

## Development

```sh
nvim --clean --headless -l tests/run.lua
nvim --clean --headless -l tests/layout.lua
nvim --clean --headless -l tests/git.lua
```

`tests/preview.lua` prints the dashboard as plain text for a given size:

```sh
NEODASH_COLS=120 NEODASH_ROWS=40 nvim --clean --headless -l tests/preview.lua
```

## License

MIT
