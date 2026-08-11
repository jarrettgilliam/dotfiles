# Environment shared by both shells.

export VISUAL=vim
export EDITOR=vim
export NMON=cmnd
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# ls colors. Kept together here rather than split across os/, and set this
# early because zsh's 10-completion.zsh feeds $LS_COLORS to its list-colors.
# https://apple.stackexchange.com/a/33679/294425
# https://geoff.greer.fm/lscolors/
export LS_COLORS='di=1;34:ln=1;36:so=1;31:pi=1;33:ex=1;32:bd=1;34;46:cd=1;34;43:su=1;33;42:sg=1;0;42:tw=1;36;44:ow=1;34'

case "$OSTYPE" in
    darwin*)
        export CLICOLOR=1
        export LSCOLORS='ExGxBxDxCxEgEdDcXcGeEx'
        ;;
esac
