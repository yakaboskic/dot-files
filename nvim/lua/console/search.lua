-- Find files / grep across the whole workspace. The workspace roots are
-- symlinks, which fd and ripgrep skip unless told to follow them.
require("fzf-lua").setup({
  defaults = {
    file_icons = vim.g.have_nerd_font and true or false,
    git_icons = false,
  },
  files = { follow = true, hidden = true },
  grep = {
    follow = true,
    hidden = true,
    -- fzf-lua's default grep flags plus a .git exclusion: with hidden files
    -- searched, every repo's .git directory would otherwise be searched too.
    rg_opts = [[--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -g "!.git" -e]],
  },
})
