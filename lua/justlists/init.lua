local M = {}

-- Load configuration
local config = require("justlists.config")
M.config = config

-- Core utilities
local core = require("justlists.core")
M.get_state_file = core.get_state_file
M.load_state = core.load_state
M.save_state = core.save_state

-- Setup configuration
function M.setup(opts)
  config.setup(opts) -- Configure the plugin
  M.state = M.load_state() -- Load state
end

-- Import modularized functions
M.markdown_viewer = require("justlists.markdown_viewer")
local list = require("justlists.list")
M.create_list = list.create_list
M.edit_list = list.edit_list
M.delete_list = list.delete_list
M.quick_list = list.quick_list
M.open_list = list.open_list

return M
