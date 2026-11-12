-- Workspace roots: the symlinks in the working directory and where they point.
--
-- Two spellings of every file exist: the workspace path (workspace/root/file,
-- through the symlink) and the real path. Neovim itself resolves directory
-- symlinks when it opens a relative path, so buffers carry real paths, while
-- the file tree is built from workspace paths. These helpers convert.
local uv = vim.uv
local M = {}

local cache = { at = -1e9, cwd = nil, list = {} }

--- { { name = "root", link = "<cwd>/root", real = "/real/path" }, ... }
function M.list()
  local cwd, now = vim.fn.getcwd(), uv.now()
  if cache.cwd ~= cwd or now - cache.at > 2000 then
    cache.cwd, cache.at, cache.list = cwd, now, {}
    for name, kind in vim.fs.dir(cwd) do
      if kind == "link" then
        local real = uv.fs_realpath(cwd .. "/" .. name)
        if real then
          cache.list[#cache.list + 1] = { name = name, link = cwd .. "/" .. name, real = real }
        end
      end
    end
  end
  return cache.list
end

local function swap(path, from, to)
  if type(path) ~= "string" then
    return path, false
  end
  for _, root in ipairs(M.list()) do
    local prefix = root[from]
    if path == prefix then
      return root[to], true
    elseif path:sub(1, #prefix + 1) == prefix .. "/" then
      return root[to] .. path:sub(#prefix + 1), true
    end
  end
  return path, false
end

--- workspace/root/file -> /real/path/file (unchanged if not under a root)
function M.to_real(path)
  return (swap(path, "link", "real"))
end

--- /real/path/file -> workspace/root/file; second value says whether it matched
function M.to_workspace(path)
  return swap(path, "real", "link")
end

--- Short name for display: "root/sub/file" for workspace files.
function M.display(path)
  if path == "" then
    return "[No Name]"
  end
  local ws, matched = M.to_workspace(path)
  if matched then
    return ws:sub(#vim.fn.getcwd() + 2)
  end
  return vim.fn.fnamemodify(path, ":~:.")
end

return M
