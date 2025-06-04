--------------------------------------------------------------------------------
-- justlists.lua (single‐file plugin with history & quick‐open)
--
-- 1. Uses Telescope (Tree‐sitter–powered fuzzy) to find files by name or content 
--    under a configured root directory.
-- 2. Opens the selected file either in a floating window or replaces the current buffer.
-- 3. Records every opened file into a persistent history.
-- 4. Provides “quick open” to reopen the most recently opened file.
--------------------------------------------------------------------------------

local Path = require("plenary.path")
local vim  = vim
local M    = {}

--==============================================================================
-- 1. Defaults & persistent state
--==============================================================================
M.config = {
  -- Directory under which to search (override via setup)
  root_dir   = Path:new(vim.fn.stdpath("data"), "justlists"):absolute(),
  -- File to store history (JSON with { history = { ... } })
  state_file = Path:new(vim.fn.stdpath("data"), "justlists_history.json"):absolute(),
}
M.state = { history = {} }

-- Load history from disk
function M._load_state()
  local f = M.config.state_file
  if vim.fn.filereadable(f) == 1 then
    local lines = vim.fn.readfile(f)
    local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
    if ok and type(decoded) == "table" and decoded.history then
      M.state = decoded
    end
  end
end

-- Save history to disk
function M._save_state()
  local f = M.config.state_file
  vim.fn.mkdir(Path:new(f):parent().filename, "p")
  vim.fn.writefile({ vim.json.encode(M.state) }, f)
end

--==============================================================================
-- 2. Cross‐platform path helper
--==============================================================================
function M._join_path(...)
  return Path:new(...):absolute()
end

--==============================================================================
-- 3. File‐opening adapters
--==============================================================================

-- 3.1. Open in current window (replace buffer)
function M._open_normal(filepath)
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

-- 3.2. Open in floating window
function M._open_float(filepath)
  local buf = vim.fn.bufadd(filepath)
  pcall(vim.fn.bufload, buf)

  local width  = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines   * 0.8)
  local row    = math.floor((vim.o.lines - height) / 2)
  local col    = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    row      = row,
    col      = col,
    style    = "minimal",
    border   = "rounded",
  })

  -- If it's Markdown, set ft; otherwise keep existing
  if vim.fn.fnamemodify(filepath, ":e") == "md" then
    vim.bo[buf].filetype = "markdown"
  end
  vim.bo[buf].bufhidden = "wipe"
end

--==============================================================================
-- 4. Record and open: update history then open
--==============================================================================
function M._record_and_open(filepath, mode)
  -- Normalize absolute path
  local target = Path:new(filepath):absolute()

  -- Update history (dedupe + append)
  M.state.history = M.state.history or {}
  for i, v in ipairs(M.state.history) do
    if v == target then
      table.remove(M.state.history, i)
      break
    end
  end
  table.insert(M.state.history, target)
  if #M.state.history > 50 then
    table.remove(M.state.history, 1)
  end
  M._save_state()

  -- Open now
  if mode == "float" then
    M._open_float(target)
  else
    M._open_normal(target)
  end
end

--==============================================================================
-- 5. Finder functions using Telescope
--==============================================================================

-- 5.1. Find files by filename (fuzzy)
function M.find_files()
  require("telescope.builtin").find_files({
    prompt_title = "JustLists ▶ Find Files",
    cwd          = M.config.root_dir,
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local state   = require("telescope.actions.state")

      map("i", "<CR>", function()
        local entry = state.get_selected_entry()
        local path  = entry.path
        actions.close(prompt_bufnr)
        if vim.fn.filereadable(path) == 1 then
          M._record_and_open(path, "normal")
        else
          print("Error: file not readable: " .. path)
        end
      end)
      map("n", "<CR>", function()
        local entry = state.get_selected_entry()
        local path  = entry.path
        actions.close(prompt_bufnr)
        if vim.fn.filereadable(path) == 1 then
          M._record_and_open(path, "normal")
        else
          print("Error: file not readable: " .. path)
        end
      end)

      return true
    end,
  })
