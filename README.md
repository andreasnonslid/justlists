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

### Todo
- [ ] Reuse floating list viewer for viewing more than just explicitly set lists via keybinds
- [ ] Reflect and limit the plugin to not overengineer (re--plan)
- [ ] Add renewing todos for daily/weekly/monthly elements
- [ ] Add time based search for lists based on last update
- [ ] Add easy copying of a list

## Configuration
Lazy.nvim to set up, with defaults and some keybinds as starting points.

```lua

require("lazy").setup(
    {
        {
            "andreasnonslid/justlists",
            dependencies = {
                "nvim-lua/plenary.nvim",
                "nvim-telescope/telescope.nvim"
            },
            config = function()
                local justlists = require("justlists")
                justlists.setup(
                    {
                        list_dir = vim.fn.stdpath("data") .. "/justlists", -- Default list directory
                        file_extension = ".md" -- Default
                    }
                )

                -- Default plugin functions
                vim.keymap.set("n", "<leader>lc", justlists.create_list, {desc = "[L]ists [C]reate a New List"})
                vim.keymap.set("n", "<leader>ld", justlists.delete_list, {desc = "[L]ists [D]elete a List"})
                vim.keymap.set("n", "<leader>le", justlists.edit_list, {desc = "[L]ists [E]dit an Existing List"})
                vim.keymap.set("n", "<leader>lq", justlists.quick_list, {desc = "[L]ists [Q]uickly Open Last List"})

                -- Keymaps to open certain lists quickly
                vim.keymap.set("n", "<leader>lt", justlists.open_list("todo"), {desc = "[L]ists [T]odo"})
                vim.keymap.set("n", "<leader>lj", justlists.open_list("journal"), {desc = "[L]ists [J]ournal"})
                vim.keymap.set("n", "<leader>lg", justlists.open_list("goals"), {desc = "[L]ists [G]oals"})

                -- Keymaps for viewing markdown
                vim.keymap.set(
                    "n",
                    "<leader>lv",
                    function()
                        justlists.markdown_viewer.open("todo")
                    end,
                    {desc = "[L]ists [V]iew Todo"}
                )
            end
        }
    }
)
```

or

```lua
return {
    "andreasnonslid/justlists",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim"
    },
    config = function()
        local justlists = require("justlists")
        justlists.setup(
            {
                list_dir = vim.fn.stdpath("data") .. "/justlists", -- Default list directory
                file_extension = ".md" -- Default
            }
        )

        -- Default plugin functions
        vim.keymap.set("n", "<leader>lc", justlists.create_list, {desc = "[L]ists [C]reate a New List"})
        vim.keymap.set("n", "<leader>ld", justlists.delete_list, {desc = "[L]ists [D]elete a List"})
        vim.keymap.set("n", "<leader>le", justlists.edit_list, {desc = "[L]ists [E]dit an Existing List"})
        vim.keymap.set("n", "<leader>lq", justlists.quick_list, {desc = "[L]ists [Q]uickly Open Last List"})

        -- Keymaps to open certain lists quickly
        vim.keymap.set("n", "<leader>lt", justlists.open_list("todo"), {desc = "[L]ists [T]odo"})
        vim.keymap.set("n", "<leader>lj", justlists.open_list("journal"), {desc = "[L]ists [J]ournal"})
        vim.keymap.set("n", "<leader>lg", justlists.open_list("goals"), {desc = "[L]ists [G]oals"})

        -- Keymaps for viewing markdown
        vim.keymap.set(
            "n",
            "<leader>lv",
            function()
                justlists.markdown_viewer.open("todo")
            end,
            {desc = "[L]ists [V]iew Todo"}
        )
    end
}
```

My config while developing with my settings:

```lua
return {
    "andreasnonslid/justlists",
    dev = true,
    dir = "~/dev/justlists",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim"
    },
    config = function()
        local justlists = require("justlists")
        justlists.setup(
            {
                list_dir = vim.fn.expand("~/list_directory"),
                file_extension = ".md" -- Default
            }
        )

        -- Default plugin functions
        vim.keymap.set("n", "<leader>lc", justlists.create_list, {desc = "[L]ists [C]reate a New List"})
        vim.keymap.set("n", "<leader>ld", justlists.delete_list, {desc = "[L]ists [D]elete a List"})
        vim.keymap.set("n", "<leader>le", justlists.edit_list, {desc = "[L]ists [E]dit an Existing List"})
        vim.keymap.set("n", "<leader>lq", justlists.quick_list, {desc = "[L]ists [Q]uickly Open Last List"})

        -- Keymaps to open certain lists quickly
        vim.keymap.set("n", "<leader>lt", justlists.open_list("todo"), {desc = "[L]ists [T]odo"})
        vim.keymap.set("n", "<leader>lj", justlists.open_list("journal"), {desc = "[L]ists [J]ournal"})
        vim.keymap.set("n", "<leader>lg", justlists.open_list("goals"), {desc = "[L]ists [G]oals"})

        -- Keymaps for viewing markdown
        vim.keymap.set(
            "n",
            "<leader>lv",
            function()
                justlists.markdown_viewer.open("todo")
            end,
            {desc = "[L]ists [V]iew Todo"}
        )
    end
}
```
