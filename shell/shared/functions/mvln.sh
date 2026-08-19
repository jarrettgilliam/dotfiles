# Move one or more files/folders, leaving a symlink at each original location.
# Relative destinations need GNU coreutils for `realpath -m --relative-to`;
# absolute destinations work everywhere.
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
