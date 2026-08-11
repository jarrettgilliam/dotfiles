# Linux, including WSL and the Steam Deck.

# Distro profile scripts. Banners are suppressed for non-interactive shells so
# they cannot corrupt the output of `ssh host cmd`
if [ -d /etc/profile.d ]; then
    for _profile in /etc/profile.d/*.sh; do
        [ -r "$_profile" ] || continue
        if is_interactive; then
            . "$_profile"
        else
            . "$_profile" >/dev/null
        fi
    done
    unset _profile
fi

alias poweroff='sudo poweroff'
alias reboot='sudo reboot'
