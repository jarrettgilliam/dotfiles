# Helpers used by the shared config and by both shells' own files.
# Sourced first, before anything in conf.d.

# has_command <name>
#
# Matches functions and aliases too, which 50-aliases.sh relies on: the nvm
# stubs in 05-environment.sh are functions
has_command() {
    command -v "$1" >/dev/null 2>&1
}

is_interactive() {
    case $- in
        *i*) return 0 ;;
        *)   return 1 ;;
    esac
}

current_shell() {
    if [ -n "${ZSH_VERSION-}" ]; then
        printf 'zsh\n'
    else
        printf 'bash\n'
    fi
}

# path_prepend / path_append <dir>
#
# The surrounding colons match whole entries only, so /usr/bin is not
# considered present because /usr/bin/local is
path_prepend() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

path_append() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$PATH:$1" ;;
    esac
}

# cached_eval <cache-name> <command> [args...]
#
# Sources a tool's init output from a cache, regenerating only when the binary
# is newer. Keyed by shell, since the generated scripts differ. Writes through
# a temp file so a failed run cannot leave a truncated cache behind.
cached_eval() {
    local name=$1; shift
    local bin
    bin=$(command -v "$1" 2>/dev/null) || return 0
    [ -n "$bin" ] || return 0

    local cache="$DOTFILES_CACHE_DIR/$name.$(current_shell)"
    if [ ! -s "$cache" ] || [ "$bin" -nt "$cache" ]; then
        local tmp="$cache.$$"
        if "$@" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
            command mv -f "$tmp" "$cache"
        else
            command rm -f "$tmp"
            return 1
        fi
    fi
    # shellcheck disable=SC1090
    . "$cache"
}
