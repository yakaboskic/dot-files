-- Left pane: Neo-tree rooted at the workspace directory. The roots are
-- symlinks to the real repos; the tree stays on the workspace no matter which
-- file is open.
local roots = require("console.roots")
local M = {}

-- Git status under symlinked roots --------------------------------------------
-- Neo-tree names nodes by workspace path but keys git status by the repo's real
-- path, so its lookups miss for everything under a symlinked root. Translate
-- the path for those two lookups. If Neo-tree's internals change, the pcall
-- just leaves git marks off; nothing else depends on this.
pcall(function()
  local git = require("neo-tree.git")
  local status, worktree = git.find_existing_status_code, git.find_existing_worktree
  if type(status) ~= "function" or type(worktree) ~= "function" then
    return
  end
  git.find_existing_status_code = function(path, ...)
    return status(roots.to_real(path), ...)
  end
  git.find_existing_worktree = function(path)
    return worktree(roots.to_real(path))
  end
end)

-- Neo-tree only redraws on a git change when the repo is the tree root or a
-- node with the repo's real path; ours sit behind symlinks, so always redraw.
local function redraw_tree()
  pcall(function()
    local state = require("neo-tree.sources.manager").get_state("filesystem")
    if state and state.tree then
      require("neo-tree.ui.renderer").redraw(state)
    end
  end)
end

-- Reveal the current file ---------------------------------------------------
-- Neo-tree's own follow_current_file cannot find buffers under a symlinked
-- root (buffers carry real paths), so do it here with the workspace path.
local function tree_visible()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      return true
    end
  end
  return false
end

--- Expand the tree to the file in `buf` (default: current) and highlight it.
function M.reveal(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return
  end
  local path, matched = roots.to_workspace(name)
  local cwd = vim.fn.getcwd()
  if not matched and name:sub(1, #cwd + 1) ~= cwd .. "/" then
    return -- not part of this workspace
  end
  pcall(require("neo-tree.command").execute, {
    action = "show",
    source = "filesystem",
    position = "left",
    dir = cwd,
    reveal_file = path,
    reveal_force_cwd = false,
  })
end

local reveal_timer = vim.uv.new_timer()
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("console_tree", { clear = true }),
  callback = function(ev)
    if vim.g.console_follow == false or vim.bo[ev.buf].buftype ~= "" then
      return
    end
    reveal_timer:stop()
    reveal_timer:start(
      150,
      0,
      vim.schedule_wrap(function()
        if tree_visible() and vim.api.nvim_get_current_buf() == ev.buf then
          M.reveal(ev.buf)
        end
      end)
    )
  end,
})

-- Appearance ----------------------------------------------------------------
local components = {
  indent = { with_expanders = true },
}

if not vim.g.have_nerd_font then
  -- Plain glyphs that every font has.
  components.indent.expander_collapsed = "▸"
  components.indent.expander_expanded = "▾"
  components.icon = {
    folder_closed = "",
    folder_open = "",
    folder_empty = "",
    folder_empty_open = "",
    default = "",
  }
  components.git_status = {
    symbols = {
      added = "A",
      deleted = "D",
      modified = "M",
      renamed = "R",
      untracked = "?",
      ignored = "",
      unstaged = "",
      staged = "+",
      conflict = "!",
    },
  }
end

require("neo-tree").setup({
  close_if_last_window = false,
  enable_diagnostics = false,
  popup_border_style = "rounded",
  default_component_configs = components,
  event_handlers = {
    { event = "git_status_changed", handler = vim.schedule_wrap(redraw_tree) },
    {
      event = "neo_tree_window_after_open",
      handler = function(args)
        local layout = require("console.layout")
        local width = layout.width("tree")
        if width and args.position == "left" and vim.api.nvim_win_is_valid(args.winid) then
          layout.quiet()
          vim.api.nvim_win_set_width(args.winid, width)
        end
      end,
    },
  },
  window = {
    position = "left",
    width = 34,
    mappings = {
      ["<space>"] = "none", -- keep <Space> free as the leader key
    },
  },
  filesystem = {
    bind_to_cwd = false,
    follow_current_file = { enabled = false }, -- replaced by M.reveal above
    use_libuv_file_watcher = true, -- update when files change outside nvim
    hijack_netrw_behavior = "open_default",
    filtered_items = {
      hide_dotfiles = false,
      -- Git-ignored files stay visible but dimmed (as in VS Code): agents
      -- often write logs and build output into ignored folders.
      hide_gitignored = false,
      never_show = { ".git", ".DS_Store" },
    },
  },
})

return M
