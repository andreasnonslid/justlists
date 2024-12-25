local config = require("justlists.config")
local M = {}

-- Opens a file in a floating window
function M.open(filename)
  if not filename or filename == "" then
    print("Error: Filename is required.")
    return
  end

  local path = config.config.list_dir .. "/" .. filename .. config.config.file_extension

  -- Open the file and get its buffer
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)

  -- Create a floating window for the buffer
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Set the buffer options
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"

  -- Add keybinds for interactions
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, noremap = true, silent = true })
end

return M
