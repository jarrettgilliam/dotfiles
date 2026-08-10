# Bootstrap. This is the only file zsh reads out of $HOME (via a symlink),
# because ZDOTDIR cannot be consulted until something sets it.
#
# Keep this file minimal and side-effect-free: it runs for EVERY zsh, including
# non-interactive ones (`ssh host cmd`, script shebangs, subshells).

# This file's real directory, resolving the ~/.zshenv symlink.
# %N is the current script; :A makes it absolute+resolved, :h takes the dirname.
ZDOTDIR=${${(%):-%N}:A:h}

# Deliberately NOT exported. Every zsh re-reads ~/.zshenv and re-derives this,
# so exporting buys nothing -- but an exported ZDOTDIR would follow you into
# `sudo -s` and point root's shell at this config.

: ${XDG_CACHE_HOME:=$HOME/.cache}
export XDG_CACHE_HOME
ZSH_CACHE_DIR=$XDG_CACHE_HOME/zsh

# Terminal.app's per-session save/restore writes to
# "${ZDOTDIR:-$HOME}/.zsh_sessions" -- and since ZDOTDIR is now this
# repository, that means session state AND per-session command history would
# accumulate inside version control. /etc/zshrc_Apple_Terminal assigns
# SHELL_SESSION_DIR unconditionally, so it cannot be redirected; disabling the
# feature is the only lever, and this is the variable Apple documents for it.
#
# Cost: Terminal no longer restores per-tab scrollback history on reopen. The
# normal shared $HISTFILE is unaffected. Delete this line to get it back.
SHELL_SESSIONS_DISABLE=1
