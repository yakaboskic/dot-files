# System Admin Repo
Contains configuration file customizations for applications, install scripts, and other sys admin things I wanted to keep backup and up-to-date.

## Neovim console (current setup)

A lightweight stand-in for VS Code when most of the coding is done by an agent
and the editor is mainly for watching: file tree on the left, files in the
middle, tabbed terminals on the right.

```sh
./install.sh        # links nvim/ and bin/ws into place, installs plugins
ws                  # list workspaces
ws <name>           # open one
```

| Path | Installed as | What it is |
| --- | --- | --- |
| `nvim/` | `~/.config/nvim` | Neovim config. Keys are in [`nvim/KEYS.md`](nvim/KEYS.md) (`Space ?` inside nvim). |
| `bin/ws` | `~/.local/bin/ws` | Workspace tool: builds a folder of symlinks from a VS Code `.code-workspace` file. `ws help` for commands. |

Both are symlinks into this repo, so editing the installed files edits the repo.

### Workspaces

A workspace is a real directory in `~/src/workspaces` (override with
`$WS_HOME`) holding one symlink per root folder. The list of roots lives in
`<name>.code-workspace` beside it, in VS Code's format, so existing VS Code
workspaces work as they are: `ws sync <name>` builds the links.

```sh
ws new papers ~/src/papers/a ~/src/blogs/b    # create
ws add papers ~/src/papers/c                  # add a root
ws rm papers b                                # drop a root (the folder is untouched)
```

### Neovim config layout

```text
nvim/init.lua
nvim/lua/console/
  plugins.lua    plugin list (built-in vim.pack; versions pinned in nvim-pack-lock.json)
  options.lua    editor options
  layout.lua     the three panes; opens them on `nvim` / `nvim <dir>`, not on `nvim <file>`
  tree.lua       Neo-tree, plus git status and reveal through symlinked roots
  term.lua       right-hand terminal pane with tabs
  search.lua     fzf-lua find/grep that follows the symlinks
  git.lua        gitsigns change markers
  watch.lua      reload files changed on disk
  session.lua    auto-session: reopen files and splits per workspace
  roots.lua      workspace path <-> real path conversion
  keymaps.lua
```

Requires Neovim 0.12+, `ripgrep`, `fd`, `fzf`. Icons need a Nerd Font: set the
terminal font to one, then flip `vim.g.have_nerd_font` in `nvim/init.lua`.
Update plugins with `:lua vim.pack.update()` and commit the lockfile.

## Older files

`dot-files/linux/generic/`, `install-wsl.sh` and `wsl/` are the previous
Linux/WSL setup (bash, vim, git config), kept as they were.
