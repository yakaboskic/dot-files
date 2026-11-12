-- Right pane: several terminals sharing one split, with a clickable tab strip.
--
-- Keys typed in a terminal go to the program untouched (Esc included), so
-- TUIs such as Claude Code behave exactly as they do in a bare terminal. The
-- only keys taken are behind the Ctrl-\ prefix.
local api = vim.api
local M = {}

local S = { terms = {}, active = 0, win = nil }

local function pane_width()
  return require("console.layout").width("term") or math.max(40, math.min(110, math.floor(vim.o.columns * 0.36)))
end

local function pane_open()
  return S.win ~= nil and api.nvim_win_is_valid(S.win)
end

local function redraw()
  vim.cmd("redrawstatus!")
end

local function show(buf)
  if not pane_open() then
    require("console.layout").quiet()
    S.win = api.nvim_open_win(buf, false, { split = "right", win = -1, width = pane_width() })
    local wo = vim.wo[S.win]
    wo.winfixwidth = true
    wo.number = false
    wo.relativenumber = false
    wo.signcolumn = "no"
    wo.cursorline = false
    wo.winbar = "%!v:lua.require'console.term'.winbar()"
  else
    vim.wo[S.win].winfixbuf = false
    api.nvim_win_set_buf(S.win, buf)
  end
  vim.wo[S.win].winfixbuf = true -- files never open in the terminal pane
end

local function index_of(buf)
  for i, t in ipairs(S.terms) do
    if t.buf == buf then
      return i
    end
  end
end

-- Tab strip -----------------------------------------------------------------

