# The NAS. Sourced by conf.d/05-environment.zsh when ZSH_MACHINE=sheik, or
# when the short hostname matches.
#
# Tracked in git, so nothing secret goes here -- secrets live in ~/.zsh.local.

# Watch filesystem activity under the pools. fatrace uses fanotify, so this is
# Linux-only, which is implied by the machine rather than guarded for.
alias fatrace-home='cd /mnt/tank/home && sudo fatrace -c && cd -'
alias fatrace-backup='cd /mnt/tank/backup && sudo fatrace -c && cd -'