end

-- 5.2. Find files by content (live grep)
function M.find_content()
  require("telescope.builtin").live_grep({
    prompt_title = "JustLists ▶ Find by Content",
    cwd          = M.config.root_dir,
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local state   = require("telescope.actions.state")

      map("i", "<CR>", function()
        local entry = state.get_selected_entry()
        local file  = entry.filename or entry.path
        actions.close(prompt_bufnr)
        local full = Path:new(M.config.root_dir, file):absolute()
        if vim.fn.filereadable(full) == 1 then
          M._record_and_open(full, "normal")
        else
          print("Error: file not readable: " .. full)
        end
      end)
      map("n", "<CR>", function()
        local entry = state.get_selected_entry()
        local file  = entry.filename or entry.path
        actions.close(prompt_bufnr)
        local full = Path:new(M.config.root_dir, file):absolute()
        if vim.fn.filereadable(full) == 1 then
          M._record_and_open(full, "normal")
        else
          print("Error: file not readable: " .. full)
        end
      end)

      return true
    end,
  })
end

--==============================================================================
-- 6. quick_open: reopen last file from history
--==============================================================================
function M.quick_open()
  local hist = M.state.history or {}
  if #hist == 0 then
    print("JustLists ▶ No history available.")
    return
  end
  local last = hist[#hist]
  if vim.fn.filereadable(last) == 1 then
    M._record_and_open(last, "normal")
  else
    print("JustLists ▶ Most recent file no longer exists: " .. last)
  end
end

--==============================================================================
-- 7. open_file: open a given relative or absolute path
--==============================================================================
function M.open_file(rel_or_abs_path, mode)
  if not rel_or_abs_path or rel_or_abs_path == "" then
    print("JustLists ▶ Error: path required.")
    return
  end

  -- Determine absolute path
  local candidate = rel_or_abs_path
  if not Path:new(candidate):exists() then
    candidate = Path:new(M.config.root_dir, rel_or_abs_path):absolute()
  end

  if vim.fn.filereadable(candidate) == 0 then
    print("JustLists ▶ File does not exist: " .. candidate)
    return
  end

  -- Record & open
  M._record_and_open(candidate, mode)
end

--==============================================================================
-- 8. delete_file: remove a chosen file
--==============================================================================
function M.delete_file()
  require("telescope.builtin").find_files({
    prompt_title = "JustLists ▶ Select File to Delete",
    cwd          = M.config.root_dir,
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local state   = require("telescope.actions.state")

      map("i", "<CR>", function()
        local entry = state.get_selected_entry()
        local path  = entry.path
        actions.close(prompt_bufnr)
        if vim.fn.filereadable(path) == 1 then
          os.remove(path)
          print("JustLists ▶ Deleted: " .. path)
        else
          print("JustLists ▶ Error: file not found: " .. path)
        end
      end)
      map("n", "<CR>", function()
        local entry = state.get_selected_entry()
        local path  = entry.path
        actions.close(prompt_bufnr)
        if vim.fn.filereadable(path) == 1 then
          os.remove(path)
          print("JustLists ▶ Deleted: " .. path)
        else
          print("JustLists ▶ Error: file not found: " .. path)
        end
      end)

      return true
    end,
  })
end

--==============================================================================
-- 9. setup() & user commands
--==============================================================================
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  vim.fn.mkdir(M.config.root_dir, "p")
  M._load_state()

  vim.api.nvim_create_user_command("JLFindName",    M.find_files,   {})
  vim.api.nvim_create_user_command("JLFindContent", M.find_content,{})
  vim.api.nvim_create_user_command("JLOpenFile",    function(o) M.open_file(o.args, "normal") end, { nargs = 1 })
  vim.api.nvim_create_user_command("JLOpenFloat",   function(o) M.open_file(o.args, "float")  end, { nargs = 1 })
  vim.api.nvim_create_user_command("JLQuickOpen",   M.quick_open,   {})
  vim.api.nvim_create_user_command("JLDeleteFile",  M.delete_file,  {})
end

return M

