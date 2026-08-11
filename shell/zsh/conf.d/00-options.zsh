# Shell options and environment.

source $DOTFILES_SHELL/shared/00-options.sh

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
