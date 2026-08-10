# Make a directory and cd into it.
mkcd() {
    mkdir -p "$@" && cd "$1" || return
}
