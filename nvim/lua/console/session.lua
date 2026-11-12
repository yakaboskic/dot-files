-- One session per working directory, saved on exit and restored on start:
-- open files and editor splits come back when you reopen a workspace.
-- Terminals are not restored (their processes are gone); you get a fresh shell.
local layout = require("console.layout")

require("auto-session").setup({
  suppressed_dirs = { "~/", "/", "~/Downloads", "~/Desktop" },
  pre_save_cmds = { layout.close_sides },
  post_save_cmds = {
    function()
      if vim.v.exiting == vim.NIL then
        layout.open()
      end
    end,
  },
  post_restore_cmds = { layout.open },
})
