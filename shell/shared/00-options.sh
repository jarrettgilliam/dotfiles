# Environment shared by both shells.
#
# History and shell options are NOT here: they are spelled differently in bash
# and zsh, so each shell's own 00-options file handles them.

export VISUAL=vim
export EDITOR=vim
export NMON=cmnd
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# ---------------------------------------------------------------------------
# ls colors
#
# All three variables are the same topic, so they stay together rather than
# being split across os/ files: LS_COLORS is read by GNU ls, and CLICOLOR /
# LSCOLORS by BSD ls. Setting the BSD pair on Linux is harmless, but it is
# guarded anyway to document which platform each belongs to.
#
# Must be set before zsh's 10-completion.zsh, which derives its completion
# list-colors from $LS_COLORS.
#
# https://apple.stackexchange.com/a/33679/294425
# https://geoff.greer.fm/lscolors/
# ---------------------------------------------------------------------------
export LS_COLORS='di=1;34:ln=1;36:so=1;31:pi=1;33:ex=1;32:bd=1;34;46:cd=1;34;43:su=1;33;42:sg=1;0;42:tw=1;36;44:ow=1;34'

# $OSTYPE is set by both bash and zsh.
case "$OSTYPE" in
    darwin*)
        export CLICOLOR=1
        export LSCOLORS='ExGxBxDxCxEgEdDcXcGeEx'
        ;;
esac
