local config = require("justlists.config")
local core = require("justlists.core")
local M = {}

function M.create_list()
  local name = vim.fn.input("List name: ")
  if name ~= "" then
    local path = config.config.list_dir .. "/" .. name .. config.config.file_extension
    vim.cmd("edit " .. path)
    require("justlists").state.last_opened_list = path
    core.save_state(require("justlists").state)
  end
end

function M.edit_list()
  require("telescope.builtin").find_files({
    prompt_title = "Edit List",
    cwd = config.config.list_dir,
  })
end

function M.delete_list()
  require("telescope.builtin").find_files({
    prompt_title = "Select List to Delete",
    cwd = config.config.list_dir,
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local entry = require("telescope.actions.state").get_selected_entry()
        local path = entry.path
        if vim.fn.filereadable(path) == 1 then
          os.remove(path)
          print("Deleted: " .. path)
        end
        require("telescope.actions").close(prompt_bufnr)
        if require("justlists").state.last_opened_list == path then
          require("justlists").state.last_opened_list = nil
          core.save_state(require("justlists").state)
        end
      end)
      return true
    end,
  })
end

function M.quick_list()
  local last_opened_list = require("justlists").state.last_opened_list
  if last_opened_list and vim.fn.filereadable(last_opened_list) == 1 then
    vim.cmd("edit " .. last_opened_list)
  else
    vim.cmd("enew")
    print("No last list found.")
  end
end

function M.open_list(filename)
  return function()
    if not filename or filename == "" then
      print("Error: Filename is required.")
      return
    end

    if not filename:match("%..+$") then
      filename = filename .. config.config.file_extension
    end

    local path = config.config.list_dir .. "/" .. filename
    if vim.fn.filereadable(path) == 0 then
      print("File does not exist. Creating a new file: " .. path)
    end

    vim.cmd("edit " .. path)
    require("justlists").state.last_opened_list = path
    core.save_state(require("justlists").state)
  end
end

return M
