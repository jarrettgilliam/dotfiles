# Shell options and environment.

# Environment variables and ls colors, shared with bash.
source $DOTFILES_SHELL/shared/00-options.sh

# ---------------------------------------------------------------------------
# History
#
# HISTFILE is pinned deliberately. macOS /etc/zshrc does
#     HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# which, now that ZDOTDIR is set, would silently relocate history INTO this
# repo -- orphaning the existing ~/.zsh_history and accumulating a new one
# inside git. /etc/zshrc has already run by this point, so this must be an
# unconditional assignment rather than a `[[ -z $HISTFILE ]]` guard.
#
# bash keeps its own history in ~/.bash_history: the file formats differ, so
# the two shells cannot share one.
# ---------------------------------------------------------------------------
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=10000

setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

# Changing directories
setopt auto_cd
setopt auto_pushd
unsetopt pushd_ignore_dups
setopt pushdminus

# Required for the dynamic sections of $PROMPT / $RPROMPT.
setopt prompt_subst
