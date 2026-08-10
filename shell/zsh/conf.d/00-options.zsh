# Shell options and environment.

# ---------------------------------------------------------------------------
# History
#
# HISTFILE is pinned deliberately. macOS /etc/zshrc does
#     HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# which, now that ZDOTDIR is set, would silently relocate history INTO this
# repo -- orphaning the existing ~/.zsh_history and accumulating a new one
# inside git. /etc/zshrc has already run by this point, so this must be an
# unconditional assignment rather than a `[[ -z $HISTFILE ]]` guard.
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

# Environment
export VISUAL=vim
export EDITOR=vim
export NMON=cmnd
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# ---------------------------------------------------------------------------
# ls colours
#
# All three variables are the same topic, so they stay together rather than
# being split across os/ files: LS_COLORS is read by GNU ls, and CLICOLOR /
# LSCOLORS by BSD ls. Setting the BSD pair on Linux is harmless, but it is
# guarded anyway to document which platform each belongs to.
#
# Must be set before 10-completion.zsh, which derives its completion
# list-colors from $LS_COLORS.
#
# https://apple.stackexchange.com/a/33679/294425
# https://geoff.greer.fm/lscolors/
# ---------------------------------------------------------------------------
export LS_COLORS='di=1;34:ln=1;36:so=1;31:pi=1;33:ex=1;32:bd=1;34;46:cd=1;34;43:su=1;33;42:sg=1;0;42:tw=1;36;44:ow=1;34'

if [[ $OSTYPE == darwin* ]]; then
    export CLICOLOR=1
    export LSCOLORS='ExGxBxDxCxEgEdDcXcGeEx'
fi
