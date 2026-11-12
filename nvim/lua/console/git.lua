-- Change markers in the gutter, per file, against that file's own repo.
require("gitsigns").setup({
  on_attach = function(buf)
    local gs = require("gitsigns")
    local function map(lhs, fn, desc)
      vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
    end
    map("]h", function()
      gs.nav_hunk("next")
    end, "Next change")
    map("[h", function()
      gs.nav_hunk("prev")
    end, "Previous change")
    map("<leader>gp", gs.preview_hunk, "Preview change")
    map("<leader>gd", gs.diffthis, "Diff file against git")
    map("<leader>gb", function()
      gs.blame_line({ full = true })
    end, "Blame line")
  end,
})
