local augroup_name = "Fixquick"
local augroup = vim.api.nvim_create_augroup(augroup_name, {})

local function make_buffer_modifiable()
  vim.cmd "setlocal modifiable"
  vim.cmd "setlocal nomodified"
end

--- @param args table
local function on_quickfix_write(args)
  local file = args.file
  local file_contents = vim.fn.readfile(file)
  local quickfix_entries = vim.fn.getqflist()
  local new_qf_list = {}

  for _, entry in ipairs(quickfix_entries) do
    local found = false
    for _, line in ipairs(file_contents) do
      if line:find(entry.text) then
        found = true
        break
      end
    end
    if found then
      table.insert(new_qf_list, entry)
    end
  end

  -- Replace the current quickfix list with the new one
  vim.fn.setqflist({}, "r", { items = new_qf_list })
  make_buffer_modifiable()
end

local function on_quickfix_enter()
  if vim.bo.buftype == "quickfix" then
    local bufnr = vim.api.nvim_get_current_buf()
    local name = "/tmp/quickfix-" .. bufnr -- Naming the buffer allows us to save it as a file

    vim.cmd("silent write! " .. name)
    make_buffer_modifiable()
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = augroup,
      buffer = bufnr,
      callback = on_quickfix_write,
    })
  end
end

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  pattern = "quickfix",
  callback = on_quickfix_enter,
  nested = true,
})
