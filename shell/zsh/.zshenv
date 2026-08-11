# Bootstrap. The only file zsh reads out of $HOME (via a symlink), because ZDOTDIR cannot be
# consulted until something sets it. Keep it minimal and side-effect-free: it
# runs for EVERY zsh, including `ssh host cmd`, shebangs and subshells.

# This file's real directory, resolving the ~/.zshenv symlink
ZDOTDIR=${${(%):-%N}:A:h}

# The shell/ directory, where the shared/ files live.
DOTFILES_SHELL=${ZDOTDIR:h}

: ${XDG_CACHE_HOME:=$HOME/.cache}
export XDG_CACHE_HOME

# Per-shell. See cached_eval in shared/lib.sh
ZSH_CACHE_DIR=$XDG_CACHE_HOME/zsh
DOTFILES_CACHE_DIR=$ZSH_CACHE_DIR

# Opt out of session save/restore in macOS terminal
SHELL_SESSIONS_DISABLE=1
