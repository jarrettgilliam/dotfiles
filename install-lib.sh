# Installer library, sourced by ./install.sh and by any <package>/install.sh.
# Sourced, never run.
#
# Every verb honors DOTFILES_DRY_RUN, backs up whatever it displaces, and
# reports one line per path, so a package installer contains only its own
# decisions. See README.md, "Writing a package installer".

DOTFILES_ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Physical, so that the prefix tests in _dotfiles_link_target are meaningful. A
# $HOME reached through a symlink (/home -> /System/Volumes/Data/home) would
# otherwise never look like a prefix of the repository path.
DOTFILES_HOME_REAL="$(cd -P "$HOME" && pwd)"

DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-0}"

# Anything an installer displaces is renamed to
#
#     <original name>.<timestamp>.dotfiles-bak
#
# The extensions are all the same so they're findable and removable with one
# command. The top-level installer exports this so a whole run shares one
# timestamp; the default is for a package installer run on its own.
DOTFILES_BAK_SUFFIX="${DOTFILES_BAK_SUFFIX:-$(date +%Y%m%d%H%M%S).dotfiles-bak}"

# Set when any operation fails, so the top-level installer can exit non-zero.
DOTFILES_FAILED=0

# Set when anything was changed, or in a dry run would have been. Lets an
# installer keep its closing advice for runs that actually did something.
DOTFILES_CHANGED=0

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

# _dotfiles_report <glyph> <path> [note]
#
# One line per path: "   <glyph> ~/.bashrc (note)".
_dotfiles_report() {
    if [ -n "${3:-}" ]; then
        printf '   %s %s (%s)\n' "$1" "$(tildify "$2")" "$3"
    else
        printf '   %s %s\n' "$1" "$(tildify "$2")"
    fi
}

_dotfiles_fail() {
    printf '   ❌ %s (%s)\n' "$(tildify "$1")" "$2" >&2
    DOTFILES_FAILED=1
}

