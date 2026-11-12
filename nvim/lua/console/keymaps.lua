local map = vim.keymap.set
local layout = require("console.layout")
local term = require("console.term")

-- Pickers always open their result in the editor pane, never the tree/terminal.
local function pick(name, opts)
  return function()
    layout.focus_editor()
    require("fzf-lua")[name](opts)
  end
end

-- Windows (from ~/.vimrc)
map("n", "<leader>h", "<cmd>wincmd h<cr>", { desc = "Window left" })
map("n", "<leader>j", "<cmd>wincmd j<cr>", { desc = "Window down" })
map("n", "<leader>k", "<cmd>wincmd k<cr>", { desc = "Window up" })
map("n", "<leader>l", "<cmd>wincmd l<cr>", { desc = "Window right" })
map("n", "<leader>+", function()
  layout.resize(5)
end, { desc = "Make this pane wider" })
map("n", "<leader>-", function()
  layout.resize(-5)
end, { desc = "Make this pane narrower" })
map("n", "<leader>=", layout.reset, { desc = "Reset the three panes to default widths" })

-- Files and buffers
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Close window" })
map("n", "<leader>Q", function()
  -- One question at most: unsaved files are handled by 'confirm'; running
  -- terminals (which die with nvim) get a single prompt instead of one each.
  for _, b in ipairs(vim.fn.getbufinfo({ bufmodified = 1 })) do
    if vim.bo[b.bufnr].buftype == "" then
      return vim.cmd("confirm qall")
    end
  end
  local tabs = term.count()
  if tabs > 0 and vim.fn.confirm(("Quit and end %d terminal tab%s?"):format(tabs, tabs == 1 and "" or "s"), "&Quit\n&Cancel", 2) ~= 1 then
    return
  end
  vim.cmd("qall!")
end, { desc = "Quit nvim" })
map("n", "<leader>x", function()
  -- Close the file but keep the window: show another open file (or an empty
  -- buffer) in its place first.
  local buf = vim.api.nvim_get_current_buf()
  local bt = vim.bo[buf].buftype
  if vim.bo[buf].filetype == "neo-tree" or (bt ~= "" and bt ~= "help") then
    return
  end
  local alt = vim.fn.bufnr("#")
  if not (alt > 0 and alt ~= buf and vim.fn.buflisted(alt) == 1) then
    alt = nil
    for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if b.bufnr ~= buf then
        alt = b.bufnr
        break
      end
    end
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_set_buf(win, alt or vim.api.nvim_create_buf(true, false))
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.cmd("confirm bdelete " .. buf)
  end
end, { desc = "Close file, keep window" })

-- Tree
map("n", "<leader>e", "<cmd>Neotree focus filesystem left<cr>", { desc = "Focus file tree" })
map("n", "<leader>E", function()
  layout.quiet()
  vim.cmd("Neotree toggle filesystem left")
end, { desc = "Show/hide file tree" })

-- Search
map("n", "<leader>ff", pick("files"), { desc = "Find file" })
map("n", "<C-p>", pick("files"), { desc = "Find file" })
map("n", "<leader>fg", pick("live_grep"), { desc = "Search text in workspace" })
map("n", "<leader>fw", pick("grep_cword"), { desc = "Search word under cursor" })
map("n", "<leader>fb", pick("buffers"), { desc = "Open files" })
map("n", "<leader>fo", pick("oldfiles", { include_current_session = true }), { desc = "Recent files" })
map("n", "<leader>fr", pick("resume"), { desc = "Reopen last search" })

-- Terminal pane (inside a terminal use the Ctrl-\ prefix instead; see term.lua)
map("n", "<leader>tt", term.focus, { desc = "Focus terminal" })
map("n", "<leader>th", term.toggle, { desc = "Show/hide terminal pane" })
map("n", "<leader>tc", function()
  term.new()
end, { desc = "New terminal tab" })
map("n", "<leader>tn", function()
  term.cycle(1)
end, { desc = "Next terminal tab" })
map("n", "<leader>tp", function()
  term.cycle(-1)
end, { desc = "Previous terminal tab" })
map("n", "<leader>tr", function()
  vim.ui.input({ prompt = "Tab name: " }, term.rename)
end, { desc = "Rename terminal tab" })
map("n", "<leader>tx", function()
  term.close()
end, { desc = "Close terminal tab" })

-- Cheat sheet
map("n", "<leader>?", function()
  layout.focus_editor()
  vim.cmd.view(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/KEYS.md"))
end, { desc = "Keys cheat sheet" })
