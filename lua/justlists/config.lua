local M = {}

-- Default configuration
M.defaults = {
  list_dir = vim.fn.stdpath("data") .. "/justlists",
  file_extension = ".md",
  state_file = vim.fn.stdpath("data") .. "/justlists_state.json",
}

-- Active configuration (populated during setup)
M.config = {}

-- Setup function to override defaults
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.defaults, opts)

  -- Ensure the list directory exists
  vim.fn.mkdir(M.config.list_dir, "p")
end

return M
