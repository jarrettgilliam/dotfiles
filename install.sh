#!/usr/bin/env bash
# Install dotfiles packages into $HOME.
#
#   ./install.sh                 install every package
#   ./install.sh shell vim       install only the named packages
#   ./install.sh --list          list packages and exit
#   ./install.sh --dry-run       report what would happen, change nothing
#
# A package is any top-level directory not starting with a dot. Each is
# installed one of two ways:
#
#   1. If <package>/install.sh exists and is executable, it is run and is
#      entirely responsible for that package.
#   2. Otherwise the package tree mirrors $HOME: every file below it is
#      symlinked to the matching path under $HOME.
#
# Safe to re-run: an existing correct symlink is left alone, and a real file is
# backed up before it is replaced.

set -u

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Anything this installer displaces is renamed to
#
#     <original name>.<timestamp>.dotfiles-bak
#
# The distinctive final extension is the point: it makes every backup this
# repository has ever made findable, and removable, with one command. See
# "Cleaning up backups" in the README. Exported so package installers use the
# same convention.
export DOTFILES_BAK_SUFFIX="$(date +%Y%m%d%H%M%S).dotfiles-bak"

DRY_RUN=0
declare -a REQUESTED=()

# Files that are part of the repository rather than part of the config, so they
# are never symlinked into $HOME.
is_repo_file() {
    case "$(basename "$1")" in
        install.sh|README|README.*|LICENSE|LICENSE.*|.gitignore|.DS_Store) return 0 ;;
        *) return 1 ;;
    esac
}

