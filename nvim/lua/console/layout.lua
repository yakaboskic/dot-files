-- The three-pane arrangement and "which window is the editor" bookkeeping.
local api = vim.api
local M = {}

local last_editor

-- Pane widths ---------------------------------------------------------------
-- The side panes keep whatever width you give them (drag a border, or use the
-- resize keys). Widths are remembered across hide/show and across restarts.
local TREE_DEFAULT = 34
local widths_file = vim.fn.stdpath("state") .. "/console-widths.json"
local widths = {} -- { tree = n, term = n }, only what the user has chosen
local quiet_until = 0 -- ignore resize events caused by our own layout changes
local last_columns = vim.o.columns

pcall(function()
  local data = vim.json.decode(table.concat(vim.fn.readfile(widths_file), "\n"))
  for _, kind in ipairs({ "tree", "term" }) do
    if type(data[kind]) == "number" then
      widths[kind] = math.floor(data[kind])
    end
  end
end)

local save_timer = vim.uv.new_timer()
local function save_widths()
  save_timer:stop()
  save_timer:start(
    400,
    0,
    vim.schedule_wrap(function()
      pcall(vim.fn.mkdir, vim.fn.fnamemodify(widths_file, ":h"), "p")
      pcall(vim.fn.writefile, { vim.json.encode(widths) }, widths_file)
    end)
  )
end

local function tree_win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      return win
    end
  end
end

local function pane_kind(win)
  if win == require("console.term").win() then
    return "term"
  elseif win == tree_win() then
    return "tree"
  end
end

--- Width the user chose for a side pane ("tree" or "term"), or nil.
function M.width(kind)
  local w = widths[kind]
  return w and math.max(12, math.min(w, vim.o.columns - 30)) or nil
end

--- Call before opening/closing panes so the resulting resizes are not
--- mistaken for the user's choice.
function M.quiet()
  quiet_until = vim.uv.now() + 300
end

--- Make the pane the cursor is in wider (delta > 0) or narrower.
function M.resize(delta, win)
  win = win or api.nvim_get_current_win()
  if pane_kind(win) then
    api.nvim_win_set_width(win, math.max(12, api.nvim_win_get_width(win) + delta))
  else
    api.nvim_win_call(win, function()
      vim.cmd(("vertical resize %s%d"):format(delta > 0 and "+" or "", delta))
    end)
  end
end

--- Forget remembered widths and put the three panes back to their defaults.
function M.reset()
  widths = {}
  save_widths()
  M.open()
end

local function is_editor(win)
  if not api.nvim_win_is_valid(win) or api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = api.nvim_win_get_buf(win)
  local bt, ft = vim.bo[buf].buftype, vim.bo[buf].filetype
  return ft ~= "neo-tree" and (bt == "" or bt == "help" or bt == "acwrite")
end

--- The window files should open in: the last editor window used, else any.
function M.editor_win()
  if last_editor and is_editor(last_editor) then
    return last_editor
  end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if is_editor(win) then
      return win
    end
  end
end

--- Move the cursor to the editor, creating an editor window if none is left.
function M.focus_editor()
  local win = M.editor_win()
  if not win then
    local term = require("console.term").win()
    if term then
      win = api.nvim_open_win(api.nvim_create_buf(true, false), false, { split = "left", win = term })
      require("console.term").resize()
    else
      vim.cmd("botright vnew")
      win = api.nvim_get_current_win()
    end
  end
  if vim.fn.mode() == "t" then
    vim.cmd.stopinsert()
  end
  api.nvim_set_current_win(win)
  return win
end

--- Build (or repair) the console: tree left, editor middle, terminals right.
function M.open()
  M.quiet()
  M.focus_editor()
  vim.cmd("Neotree show filesystem left dir=" .. vim.fn.fnameescape(vim.fn.getcwd()))
  local tree = tree_win()
  if tree then
    api.nvim_win_set_width(tree, M.width("tree") or TREE_DEFAULT)
  end
  require("console.term").open()
  require("console.term").resize()
  -- Share the middle evenly between editor splits; the side panes are fixed-width.
  vim.cmd("wincmd =")
  M.focus_editor()
end

--- Close the side panes (used around session saves).
function M.close_sides()
  M.quiet()
  pcall(vim.cmd, "Neotree close")
  require("console.term").hide()
end

function M.setup()
  local group = api.nvim_create_augroup("console_layout", { clear = true })

  api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      local win = api.nvim_get_current_win()
      if is_editor(win) then
        last_editor = win
      end
    end,
  })

  -- Remember side-pane widths the user sets (border drag or resize keys).
  api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
      if vim.o.columns ~= last_columns then
        last_columns = vim.o.columns -- the terminal itself was resized
        return
      end
      if vim.uv.now() < quiet_until then
        return
      end
      for _, win in ipairs(vim.v.event.windows or {}) do
        local kind = api.nvim_win_is_valid(win) and pane_kind(win)
        if kind and widths[kind] ~= api.nvim_win_get_width(win) then
          widths[kind] = api.nvim_win_get_width(win)
          save_widths()
        end
      end
    end,
  })

  -- Open the console when nvim starts with no file arguments (`nvim`,
  -- `nvim <dir>`, `ws <name>`). `nvim some/file`, `git commit`, pipes and
  -- diff mode get a plain editor.
  api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      local argc = vim.fn.argc()
      local dir_arg = argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1
      local interactive = #api.nvim_list_uis() > 0 or vim.g.console_force
      if (argc == 0 or dir_arg) and interactive and not vim.o.diff and not vim.g.console_stdin then
        vim.schedule(M.open)
      end
    end,
  })
  api.nvim_create_autocmd("StdinReadPre", {
    group = group,
    callback = function()
      vim.g.console_stdin = true
    end,
  })

  api.nvim_create_user_command("Console", M.open, { desc = "Open/repair the tree | editor | terminal layout" })
  api.nvim_create_user_command("ConsoleReset", M.reset, { desc = "Reset pane widths to their defaults" })
end

return M
