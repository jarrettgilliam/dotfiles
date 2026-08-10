# This MacBook. Sourced by conf.d/05-environment.zsh when ZSH_MACHINE=majora,
# or when the short hostname matches.
#
# Tracked in git, so nothing secret goes here -- secrets live in ~/.zsh.local.
# Paths use $HOME rather than /Users/jarrett so the file survives a rename.

# Personal scripts. The directory name contains a space, hence the quoting.
[[ -d "$HOME/Code/Shell/Mac Commands" ]] && path+=("$HOME/Code/Shell/Mac Commands")

[[ -d "$HOME/Library/Python/3.8/bin" ]] && path+=("$HOME/Library/Python/3.8/bin")

# .NET iOS workload tooling.
#
# Pinned to the version the old ~/.zprofile used. Note that 16.4.60 and
# 16.4.7099 are also installed -- this pin is the oldest of the three. Bump it
# (or switch to a newest-wins glob) if that is not deliberate.
_ios_sdk=/usr/local/share/dotnet/packs/Microsoft.iOS.Sdk/15.4.447/tools/bin
[[ -d $_ios_sdk ]] && path+=($_ios_sdk)
unset _ios_sdk
