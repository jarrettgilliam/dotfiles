# The NAS. Sourced by shared/05-environment.sh when SHELL_MACHINE=sheik, or
# when the short hostname matches.
#
# Tracked in git, so nothing secret goes here -- secrets live in
# ~/.shell.local.

# Watch filesystem activity under the pools. fatrace uses fanotify, so this is
# Linux-only, which is implied by the machine rather than guarded for.
alias fatrace-home='cd /mnt/tank/home && sudo fatrace -c && cd -'
alias fatrace-backup='cd /mnt/tank/backup && sudo fatrace -c && cd -'
