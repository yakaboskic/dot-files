-- Files change underneath this editor all the time (agents write them), so
-- reload buffers from disk without waiting for a focus event. Buffers with
-- unsaved edits are never overwritten silently; nvim asks first.
vim.o.autoread = true

local function check()
  if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
    vim.cmd("silent! checktime")
  end
end

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("console_watch", { clear = true }),
  callback = check,
})

local timer = vim.uv.new_timer()
timer:start(1000, 1000, vim.schedule_wrap(check))
