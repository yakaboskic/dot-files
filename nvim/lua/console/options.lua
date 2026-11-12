vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt

-- Carried over from ~/.vimrc
o.number = true
o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.smartindent = true
o.wrap = false
o.ignorecase = true
o.smartcase = true
o.swapfile = false
o.backup = false
o.undofile = true
o.scrolloff = 8
o.mouse = "a"

-- Console behaviour
o.clipboard = "unnamedplus" -- yank/paste use the macOS clipboard
o.confirm = true -- ask instead of failing on unsaved changes
o.cursorline = true
o.signcolumn = "yes"
o.splitright = true
o.splitbelow = true
o.laststatus = 3 -- one statusline for the whole console
o.updatetime = 300
o.fillchars = { eob = " " }
o.shortmess:append("I")

-- Sessions restore files and editor splits only; the tree and terminals are
-- rebuilt by console.layout.
o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,localoptions"
