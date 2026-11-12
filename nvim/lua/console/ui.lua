vim.o.background = "dark"
pcall(vim.cmd.colorscheme, "gruvbox")

-- Statusline: file as "root/sub/file" (workspace-relative), modified flag,
-- git branch of that file's repo, cursor position.
function _G.ConsoleFile()
  local bt = vim.bo.buftype
  if bt == "terminal" then
    return "terminal"
  elseif vim.bo.filetype == "neo-tree" then
    return "files"
  end
  return require("console.roots").display(vim.api.nvim_buf_get_name(0))
end

function _G.ConsoleBranch()
  local head = vim.b.gitsigns_head
  return (head and head ~= "") and ("[" .. head .. "] ") or ""
end

vim.o.statusline = " %{v:lua.ConsoleFile()} %m%r%=%{v:lua.ConsoleBranch()}%l:%c  %P "
