local config = require("justlists.config")
local M = {}

function M.get_state_file()
  return config.config.state_file
end

function M.load_state()
  local state_file = M.get_state_file()
  if vim.fn.filereadable(state_file) == 1 then
    local state = vim.fn.readfile(state_file)
    return vim.json.decode(table.concat(state, "\n"))
  end
  return {}
end

function M.save_state(state)
  local state_file = M.get_state_file()
  vim.fn.writefile({ vim.json.encode(state) }, state_file)
end

return M
