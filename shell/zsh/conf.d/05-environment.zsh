# Environment: secrets, PATH, package managers, and the machine layers.
#
# Runs at 05 because 10-completion.zsh needs $HOMEBREW_PREFIX to assemble
# fpath, and needs $LS_COLORS (00-options.zsh) for its list-colors.
#
# The work is entirely shared with bash. path_append (shared/lib.sh) already
# deduplicates, but `typeset -U` is kept as well: it also covers entries added
# by anything outside this config, such as `brew shellenv` or /etc/profile.d.

typeset -U path PATH fpath

source $DOTFILES_SHELL/shared/05-environment.sh
