-- Plugins, managed by Neovim's built-in vim.pack (no third-party manager).
-- Update:  :lua vim.pack.update()      Lockfile: nvim-pack-lock.json (commit it)
local function gh(repo)
  return "https://github.com/" .. repo
end

local specs = {
  gh("ellisonleao/gruvbox.nvim"),
  gh("nvim-lua/plenary.nvim"), -- neo-tree dependency
  gh("MunifTanjim/nui.nvim"), -- neo-tree dependency
  { src = gh("nvim-neo-tree/neo-tree.nvim"), version = "v3.x" },
  gh("rmagatti/auto-session"),
  gh("ibhagwan/fzf-lua"),
  gh("lewis6991/gitsigns.nvim"),
}
if vim.g.have_nerd_font then
  table.insert(specs, gh("nvim-tree/nvim-web-devicons"))
end

vim.pack.add(specs, { confirm = false })
