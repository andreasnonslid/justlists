# JustLists

A NeoVim plugin for managing and interacting with simple lists from within NeoVim (file jump manager sort of..).

## Features
### Works
- [x] Specify directory for lists
- [x] Add new lists
- [x] Delete lists with fuzzy search to choose which (telescope)
- [x] Edit lists with fuzzy search to choose which (telescope)
- [x] Floating list viewer with markdown support and integrated common actions for lists
- [x] Quick switching to previous list
- [x] Reuse floating list viewer for viewing more than just explicitly set lists via keybinds

### Todo
- [ ] Reflect and limit the plugin to not overengineer (re--plan)
- [ ] Add time based search for lists based on last update
- [ ] Add easy copying of a list

## Configuration
Lazy.nvim to set up, with defaults and some keybinds as starting points.

```lua

require("lazy").setup(
    {
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
      },
      config = function()
        local jl = require("justlists")

        -- 1) Initialize with your desired root_dir:
        jl.setup({
          root_dir = vim.fn.expand("/mnt/c/Users/andreas/dropbox/list_directory"),
        })

        -- 2) Keymaps for find / open / quick / delete:

        -- 2a) Find files by name:
        vim.keymap.set("n", "<leader>lf", function()
          jl.find_files()
        end, { desc = "[J]ustLists ▶ Find [F]iles by Name" })

        -- 2b) Find by content:
        vim.keymap.set("n", "<leader>lc", function()
          jl.find_content()
        end, { desc = "[J]ustLists ▶ Find by [C]ontent" })

        -- 2c) Quick‐open last file from history:
        vim.keymap.set("n", "<leader>lq", function()
          jl.quick_open()
        end, { desc = "[J]ustLists ▶ [Q]uick Open Last File" })

        -- 2d) Open “todo.md” normally:
        vim.keymap.set("n", "<leader>lt", function()
          jl.open_file("todo.md", "normal")
        end, { desc = "[J]ustLists ▶ Open [T]odo (normal)" })

        -- 2e) Open “todo.md” in a floating window:
        vim.keymap.set("n", "<leader>lT", function()
          jl.open_file("todo.md", "float")
        end, { desc = "[J]ustLists ▶ Open [T]odo (float)" })

        -- 2f) Delete a file under root_dir:
        vim.keymap.set("n", "<leader>ld", function()
          jl.delete_file()
        end, { desc = "[J]ustLists ▶ [D]elete File" })
      end,
    }
)
```
