-- Observation console:  file tree | editor | tabbed terminals
-- Keys: <Space>? opens the cheat sheet (KEYS.md).

-- Set to true once your terminal's font is a Nerd Font (adds file-type icons).
vim.g.have_nerd_font = false

-- `nvim <dir>` means "open that workspace": make it the working directory.
if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
  vim.cmd.cd(vim.fn.fnameescape(vim.fn.argv(0)))
end

require("console.options")
require("console.plugins")
require("console.ui")
require("console.tree")
require("console.term").setup()
require("console.search")
require("console.git")
require("console.watch")
require("console.session")
require("console.keymaps")
require("console.layout").setup()
