# Linux, including WSL and the Steam Deck. Sourced by conf.d/05-environment.zsh.
#
# Everything that only makes sense on this OS goes here -- environment, PATH
# and aliases alike.

# Distro profile scripts. Many set environment variables; some also print
# banners, which are suppressed for non-interactive shells so they cannot
# corrupt the output of `ssh host cmd`.
if [[ -d /etc/profile.d ]]; then
    for _profile in /etc/profile.d/*.sh(N); do
        [[ -r $_profile ]] || continue
        if [[ -o interactive ]]; then
            source $_profile
        else
            source $_profile >/dev/null
        fi
    done
    unset _profile
fi

alias poweroff='sudo poweroff'
alias reboot='sudo reboot'
