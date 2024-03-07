--- A Neovim plugin to make the quickfix list modifiable and persist changes.
-- @module fixquick
local M = {}

--- Autogroup name for the plugin's autocmds.
local augroup_name = "Fixquick"
local augroup = vim.api.nvim_create_augroup(augroup_name, {})

--- Makes the current buffer modifiable and clears the modified flag.
function M.make_buffer_modifiable()
  vim.cmd "setlocal modifiable"
  vim.cmd "setlocal nomodified"
end

--- Updates the quickfix list based on the saved temporary file.
--- This function is called after the temporary file associated with the quickfix buffer is written.
--- @param args table The arguments table with the 'file' key containing the path to the temporary file.
function M.on_quickfix_write(args)
  assert(type(args) == "table" and args.file, "on_quickfix_write: Invalid args or missing 'file' key")

  local file = args.file
  local file_lines = vim.fn.readfile(file)
  local quickfix_entries = vim.fn.getqflist()
  local new_qf_list = {}

  for _, entry in ipairs(quickfix_entries) do
    local entry_text = entry.text

    -- vim will truncate the text if it's too long
    if #entry_text > 180 then
      entry_text = string.sub(entry_text, 1, 180)
    end

    local search_in_line = "|" .. entry.lnum .. " col " .. (entry.col or 0) .. "| " .. entry_text

    search_in_line = string.gsub(search_in_line, "|%s+", "| ") -- remove leading whitespace

    for _, line in ipairs(file_lines) do
      line = string.gsub(line, "^[^|]+|", "|") -- remove the file name
      line = string.gsub(line, "|%s+", "| ") -- remove leading whitespace
      if string.find(line, search_in_line, 1, true) then
        table.insert(new_qf_list, entry)
        break
      end
    end
  end

  vim.fn.setqflist({}, "r", { items = new_qf_list })
  M.make_buffer_modifiable()
end

--- Sets up the environment for editing the quickfix list when entering the quickfix window.
--- It writes the current quickfix list to a temporary file and sets up an autocmd to handle saving changes.
function M.on_quickfix_enter()
  if vim.bo.buftype == "quickfix" then
    local bufnr = vim.api.nvim_get_current_buf()
    local temp_file = "/tmp/quickfix-" .. bufnr

    vim.cmd("silent write! " .. temp_file)
    M.make_buffer_modifiable()

    vim.api.nvim_create_autocmd("BufWritePost", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        M.on_quickfix_write { file = temp_file }
      end,
    })
  end
end

--- Initializes the plugin by setting up an autocmd for entering the quickfix window.
function M.setup()
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = "quickfix",
    callback = M.on_quickfix_enter,
    nested = true,
  })
end

return M
