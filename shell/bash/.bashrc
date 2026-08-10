# Interactive bash configuration.
#
# Everything lives in conf.d/, loaded in filename order, mirroring the zsh
# side: the same number means the same topic, and most files source a
# counterpart in ../shared/ that zsh uses too, then add the bash-only part.
#
#   00  options       history and shopt. Nothing depends on it.
#   05  environment   secrets, PATH, brew, nvm, os/ + hosts/
#   10  completion    bash-completion, if installed
#   20  prompt
#   30  keybinds      readline bindings
#   50  aliases
#   90  tools         external inits last, so they can override anything above
#
# See README.md before adding a file.

# Non-interactive shells get nothing: scripts inherit the finished environment
# from their parent, and readline settings would be meaningless. This mirrors
# zsh, where conf.d is only read from .zshrc.
case $- in
    *i*) ;;
    *)   return ;;
esac

# ---------------------------------------------------------------------------
# Locate the repository.
#
# zsh gets this from ZDOTDIR; bash has no equivalent, so this file finds
# itself. $BASH_SOURCE is ~/.bashrc, which is a symlink into the repository,
# so the link is resolved a step at a time. `readlink -f` would do it in one
# go but does not exist on BSD, and this file has to work on macOS.
# ---------------------------------------------------------------------------
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

# Per-shell, because cached tool output is not interchangeable: `kubectl
# completion bash` and `zsh` generate entirely different scripts.
DOTFILES_CACHE_DIR="$XDG_CACHE_HOME/bash"
[ -d "$DOTFILES_CACHE_DIR" ] || mkdir -p "$DOTFILES_CACHE_DIR"

# Helpers the shared files rely on: has_command, path_append, cached_eval.
. "$DOTFILES_SHELL/shared/lib.sh"

for _rc in "$DOTFILES_SHELL"/bash/conf.d/*.bash; do
    [ -r "$_rc" ] && . "$_rc"
done
unset _rc
