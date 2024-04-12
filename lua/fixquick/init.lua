--- A Neovim plugin to make the quickfix list modifiable and persist changes.
--- @module fixquick
local M = {}

local augroup_name = "Fixquick"
local augroup = vim.api.nvim_create_augroup(augroup_name, {})

local function async_fn(fn)
  return function(...)
    local args = { ... }
    vim.defer_fn(function()
      fn(unpack(args))
    end, 0)
  end
end

--- Make the buffer modifiable
--- @param bufnr number The buffer number to make modifiable
function M.make_buffer_modifiable(bufnr)
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
end

--- @param args table The arguments table with the 'file' key containing the path to the temporary file.
function M.on_quickfix_write(args)
  assert(type(args) == "table" and args.file, "on_quickfix_write: Invalid args or missing 'file' key")

  local file = args.file
  local file_lines = vim.fn.readfile(file)
  file_lines = vim.tbl_filter(function(line)
    return not line:match "^%s*$" -- Remove empty lines
  end, file_lines)
  local new_qf_list = {}

  -- Capture the current cursor position in the quickfix window
  local winid = vim.fn.getqflist({ winid = 0 }).winid
  local cursor_pos = vim.api.nvim_win_get_cursor(winid)

  for _, line in ipairs(file_lines) do
    local parts = vim.split(line, "|")
    local entry_text = parts[3]
    entry_text = entry_text:gsub("^%s+", "")
    local entry_file = parts[1]

    local new_entry = {
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

    table.insert(new_qf_list, new_entry)
  end

  vim.fn.setqflist({}, "r", { items = new_qf_list })

  -- Restore the cursor position
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_set_cursor(winid, cursor_pos)
  end
end

-- Keep track of the autocmds created for each buffer, so we don't create them again
local autocmds_created = {}
function M.on_quickfix_enter()
  if vim.bo.buftype == "quickfix" then
    local bufnr = vim.api.nvim_get_current_buf()
    M.make_buffer_modifiable(bufnr)

    -- Check if the autocmd has already been created for this buffer
    if not autocmds_created[bufnr] then
      local temp_file = "/tmp/quickfix-" .. bufnr

      vim.cmd("silent write! " .. temp_file)

      -- Create the BufWritePost autocmd for this buffer
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          async_fn(M.on_quickfix_write) { file = temp_file }
        end,
      })

      -- Mark the autocmd as created for this buffer
      autocmds_created[bufnr] = true
    end
  end
end

local function create_autocmds()
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = "quickfix",
    callback = M.on_quickfix_enter,
    nested = true,
  })
end

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
