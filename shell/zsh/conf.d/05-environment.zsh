# Environment: secrets, PATH, package managers, and the machine layers.

# path_append already deduplicates; `typeset -U` also covers entries added from
# outside this config, such as `brew shellenv` or /etc/profile.d
typeset -U path PATH fpath

source $DOTFILES_SHELL/shared/05-environment.sh