list_packages() {
    local d
    for d in "$DOTFILES_DIR"/*/; do
        [ -d "$d" ] || continue
        basename "$d"
    done
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run|-n) DRY_RUN=1; shift ;;
        --list|-l)    list_packages; exit 0 ;;
        -h|--help)
            sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Try: $(basename "$0") --help" >&2
            exit 2 ;;
        *) REQUESTED+=("$1"); shift ;;
    esac
done

declare -a PACKAGES=()
if [ ${#REQUESTED[@]} -eq 0 ]; then
    while IFS= read -r p; do PACKAGES+=("$p"); done < <(list_packages)
else
    for p in "${REQUESTED[@]}"; do
        if [ -d "$DOTFILES_DIR/$p" ]; then
            PACKAGES+=("$p")
        else
            echo "No such package: $p" >&2
            echo "Available: $(list_packages | tr '\n' ' ')" >&2
            exit 2
        fi
    done
fi

# ---------------------------------------------------------------------------
# Counters, reported at the end so a long run has a short summary.
# ---------------------------------------------------------------------------
linked=0
already=0
backed_up=0
delegated=0
declare -a reported_dirs=()

# ensure_real_dirs <directory>
#
# Make every path component below $HOME a real directory, replacing any that is
# a symlink.
#
# This matters because the scheme this repository replaces symlinked whole
# directories: ~/.vim pointed at another repository's vim/.vim. Left alone,
# `mkdir -p ~/.vim/colors` and `ln` would both resolve *through* that symlink
# and write into the other repository instead of into $HOME. Only the symlink
# is moved aside; whatever it pointed at is untouched.
ensure_real_dirs() {
    local dir="$1" rel part path="$HOME"

    # Tells link_file whether $dest is reached through a symlink. In a dry run
    # nothing is actually replaced, so a stale file behind that symlink would
    # otherwise be reported as needing a backup when it is not even in $HOME.
    ancestor_symlink=0

    rel="${dir#$HOME/}"
    # Not under $HOME (or is $HOME itself): leave it to mkdir -p.
    [ "$rel" = "$dir" ] && return 0

    local IFS=/
    for part in $rel; do
        path="$path/$part"

        if [ -L "$path" ]; then
            ancestor_symlink=1
            if [ $DRY_RUN -eq 1 ]; then
                # Nothing is moved in a dry run, so the same symlink would be
                # re-reported for every leaf beneath it. Report it once.
                case " ${reported_dirs[*]-} " in
                    *" $path "*) ;;
                    *)
                        reported_dirs+=("$path")
                        echo "   would replace symlinked directory ${path/#$HOME/~} (-> $(readlink "$path"))"
                        ;;
                esac
            else
                mv "$path" "$path.$DOTFILES_BAK_SUFFIX"
                echo "   💾 Replaced symlinked directory ${path/#$HOME/~} -> $(basename "$path").$DOTFILES_BAK_SUFFIX"
                backed_up=$((backed_up + 1))
            fi
        fi

        if [ $DRY_RUN -eq 0 ] && [ ! -d "$path" ]; then
            mkdir "$path"
        fi
    done
}

# link_file <source> <destination>
#
# Leaf files are linked individually rather than linking whole directories, so
# that files an application writes itself -- ~/.vim/.netrwhist, swap files,
# spell dictionaries -- land in the real home directory instead of showing up
# as untracked changes in this repository.
link_file() {
    local src="$1" dest="$2"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        already=$((already + 1))
        return
    fi

    ensure_real_dirs "$(dirname "$dest")"

    if [ $DRY_RUN -eq 1 ]; then
        if [ $ancestor_symlink -eq 0 ] && [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "   would back up ${dest/#$HOME/~} -> $(basename "$dest").$DOTFILES_BAK_SUFFIX"
        fi
        echo "   would link    ${dest/#$HOME/~} -> ${src/#$DOTFILES_DIR/.}"
        linked=$((linked + 1))
        return
    fi

    mkdir -p "$(dirname "$dest")"

    # A real file is precious; a wrong symlink is not.
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.$DOTFILES_BAK_SUFFIX"
        echo "   💾 Backed up $(basename "$dest") -> $(basename "$dest").$DOTFILES_BAK_SUFFIX"
        backed_up=$((backed_up + 1))
    fi

    ln -sfn "$src" "$dest"
    echo "   ✅ ${dest/#$HOME/~}"
    linked=$((linked + 1))
}

# Check out every submodule in the repository.
#
# Done here, once, rather than per package: submodules are a property of the
# repository, so a package that gains one later needs no installer change and
# no list to keep in sync. Deliberately not scoped by pathspec -- a pathspec
# naming a package that is not committed yet fails with "did not match any
# file(s) known to git", which would break exactly when adding a package.
init_submodules() {
    local count

    command -v git >/dev/null 2>&1 || return 0
    git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1 || return 0
    [ -f "$DOTFILES_DIR/.gitmodules" ] || return 0

    count=$(git -C "$DOTFILES_DIR" config -f .gitmodules --get-regexp '^submodule\..*\.path$' | wc -l | tr -d ' ')
    [ "$count" -gt 0 ] || return 0

    echo ""
    echo "📦 submodules"

    if [ $DRY_RUN -eq 1 ]; then
        echo "   would check out $count submodule(s)"
        return 0
    fi

    if git -C "$DOTFILES_DIR" submodule update --init --recursive; then
        echo "   ✅ $count submodule(s) checked out"
    else
        # Not fatal: config that does not depend on a submodule still installs,
        # and the shell config skips plugins it cannot find.
        echo "   ⚠️  Could not check out submodules; anything depending on one will be skipped" >&2
    fi
}

# Mirror every file in a package into $HOME at the same relative path.
install_mirror() {
    local pkg_dir="$1" src rel

    while IFS= read -r src; do
        is_repo_file "$src" && continue
        rel="${src#$pkg_dir/}"
        link_file "$src" "$HOME/$rel"
    done < <(find "$pkg_dir" \( -type f -o -type l \) ! -path '*/.git/*' | sort)
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
if [ $DRY_RUN -eq 1 ]; then
    echo "🔍 Dry run -- nothing will be changed."
fi

init_submodules

for pkg in "${PACKAGES[@]}"; do
    pkg_dir="$DOTFILES_DIR/$pkg"
    echo ""

    if [ -x "$pkg_dir/install.sh" ]; then
        echo "📦 $pkg (own installer)"
        DOTFILES_DRY_RUN=$DRY_RUN "$pkg_dir/install.sh" || {
            echo "   ❌ $pkg/install.sh failed" >&2
            exit 1
        }
        delegated=$((delegated + 1))
    else
        echo "📦 $pkg"
        install_mirror "$pkg_dir"
    fi
done

echo ""
echo "-------------------------------------------------------"
summary="$linked linked, $already already installed, $backed_up backed up"
if [ $delegated -gt 0 ]; then
    # Packages with their own installer report their own results above; the
    # counters here only cover the mirrored ones.
    summary="$summary, $delegated package(s) self-installed"
fi

if [ $DRY_RUN -eq 1 ]; then
    echo "Dry run complete: $summary."
    echo "Re-run without --dry-run to apply."
else
    echo "Done: $summary."
fi
echo "-------------------------------------------------------"
