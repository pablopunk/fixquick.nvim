--- A Neovim plugin to make the quickfix list modifiable and persist changes.
--- @module fixquick
local M = {}

local augroup_name = "Fixquick"
local augroup = vim.api.nvim_create_augroup(augroup_name, {})

-- Helper function to defer function execution
local function async_fn(fn)
  return function(...)
    local args = { ... }
    vim.defer_fn(function()
      fn(unpack(args))
    end, 0)
  end
end

-- Set buffer options to make it modifiable
function M.make_buffer_modifiable(bufnr)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
end

-- Parse quickfix line into a quickfix entry table
local function parse_qf_line(line)
  local parts = vim.split(line, "|")
  local entry_text = parts[3]:gsub("^%s+", "")
  local entry_file = parts[1]

  return {
    bufnr = vim.fn.bufadd(entry_file),
    col = tonumber(parts[2]:match "col (%d+)"),
    end_col = 0,
    end_lnum = 0,
    lnum = tonumber(parts[2]:match "(%d+) col"),
    module = entry_file,
    nr = 0,
    pattern = "",
    text = entry_text,
    type = "",
    valid = 1,
    vcol = 0,
  }
end

-- Update quickfix list from a file
function M.on_quickfix_write(args)
  assert(type(args) == "table" and args.file, "on_quickfix_write: Invalid args or missing 'file' key")

  local file = args.file
  local file_lines = vim.fn.readfile(file)
  local qf_list = vim.tbl_filter(function(line)
    return not line:match "^%s*$"
  end, file_lines)
  local new_qf_list = vim.tbl_map(parse_qf_line, qf_list)

  local winid = vim.fn.getqflist({ winid = 0 }).winid
  local cursor_pos = vim.api.nvim_win_get_cursor(winid)

  vim.fn.setqflist({}, "r", { items = new_qf_list })

  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_set_cursor(winid, cursor_pos)
  end
end

local autocmds_created = {}

-- Initialize quickfix buffer on enter
function M.on_quickfix_enter()
  if vim.bo.buftype == "quickfix" then
    local bufnr = vim.api.nvim_get_current_buf()
    M.make_buffer_modifiable(bufnr)
    if not autocmds_created[bufnr] then
      M.setup_autocmds_for_buffer(bufnr)
    end
  end
end

-- Setup autocmd for a specific buffer
function M.setup_autocmds_for_buffer(bufnr)
  local temp_file = "/tmp/quickfix-" .. bufnr
  vim.cmd("silent write! " .. temp_file)

  local function callback()
    async_fn(M.on_quickfix_write) { file = temp_file }
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    buffer = bufnr,
    callback = callback,
  })

  autocmds_created[bufnr] = true
end

-- Register autocmds on plugin load
local function create_autocmds()
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = "quickfix",
    callback = M.on_quickfix_enter,
    nested = true,
  })
end

-- Clear autocmds when disabling the plugin
local function remove_autocmds()
  vim.api.nvim_clear_autocmds { group = augroup }
end

function M.setup()
  create_autocmds()
end

function M.disable()
  remove_autocmds()
end

return M