# Print <target> relative to <base-dir>. Both must be absolute and free of
# symlinked components. Done in bash rather than with `realpath --relative-to`,
# which BSD realpath does not have.
_dotfiles_relpath() {
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

# The target to store in the symlink. Relative to the link's own directory when
# the repository is under $HOME, so that a $HOME which moves -- a restored
# backup, a different mount point, another machine -- takes its links with it.
#
# A repository outside $HOME gets an absolute target instead: nothing ties the
# two paths together there, so a relative "../../../opt/dotfiles/..." would only
# break in more ways than the absolute path does.
_dotfiles_link_target() {
    local target="$1" link="$2"

    case "$DOTFILES_ROOT/" in
        "$DOTFILES_HOME_REAL"/*) ;;
        *) printf '%s\n' "$target"; return 0 ;;
    esac

    # Lexical rather than `cd -P`: in a dry run the link's directory need not
    # exist yet.
    case "$link" in
        "$HOME"/*) link="$DOTFILES_HOME_REAL/${link#"$HOME"/}" ;;
    esac

    _dotfiles_relpath "$target" "$(dirname "$link")"
}

# Permission bits of <path> as octal digits, empty if it cannot be read.
_dotfiles_file_mode() {
    local mode
    for mode in "$(stat -c '%a' "$1" 2>/dev/null)" "$(stat -f '%Lp' "$1" 2>/dev/null)"; do
        case "$mode" in
            "" | *[!0-7]*) ;;
            *) printf '%s\n' "$mode"; return 0 ;;
        esac
    done
}

# True when <actual> grants anything <wanted> does not.
_dotfiles_mode_looser() {
    [ $(( 8#$1 & ~8#$2 )) -ne 0 ]
}

# is_repo_file <path>
#
# True for a file that belongs to the repository rather than to $HOME: this
# repository's own metadata, and OS noise.
is_repo_file() {
    case "$(basename "$1")" in
        install.sh|README|README.*|LICENSE|LICENSE.*|.gitignore) return 0 ;;
        .DS_Store|._.DS_Store|.localized) return 0 ;;
        *) return 1 ;;
    esac
}

# Move <path> aside without reporting it. Sets DOTFILES_LAST_BACKUP, empty when
# there was nothing to move.
_dotfiles_backup() {
    local path="$1" bak="$1.$DOTFILES_BAK_SUFFIX"

    DOTFILES_LAST_BACKUP=""
    [ -e "$path" ] || [ -L "$path" ] || return 0

    DOTFILES_CHANGED=1

    if [ "$DOTFILES_DRY_RUN" = 1 ]; then
        DOTFILES_LAST_BACKUP="$bak"
        return 0
    fi

    if ! mv "$path" "$bak"; then
        _dotfiles_fail "$path" "could not back up"
        return 1
    fi

    DOTFILES_LAST_BACKUP="$bak"
}

# Make every path component below $HOME a real directory, replacing any that is
# a symlink, and set _dotfiles_ancestor_symlink for link_file's dry run.
#
# This matters because the scheme this repository replaces symlinked whole
# directories: ~/.vim pointed at another repository's vim/.vim. Left alone,
# `mkdir -p ~/.vim/colors` and `ln` would both resolve *through* that symlink
# and write into the other repository instead of into $HOME. Only the symlink
# is moved aside; whatever it pointed at is untouched.
_dotfiles_ensure_real_dirs() {
    local dir="$1" rel part path="$HOME"

    _dotfiles_ancestor_symlink=0

    rel="${dir#$HOME/}"
    # Not under $HOME (or is $HOME itself): leave it to mkdir -p.
    [ "$rel" = "$dir" ] && return 0

    local IFS=/
    for part in $rel; do
        path="$path/$part"

        if [ -L "$path" ]; then
            _dotfiles_ancestor_symlink=1
            if [ "$DOTFILES_DRY_RUN" = 1 ]; then
                # Nothing is moved in a dry run, so the same symlink would be
                # re-reported for every leaf beneath it. Report it once.
                case " ${_dotfiles_reported_dirs[*]-} " in
                    *" $path "*) ;;
                    *)
                        _dotfiles_reported_dirs+=("$path")
                        echo "   would replace symlinked directory $(tildify "$path") (-> $(readlink "$path"))"
                        ;;
                esac
            else
                _dotfiles_backup "$path" || return 1
                _dotfiles_report "💾" "$path" "symlinked directory replaced"
            fi
        fi

        if [ "$DOTFILES_DRY_RUN" = 0 ] && [ ! -d "$path" ]; then
            mkdir "$path" || { _dotfiles_fail "$path" "could not create directory"; return 1; }
            DOTFILES_CHANGED=1
        fi
    done
}
declare -a _dotfiles_reported_dirs=()

# backup_file <path>
#
# Rename <path> to <path>.$DOTFILES_BAK_SUFFIX and report it. Sets
# DOTFILES_LAST_BACKUP to the new path, empty when <path> did not exist.
# Non-zero only if the rename failed.
backup_file() {
    _dotfiles_backup "$1" || return 1
    [ -n "$DOTFILES_LAST_BACKUP" ] || return 0

    if [ "$DOTFILES_DRY_RUN" = 1 ]; then
        echo "   would back up $(tildify "$1")"
    else
        _dotfiles_report "💾" "$1" "backed up"
    fi
}

# link_file [--no-copy] <source> <destination>
#
# Idempotent symlink, backing up a real file in the way. Where the filesystem
# cannot create symlinks, installs a copy instead and says so; --no-copy
# suppresses that and returns 1, leaving <destination> untouched. Returns 2 if
# anything else failed.
#
# Leaf files are linked individually rather than linking whole directories, so
# that files an application writes itself -- ~/.vim/.netrwhist, swap files,
# spell dictionaries -- land in the real home directory instead of showing up
# as untracked changes in this repository.
link_file() {
    local no_copy=0
    if [ "${1:-}" = "--no-copy" ]; then no_copy=1; shift; fi

    local src="$1" dest="$2" target tmp notes=""

    target="$(_dotfiles_link_target "$src" "$dest")"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$target" ]; then
        _dotfiles_report "ℹ️ " "$dest" "already linked"
        return 0
    fi

    _dotfiles_ensure_real_dirs "$(dirname "$dest")" || return 2

    if [ "$DOTFILES_DRY_RUN" = 1 ]; then
        # A stale file behind a symlinked ancestor is not in $HOME at all, and
        # nothing was moved aside to prove it, so it is not a backup candidate.
        if [ "$_dotfiles_ancestor_symlink" = 0 ] && [ -e "$dest" ] && [ ! -L "$dest" ]; then
            notes=" (backing up existing file)"
        fi
        printf '   would link    %s -> %s%s\n' "$(tildify "$dest")" "$target" "$notes"
        DOTFILES_CHANGED=1
        return 0
    fi

    mkdir -p "$(dirname "$dest")" || { _dotfiles_fail "$dest" "could not create parent directory"; return 2; }

    # Build the link beside its destination first: until this succeeds there is
    # no way to know whether this filesystem supports symlinks at all, and
    # nothing that is in the way should be touched before then.
    tmp="$dest.dotfiles-tmp.$$"
    rm -f "$tmp"

    if ! ln -s "$target" "$tmp" 2>/dev/null; then
        rm -f "$tmp"
        [ "$no_copy" = 1 ] && return 1
        _dotfiles_copy_file "$src" "$dest"
        return $?
    fi

    # A real file is precious; a wrong symlink is not.
    if [ -L "$dest" ]; then
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        _dotfiles_backup "$dest" || { rm -f "$tmp"; return 2; }
        notes="backed up"
    fi

    if ! mv "$tmp" "$dest"; then
        rm -f "$tmp"
        _dotfiles_fail "$dest" "could not link"
        return 2
    fi

    DOTFILES_CHANGED=1
    _dotfiles_report "✅" "$dest" "$notes"
}

# The fallback for a filesystem without symlinks: Windows without Developer
# Mode, FAT32/exFAT, some SMB mounts. An identical copy is left alone so that
# re-running does not manufacture a backup every time; a diverged one is backed
# up first, which is the only record you would get of an edit made in $HOME.
_dotfiles_copy_file() {
    local src="$1" dest="$2" notes=""

    if [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$src" "$dest"; then
        _dotfiles_report "ℹ️ " "$dest" "copy, unchanged"
        return 0
    fi

    if [ -L "$dest" ]; then
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        _dotfiles_backup "$dest" || return 2
        notes="backed up; "
    fi

    if ! cp "$src" "$dest"; then
        _dotfiles_fail "$dest" "could not link or copy"
        return 2
    fi

    DOTFILES_CHANGED=1
    _dotfiles_report "⚠️ " "$dest" "${notes}copied, not linked"
}

# link_home [--no-copy] <source> [name]
#
# link_file into $HOME. <name> defaults to the source's basename and may
# contain slashes (".config/foo/config").
link_home() {
    local no_copy=""
    if [ "${1:-}" = "--no-copy" ]; then no_copy="--no-copy"; shift; fi

    link_file $no_copy "$1" "$HOME/${2:-$(basename "$1")}"
}

# mirror_tree <package-dir>
#
# link_file every file in the package to the matching path under $HOME.
mirror_tree() {
    local pkg_dir="${1%/}" src rel

    while IFS= read -r src; do
        is_repo_file "$src" && continue
        rel="${src#$pkg_dir/}"
        link_file "$src" "$HOME/$rel"
    done < <(find "$pkg_dir" \( -type f -o -type l \) ! -path '*/.git/*' | sort)
}

# write_file [--no-clobber] [--not-linked] <path> [mode]
#
# Write <path> from stdin, backing up an existing file. With --no-clobber an
# existing file is kept; only a mode more permissive than <mode> is corrected,
# never a stricter one. --not-linked reports the file as what it is at the one
# call site that has it: a stand-in for a symlink this filesystem refused.
write_file() {
    local clobber=1 not_linked=0

    while [ $# -gt 0 ]; do
        case "$1" in
            --no-clobber) clobber=0; shift ;;
            --not-linked) not_linked=1; shift ;;
            *) break ;;
        esac
    done

    local path="$1" mode="${2:-}" notes="" current

    if [ -e "$path" ] && [ "$clobber" = 0 ]; then
        notes="already exists"

        if [ -n "$mode" ]; then
            current="$(_dotfiles_file_mode "$path")"
            if [ -n "$current" ] && _dotfiles_mode_looser "$current" "$mode"; then
                DOTFILES_CHANGED=1

                if [ "$DOTFILES_DRY_RUN" = 1 ]; then
                    printf '   would tighten %s (mode %s -> %s)\n' "$(tildify "$path")" "$current" "$mode"
                    return 0
                fi
                if ! chmod "$mode" "$path"; then
                    _dotfiles_fail "$path" "could not tighten mode"
                    return 1
                fi
                _dotfiles_report "⚠️ " "$path" "$notes; mode $current tightened to $mode"
                return 0
            fi
        fi

        _dotfiles_report "ℹ️ " "$path" "$notes"
        return 0
    fi

    if [ "$DOTFILES_DRY_RUN" = 1 ]; then
        [ -e "$path" ] && notes=" (backing up existing file)"
        printf '   would write   %s%s\n' "$(tildify "$path")" "$notes"
        DOTFILES_CHANGED=1
        return 0
    fi

    # Written beside the destination first, so that content identical to what is
    # already there costs nothing: no backup, no rewrite, and a re-run on a
    # filesystem without symlinks does not manufacture a backup every time.
    local tmp="$path.dotfiles-tmp.$$"
    rm -f "$tmp"

    if ! cat > "$tmp"; then
        rm -f "$tmp"
        _dotfiles_fail "$path" "could not write"
        return 1
    fi

    if [ -f "$path" ] && [ ! -L "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        if [ "$not_linked" = 1 ]; then
            _dotfiles_report "ℹ️ " "$path" "unchanged, not linked"
        else
            _dotfiles_report "ℹ️ " "$path" "unchanged"
        fi
        return 0
    fi

    if [ -e "$path" ] || [ -L "$path" ]; then
        _dotfiles_backup "$path" || { rm -f "$tmp"; return 1; }
        notes="backed up; "
    fi

    if [ -n "$mode" ]; then
        chmod "$mode" "$tmp" || { rm -f "$tmp"; _dotfiles_fail "$path" "could not set mode"; return 1; }
    fi

    if ! mv "$tmp" "$path"; then
        rm -f "$tmp"
        _dotfiles_fail "$path" "could not write"
        return 1
    fi

    DOTFILES_CHANGED=1

    if [ "$not_linked" = 1 ]; then
        _dotfiles_report "⚠️ " "$path" "${notes}written, not linked"
    elif [ -n "$mode" ]; then
        _dotfiles_report "✅" "$path" "${notes}created, mode $mode"
    else
        _dotfiles_report "✅" "$path" "${notes}created"
    fi
}

# ensure_dir <directory>...
ensure_dir() {
    local dir

    for dir in "$@"; do
        if [ -d "$dir" ]; then
            _dotfiles_report "ℹ️ " "$dir" "already exists"
            continue
        fi

        DOTFILES_CHANGED=1

        if [ "$DOTFILES_DRY_RUN" = 1 ]; then
            printf '   would create  %s\n' "$(tildify "$dir")"
            continue
        fi

        if mkdir -p "$dir"; then
            _dotfiles_report "✅" "$dir" "created"
        else
            _dotfiles_fail "$dir" "could not create directory"
        fi
    done
}
