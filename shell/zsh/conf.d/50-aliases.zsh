# Aliases and functions.
#
# Nearly all of it is shared with bash, including the nine functions, which
# are plain definitions in shared/functions/ rather than autoload bodies.
source $DOTFILES_SHELL/shared/50-aliases.sh

# ---------------------------------------------------------------------------
# zsh-only additions.
# ---------------------------------------------------------------------------

# zmv, for bulk renames: mmv '*.txt' '*.md'. No bash equivalent.
autoload -Uz zmv
alias mmv='noglob zmv -W'
