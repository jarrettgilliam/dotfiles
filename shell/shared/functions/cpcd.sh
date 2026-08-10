# Copy something and follow it to its destination.
cpcd() {
    cp -r "$@" && cd "${@: -1}" || return
}
