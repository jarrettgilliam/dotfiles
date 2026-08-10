# Helpers used by the shared config and by both shells' own files.
#
# Sourced first, before anything in conf.d. Everything here must work in bash
# and zsh alike, which rules out arrays -- they index differently -- but allows
# `local`, `[[ ]]` and `$(( ))`.

# has_command <name>
#
# True for external commands, shell functions and aliases. Replaces zsh's
# (( $+commands[x] )), and the wider net matters: the nvm stubs in
# 05-environment.sh are functions, so the old config needed a second
# $+functions[x] test to notice them.
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# is_interactive
#
# The portable spelling of zsh's [[ -o interactive ]].
is_interactive() {
    case $- in
        *i*) return 0 ;;
        *)   return 1 ;;
    esac
}

# current_shell
#
# "zsh" or "bash". Used to pick per-shell cache files and, in a couple of
# functions, per-shell builtins.
current_shell() {
    if [ -n "${ZSH_VERSION-}" ]; then
        printf 'zsh\n'
    else
        printf 'bash\n'
    fi
}

# path_prepend / path_append <dir>
#
# Add a directory to $PATH if it exists and is not already there. Replaces
# zsh's `path+=(...)` with `typeset -U path`, which has no bash equivalent.
# The surrounding colons make the test match whole entries only, so /usr/bin
# is not considered present because /usr/bin/local is.
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
# Sources a tool's shell-init output from a cache file, regenerating only when
# the tool's binary is newer than the cache. kubectl in particular costs tens
# of milliseconds per startup to regenerate identical output.
#
# The cache is per shell: `kubectl completion bash` and `kubectl completion
# zsh` produce entirely different scripts, and $DOTFILES_CACHE_DIR already
# differs per shell. Writes through a temp file so a failed run cannot leave a
# truncated cache behind.
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
