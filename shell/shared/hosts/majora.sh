# This MacBook. Sourced by shared/05-environment.sh when SHELL_MACHINE=majora,
# or when the short hostname matches.
#
# Tracked in git, so nothing secret goes here -- secrets live in
# ~/.shell.local. Paths use $HOME rather than /Users/jarrett so the file
# survives a rename.

# Personal scripts. The directory name contains a space, hence the quoting.
path_append "$HOME/Code/Shell/Mac Commands"

path_append "$HOME/Library/Python/3.8/bin"

# .NET iOS workload tooling.
#
# Pinned to the version the old ~/.zprofile used. Note that 16.4.60 and
# 16.4.7099 are also installed -- this pin is the oldest of the three. Bump it
# (or switch to a newest-wins glob) if that is not deliberate.
path_append /usr/local/share/dotnet/packs/Microsoft.iOS.Sdk/15.4.447/tools/bin
