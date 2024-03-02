-- make sure this file is loaded only once
if vim.g.fixquick_loaded == 1 then
  return
end
vim.g.fixquick_loaded = 1

require "fixquick.init"
