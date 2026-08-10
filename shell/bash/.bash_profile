# Login shells.
#
# bash reads this file INSTEAD OF ~/.bashrc for login shells, not as well as --
# which matters because macOS Terminal opens a login shell for every tab. So
# this exists only to hand straight over.
#
# There is nothing login-specific in the config: PATH and environment are set
# from conf.d/05-environment, which runs for every interactive shell, so that
# tmux panes and nested shells get them too.

[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
