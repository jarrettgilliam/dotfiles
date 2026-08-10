# Completion.
#
# bash has no compinit: completions come from the bash-completion package,
# which is not installed by default anywhere. Sourced if present, silently
# skipped otherwise -- the same config runs on a NAS and a Steam Deck.
#
# Install with `brew install bash-completion@2` on macOS, or the distro's
# bash-completion package on Linux. Note @2 needs bash 4.2+, so on Apple's
# stock 3.2 the v1 package is the only option.

for _bc in \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/etc/profile.d/bash_completion.sh" \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion
do
    if [ -r "$_bc" ]; then
        . "$_bc"
        break
    fi
done
unset _bc
