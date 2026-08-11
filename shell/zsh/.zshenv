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

# Terminal.app writes per-session state to "${ZDOTDIR:-$HOME}/.zsh_sessions",
# which now resolves inside this repository. SHELL_SESSION_DIR is assigned
# unconditionally by /etc/zshrc_Apple_Terminal, so disabling is the only lever.
# Costs per-tab scrollback restore on reopen; $HISTFILE is unaffected.
SHELL_SESSIONS_DISABLE=1