function M.winbar()
  local parts = {}
  for i, t in ipairs(S.terms) do
    local hl = i == S.active and "%#TabLineSel#" or "%#TabLine#"
    local name = t.name:gsub("%%", "%%%%")
    parts[#parts + 1] = ("%s%%%d@v:lua.ConsoleTermSelect@ %d %s %%X%%%d@v:lua.ConsoleTermClose@× %%X"):format(
      hl,
      i,
      i,
      name,
      i
    )
  end
  parts[#parts + 1] = "%#TabLineFill#%@v:lua.ConsoleTermNew@ + %X"
  return table.concat(parts)
end

function _G.ConsoleTermSelect(idx, _, button)
  if button == "m" then
    M.close(idx)
  else
    M.select(idx)
  end
end

function _G.ConsoleTermClose(idx)
  M.close(idx)
end

function _G.ConsoleTermNew()
  M.new()
end

-- Terminals -----------------------------------------------------------------

local function on_exit(buf)
  local idx = index_of(buf)
  if not idx then
    return
  end
  table.remove(S.terms, idx)
  if #S.terms == 0 then
    S.active = 0
    if pane_open() then
      pcall(api.nvim_win_close, S.win, true)
    end
    S.win = nil
  else
    if S.active > idx or S.active > #S.terms then
      S.active = S.active - 1
    end
    S.active = math.max(S.active, 1)
    if pane_open() then
      show(S.terms[S.active].buf)
      if api.nvim_get_current_win() == S.win then
        vim.cmd.startinsert()
      end
    end
  end
  if api.nvim_buf_is_valid(buf) then
    pcall(api.nvim_buf_delete, buf, { force = true })
  end
  redraw()
end

local function set_keys(buf)
  local function tmap(lhs, fn, desc)
    vim.keymap.set("t", lhs, fn, { buffer = buf, desc = desc })
  end
  tmap([[<C-\>h]], function()
    require("console.layout").focus_editor()
  end, "Focus editor")
  tmap([[<C-\>+]], function()
    require("console.layout").resize(5, S.win)
  end, "Wider terminal pane")
  tmap([[<C-\>-]], function()
    require("console.layout").resize(-5, S.win)
  end, "Narrower terminal pane")
  tmap([[<C-\>c]], function()
    M.new()
  end, "New terminal tab")
  tmap([[<C-\>n]], function()
    M.cycle(1)
  end, "Next terminal tab")
  tmap([[<C-\>p]], function()
    M.cycle(-1)
  end, "Previous terminal tab")
  for i = 1, 9 do
    tmap([[<C-\>]] .. i, function()
      M.select(i)
    end, "Terminal tab " .. i)
  end
end

--- Open a new terminal tab.
--- opts.run   command typed into the new shell (the tab stays when it exits)
--- opts.name  tab label (default: first word of `run`, else the shell name)
--- opts.cwd   starting directory (default: nvim's working directory)
--- opts.focus false to leave the cursor where it is
function M.new(opts)
  opts = opts or {}
  local buf = api.nvim_create_buf(false, false)
  vim.bo[buf].bufhidden = "hide"
  show(buf)

  local job
  api.nvim_win_call(S.win, function()
    -- "-i" is a no-op for an interactive shell, but it keeps Neovim's default
    -- TermClose handler (which deletes buffers whose command is exactly
    -- 'shell') from closing the whole pane when one tab's shell exits.
    job = vim.fn.jobstart({ vim.o.shell, "-i" }, {
      term = true,
      cwd = opts.cwd or vim.fn.getcwd(),
      on_exit = function()
        vim.schedule(function()
          on_exit(buf)
        end)
      end,
    })
  end)
  if not job or job <= 0 then
    vim.notify("console: could not start " .. vim.o.shell, vim.log.levels.ERROR)
    pcall(api.nvim_buf_delete, buf, { force = true })
    return
  end

  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "console_term"
  set_keys(buf)

  local name = opts.name
  if not name and opts.run then
    name = vim.fn.fnamemodify(opts.run:match("%S+") or "", ":t")
  end
  if not name or name == "" then
    name = vim.fn.fnamemodify(vim.o.shell, ":t")
  end
  S.terms[#S.terms + 1] = { buf = buf, job = job, name = name }
  S.active = #S.terms

  if opts.run then
    vim.fn.chansend(job, opts.run .. "\n")
  end
  redraw()
  if opts.focus ~= false then
    M.focus()
  end
  return buf
end

function M.select(idx)
  local t = S.terms[idx]
  if not t then
    return
  end
  S.active = idx
  show(t.buf)
  redraw()
  M.focus()
end

function M.cycle(step)
  if #S.terms > 0 then
    M.select((S.active - 1 + step) % #S.terms + 1)
  end
end

--- Close a tab (default: the active one). Ends the process running in it.
function M.close(idx)
  local t = S.terms[idx or S.active]
  if t then
    vim.fn.jobstop(t.job)
  end
end

function M.rename(name)
  local t = S.terms[S.active]
  if t and name and name ~= "" then
    t.name = name
    redraw()
  end
end

--- Show the pane (starting a shell if there is none) without moving the cursor.
function M.open()
  if #S.terms == 0 then
    M.new({ focus = false })
  elseif not pane_open() then
    show(S.terms[S.active].buf)
  end
end

--- Hide the pane. Terminals keep running.
function M.hide()
  if pane_open() then
    require("console.layout").quiet()
    if api.nvim_get_current_win() == S.win then
      vim.cmd.stopinsert()
      vim.cmd.wincmd("p")
    end
    pcall(api.nvim_win_close, S.win, true)
  end
  S.win = nil
end

function M.toggle()
  if pane_open() then
    M.hide()
  else
    M.focus()
  end
end

function M.focus()
  M.open()
  if pane_open() then
    api.nvim_set_current_win(S.win)
    vim.cmd.startinsert()
  end
end

function M.count()
  return #S.terms
end

function M.is_open()
  return pane_open()
end

function M.win()
  return pane_open() and S.win or nil
end

function M.resize()
  if pane_open() then
    require("console.layout").quiet()
    api.nvim_win_set_width(S.win, pane_width())
  end
end

function M.setup()
  local group = api.nvim_create_augroup("console_term", { clear = true })

  -- Entering the pane (click or window motion) means "type into the terminal".
  api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      if pane_open() and api.nvim_get_current_win() == S.win then
        vim.cmd.startinsert()
      end
    end,
  })

  -- The pane was closed with :q or similar: forget the window, keep the jobs.
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(ev)
      if S.win and tonumber(ev.match) == S.win then
        S.win = nil
      end
    end,
  })

  local cmd = api.nvim_create_user_command
  cmd("Term", function(a)
    M.new({ run = a.args ~= "" and a.args or nil })
  end, { nargs = "*", complete = "shellcmd", desc = "New terminal tab, optionally running a command" })
  cmd("TermToggle", M.toggle, { desc = "Show/hide the terminal pane" })
  cmd("TermRename", function(a)
    M.rename(a.args)
  end, { nargs = 1, desc = "Rename the active terminal tab" })
  cmd("TermClose", function()
    M.close()
  end, { desc = "Close the active terminal tab" })
end

return M
