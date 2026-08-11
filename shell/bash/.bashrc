# Interactive bash configuration.

# Non-interactive shells get nothing: they inherit the finished environment from their parent
case $- in
    *i*) ;;
    *)   return ;;
esac

# Locate the repository. $BASH_SOURCE is the symlink ~/.bashrc
_src="${BASH_SOURCE[0]}"
while [ -L "$_src" ]; do
    _dir="$(cd -P "$(dirname "$_src")" && pwd)"
    _src="$(readlink "$_src")"
    case $_src in
        /*) ;;
        *)  _src="$_dir/$_src" ;;
    esac
done
DOTFILES_SHELL="$(cd -P "$(dirname "$_src")/.." && pwd)"
unset _src _dir

: "${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_CACHE_HOME

# Per-shell. See cached_eval in shared/lib.sh.
DOTFILES_CACHE_DIR="$XDG_CACHE_HOME/bash"
[ -d "$DOTFILES_CACHE_DIR" ] || mkdir -p "$DOTFILES_CACHE_DIR"

# Helpers the shared files rely on: has_command, path_append, cached_eval.
. "$DOTFILES_SHELL/shared/lib.sh"

for _rc in "$DOTFILES_SHELL"/bash/conf.d/*.bash; do
    [ -r "$_rc" ] && . "$_rc"
done
unset _rc
