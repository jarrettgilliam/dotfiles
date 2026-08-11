# Aliases and functions
source $DOTFILES_SHELL/shared/50-aliases.sh

# zmv, for bulk renames: mmv '*.txt' '*.md'
autoload -Uz zmv
alias mmv='noglob zmv -W'
