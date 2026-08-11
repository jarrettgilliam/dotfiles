# Search shell history. Each argument narrows the result further.
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
