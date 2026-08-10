# Move one or more files/folders, leaving a symlink at each original location.
#
#   mvln <source1> [source2...] <destination>
#
# NOTE: the relative-path branch uses `realpath -m --relative-to`, which is
# GNU coreutils only. macOS ships a BSD realpath without those flags, so
# relative destinations will fail there unless coreutils is installed.
# Absolute destinations work everywhere.
mvln() {
    if [ $# -lt 2 ]; then
        printf 'Usage: mvln <source1> [source2...] <destination>\n' >&2
        return 1
    fi

    local dest="${@: -1}"
    local total=$#
    local count=0
    local src new_path target

    mv "$@" || return 1

    for src in "$@"; do
        count=$((count + 1))
        [ "$count" -eq "$total" ] && break

        if [ -d "$dest" ]; then
            new_path="$dest/$(basename "$src")"
        else
            new_path="$dest"
        fi

        case "$dest" in
            /*) target="$(realpath "$new_path")" ;;
            *)  target="$(realpath -m --relative-to="$(dirname "$src")" "$new_path")" ;;
        esac

        ln -s "$target" "$src"
    done
}
