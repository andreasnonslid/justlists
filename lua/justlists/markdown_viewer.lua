local config = require("justlists.config")
local M = {}

-- Opens a file in a floating window
function M.open(filename)
  if not filename or filename == "" then
    print("Error: Filename is required.")
    return
  end

  local path = config.config.list_dir .. "/" .. filename .. config.config.file_extension

  -- Ensure the file exists
  if vim.fn.filereadable(path) == 0 then
    print("File does not exist. Creating an empty buffer.")
  end

  -- Open the file and get its buffer
  local buf = vim.fn.bufadd(path)
  pcall(vim.fn.bufload, buf) -- Safely load the buffer

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

  -- Add keymaps for checkbox handling
  M.set_keymaps(buf, win)
end

-- Helper functions for checkbox management and indentation

-- Toggle a checkbox on the current line
local function toggle_checkbox(buf, win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local line_nr = cursor[1]
  local line = vim.api.nvim_buf_get_lines(buf, line_nr - 1, line_nr, false)[1]

  if line:match("%- %[ %]") then
    line = line:gsub("%- %[ %]", "- [x]", 1)
  elseif line:match("%- %[x%]") then
    line = line:gsub("%- %[x%]", "- [ ]", 1)
  else
    print("No checkbox found on the current line.")
    return
  end

  vim.api.nvim_buf_set_lines(buf, line_nr - 1, line_nr, false, { line })
end

-- Add a new checkbox below the current line
local function add_checkbox(buf, win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local line_nr = cursor[1]
  vim.api.nvim_buf_set_lines(buf, line_nr, line_nr, false, { "- [ ] " })
  vim.api.nvim_win_set_cursor(win, { line_nr + 1, 5 })
end

-- Indent the current line
local function indent_line(buf, win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local line_nr = cursor[1]
  local line = vim.api.nvim_buf_get_lines(buf, line_nr - 1, line_nr, false)[1]
  vim.api.nvim_buf_set_lines(buf, line_nr - 1, line_nr, false, { "  " .. line })
end

-- Dedent the current line
local function dedent_line(buf, win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local line_nr = cursor[1]
  local line = vim.api.nvim_buf_get_lines(buf, line_nr - 1, line_nr, false)[1]
  local dedented_line = line:gsub("^%s%s", "")
  vim.api.nvim_buf_set_lines(buf, line_nr - 1, line_nr, false, { dedented_line })
end

-- Navigate to the next checkbox
local function navigate_to_next_checkbox(buf, win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local lines = vim.api.nvim_buf_get_lines(buf, cursor[1], -1, false)
  for i, line in ipairs(lines) do
    if line:match("%- %[ %]") or line:match("%- %[x%]") then
      vim.api.nvim_win_set_cursor(win, { cursor[1] + i, 0 })
      return
    end
  end
  print("No more checkboxes found.")
end

-- Navigate to the previous checkbox
local function navigate_to_previous_checkbox(buf, win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, cursor[1] - 1, false)
  for i = #lines, 1, -1 do
    if lines[i]:match("%- %[ %]") or lines[i]:match("%- %[x%]") then
      vim.api.nvim_win_set_cursor(win, { i, 0 })
      return
    end
  end
  print("No previous checkboxes found.")
end

-- Keymap assignments
function M.set_keymaps(buf, win)
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "<CR>", function()
    toggle_checkbox(buf, win)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "o", function()
    add_checkbox(buf, win)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "<Tab>", function()
    indent_line(buf, win)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "<S-Tab>", function()
    dedent_line(buf, win)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "n", function()
    navigate_to_next_checkbox(buf, win)
  end, { buffer = buf, noremap = true, silent = true })

  vim.keymap.set("n", "N", function()
    navigate_to_previous_checkbox(buf, win)
  end, { buffer = buf, noremap = true, silent = true })
end

return M
