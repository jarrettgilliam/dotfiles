# Symlink target computation, shared by ./install.sh and <package>/install.sh.
# Sourced, never run. The sourcing script sets DOTFILES_ROOT to the physical
# path of this directory first.

# Physical, so that the prefix tests below are meaningful. A $HOME reached
# through a symlink (/home -> /System/Volumes/Data/home) would otherwise never
# look like a prefix of the repository path.
HOME_REAL="$(cd -P "$HOME" && pwd)"

# tildify <path>
#
# Shorten a path under $HOME for display. A function rather than
# ${path/#$HOME/~} because there is no spelling of that substitution which works
# in both bash 3.2 and bash 5: 5 tilde-expands an unquoted replacement back into
# $HOME, and 3.2 prints the backslash of an escaped one.
tildify() {
    case "$1" in
        "$HOME") printf '%s\n' "~" ;;
        "$HOME"/*) printf '%s\n' "~/${1#"$HOME"/}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

# relpath <target> <base-dir>
#
# Print <target> relative to <base-dir>. Both must be absolute and free of
# symlinked components. Done in bash rather than with `realpath --relative-to`,
# which BSD realpath does not have.
relpath() {
    local target="${1%/}" base="${2%/}" up=""

    while [ -n "$base" ] && [ "$base" != "/" ]; do
        case "$target/" in
            "$base"/*) printf '%s\n' "$up${target#"$base"/}"; return 0 ;;
        esac
        up="../$up"
        base="$(dirname "$base")"
    done

    printf '%s\n' "$up${target#/}"
}

# link_target <target> <link>
#
# The target to store in the symlink. Relative to the link's own directory when
# the repository is under $HOME, so that a $HOME which moves -- a restored
# backup, a different mount point, another machine -- takes its links with it.
#
# A repository outside $HOME gets an absolute target instead: nothing ties the
# two paths together there, so a relative "../../../opt/dotfiles/..." would only
# break in more ways than the absolute path does.
link_target() {
    local target="$1" link="$2"

    case "$DOTFILES_ROOT/" in
        "$HOME_REAL"/*) ;;
        *) printf '%s\n' "$target"; return 0 ;;
    esac

    # Lexical rather than `cd -P`: in a dry run the link's directory need not
    # exist yet.
    case "$link" in
        "$HOME"/*) link="$HOME_REAL/${link#"$HOME"/}" ;;
    esac

    relpath "$target" "$(dirname "$link")"
}
