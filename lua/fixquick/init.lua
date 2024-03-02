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
  for index, entry in ipairs(quickfix_entries) do
    local found = false
    for _, line in ipairs(file_contents) do
      if line:find(entry.text) then
        found = true
        break
      end
    end
    if not found then
      -- remove entry from quickfix list
      table.remove(quickfix_entries, index)
    end
  end
  -- create new quickfix list
  vim.fn.setqflist({}, "r", { items = quickfix_entries })
  make_buffer_modifiable()
end

local function on_quickfix_enter()
  if vim.bo.buftype == "quickfix" then
    local bufnr = vim.api.nvim_get_current_buf()
    local name = "/tmp/quickfix-" .. bufnr -- Naming the buffer allows us to save it as a file

    vim.cmd("write! " .. name)
    make_buffer_modifiable()
    vim.api.nvim_create_autocmd("BufWriteCmd", {
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
