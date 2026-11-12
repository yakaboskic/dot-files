# Console keys

Leader is `Space`. The mouse works everywhere: click a pane to focus it, click
terminal tabs, drag the borders between panes, double-click in the tree.

## Moving between panes

| Keys | Action |
| --- | --- |
| `Space h` / `Space l` | Pane to the left / right (also `j` / `k`) |
| `Space e` | Jump to the file tree |
| `Space tt` | Jump to the terminal and start typing |
| `Ctrl-\ h` | From a terminal, back to the editor |

## Resizing panes

Widths you set are remembered, including after you hide a pane or restart.

| Keys | Action |
| --- | --- |
| drag a border | Resize with the mouse |
| `Space +` / `Space -` | Make the pane you are in wider / narrower |
| `Ctrl-\ +` / `Ctrl-\ -` | Same for the terminal pane, while typing in it |
| `Space =` | Back to the default widths |

## Files

| Keys | Action |
| --- | --- |
| `Space ff` or `Ctrl-p` | Find a file by name, across every root |
| `Space fg` | Search text across every root |
| `Space fw` | Search for the word under the cursor |
| `Space fb` | Switch between open files |
| `Space fo` | Recently opened files |
| `Space fr` | Reopen the last search |
| `Space w` | Save |
| `Space x` | Close the file, keep the window |
| `Space q` | Close the window |
| `Space Q` | Quit (asks once if files are unsaved or terminals are running) |

## File tree

| Keys | Action |
| --- | --- |
| `Enter` or double-click | Open file / expand folder |
| `s` / `S` | Open in a vertical / horizontal split |
| `a` `d` `r` `m` | Add, delete, rename, move |
| `H` | Show or hide filtered files |
| `R` | Refresh |
| `?` | All tree keys |
| `Space E` | Show or hide the tree |

Marks beside a name: `M` modified, `?` untracked, `A` added, `D` deleted,
`+` staged. Git-ignored files are shown dimmed. The tree follows the file you
are looking at; `:let g:console_follow = v:false` turns that off.

## Terminal tabs

Everything you type in a terminal goes to the program, `Esc` included. Only the
`Ctrl-\` prefix is reserved.

| Keys | Action |
| --- | --- |
| `Ctrl-\ c` or click `+` | New tab |
| `Ctrl-\ n` / `Ctrl-\ p` | Next / previous tab |
| `Ctrl-\ 1` … `9` or click | Go to tab |
| click `×` or middle-click | Close tab (ends its process) |
| `Ctrl-\ Ctrl-n` | Stop typing so you can scroll and copy; `i` to type again |
| `Space th` | Hide or show the pane (processes keep running) |
| `Space tr` | Rename the tab |
| `:Term claude` | New tab that runs a command |

From the editor, `Space tc` / `tn` / `tp` / `tx` do new / next / previous / close.
Scrolling with the mouse wheel leaves typing mode; press `i` to go back.

## Changes

| Keys | Action |
| --- | --- |
| `]h` / `[h` | Next / previous changed block in the file |
| `Space gp` | Preview what changed in this block |
| `Space gd` | Side-by-side diff of the file against git |
| `Space gb` | Who last changed this line |

Open files reload on their own when something else rewrites them.
