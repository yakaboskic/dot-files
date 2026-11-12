#!/bin/sh
# Link the Neovim console config and the `ws` workspace tool into place.
# Safe to re-run. Anything already at a destination that is not our symlink is
# moved aside to <name>.backup-<timestamp>, never deleted.
set -eu

REPO=$(cd "$(dirname "$0")" && pwd)

link() { # link <source in repo> <destination>
    src=$1 dest=$2
    mkdir -p "$(dirname "$dest")"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "ok       $dest"
        return
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$dest" "$backup"
        echo "moved    $dest -> $backup"
    fi
    ln -s "$src" "$dest"
    echo "linked   $dest -> $src"
}

if command -v brew >/dev/null 2>&1; then
    for formula in neovim ripgrep fd fzf; do
        brew list --formula "$formula" >/dev/null 2>&1 || brew install "$formula"
    done
else
    echo "note: Homebrew not found; install neovim (0.12+), ripgrep, fd and fzf yourself"
fi

link "$REPO/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
link "$REPO/bin/ws" "$HOME/.local/bin/ws"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "note: add \$HOME/.local/bin to PATH to use ws" ;;
esac

if command -v nvim >/dev/null 2>&1; then
    echo "installing Neovim plugins (pinned by nvim/nvim-pack-lock.json)..."
    nvim --headless +qa
    echo
fi

echo "done. Open a workspace with:  ws <name>     (list them with: ws)"
