# Move something and follow it to its destination.
mvcd() {
    mv "$@" && cd "${@: -1}" || return
}
