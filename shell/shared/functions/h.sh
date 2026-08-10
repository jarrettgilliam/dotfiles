# Search shell history. Each argument narrows the result further.
#
# The two shells disagree on how to ask for the whole history: zsh's `history`
# defaults to the last 16 entries and needs `history 0` for everything, while
# bash's `history` already prints the lot and rejects a 0 argument. That is the
# only difference, so it is branched inside the one function rather than
# maintaining two.
h() {
    local sresult x

    if [ -n "${ZSH_VERSION-}" ]; then
        sresult=$(history 0)
    else
        sresult=$(history)
    fi

    for x in "$@"; do
        sresult=$(printf '%s\n' "$sresult" | grep -aiE "$x")
    done

    printf '%s\n' "$sresult" | tail -n 20
}
