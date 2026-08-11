#!/usr/bin/env bash

set -u

DOTFILES_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES_ROOT="$DOTFILES_DIR"
. "$DOTFILES_DIR/install-lib.sh"

# Anything this installer displaces is renamed to
#
#     <original name>.<timestamp>.dotfiles-bak
#
# The extensions are all the same so they're findable and removable with one
# command. Exported for package installers to use.
export DOTFILES_BAK_SUFFIX="$(date +%Y%m%d%H%M%S).dotfiles-bak"

DRY_RUN=0
declare -a REQUESTED=()

usage() {
    echo "Install dotfiles packages into \$HOME."
    echo ""
    echo "  ./install.sh                 install every package"
    echo "  ./install.sh shell vim       install only the named packages"
    echo "  ./install.sh --list          list packages and exit"
    echo "  ./install.sh --dry-run       report what would happen, change nothing"
    echo ""
    echo "A package is any top-level directory not starting with a dot. Each is"
    echo "installed one of two ways:"
    echo ""
    echo "  1. If <package>/install.sh exists and is executable, it is run and is"
    echo "     entirely responsible for that package."
    echo "  2. Otherwise the package tree mirrors \$HOME: every file below it is"
    echo "     symlinked to the matching path under \$HOME."
    echo ""
    echo "Safe to re-run: an existing correct symlink is left alone, and a real"
    echo "file is backed up before it is replaced."
}

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

# Argument parsing
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run|-n) DRY_RUN=1; shift ;;
        --list|-l)    list_packages; exit 0 ;;
        -h|--help)    usage; exit 0 ;;
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

# Counters, reported at the end so a long run has a short summary.
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
                        echo "   would replace symlinked directory $(tildify "$path") (-> $(readlink "$path"))"
                        ;;
                esac
            else
                mv "$path" "$path.$DOTFILES_BAK_SUFFIX"
                echo "   💾 Replaced symlinked directory $(tildify "$path") -> $(basename "$path").$DOTFILES_BAK_SUFFIX"
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
    local src="$1" dest="$2" target

    target="$(link_target "$src" "$dest")"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$target" ]; then
        already=$((already + 1))
        return
    fi

    ensure_real_dirs "$(dirname "$dest")"

    if [ $DRY_RUN -eq 1 ]; then
        if [ $ancestor_symlink -eq 0 ] && [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "   would back up $(tildify "$dest") -> $(basename "$dest").$DOTFILES_BAK_SUFFIX"
        fi
        echo "   would link    $(tildify "$dest") -> $target"
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

    ln -sfn "$target" "$dest"
    echo "   ✅ $(tildify "$dest")"
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

# Install
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

# Did anything get displaced this run?
#
# The $backed_up counter is not enough: packages with their own install.sh run
# as subprocesses, so their backups never reach it. That is not a corner case
# -- every Linux distribution ships a ~/.bashrc, so the first install on one
# displaces a real file entirely inside shell/install.sh.
#
# Matching this run's exact suffix instead catches both, and cannot be fooled
# by backups left over from an earlier run. -print -quit stops at the first
# hit, so this costs a few milliseconds.
if [ -n "$(find ~/.[^.]* -maxdepth 3 -name "*.$DOTFILES_BAK_SUFFIX" -print -quit 2>/dev/null)" ]; then
    # Searching only $HOME's dot entries is fast and identical on every
    # platform: it never descends into ~/Library, which on macOS is slow and
    # noisy with permission errors. The backups are not all dotfiles themselves
    # -- ~/.config/git/ignore.<stamp>.dotfiles-bak is not -- but the top-level
    # entry always starts with a dot, which holds as long as packages install
    # to dot paths.
    #
    # [^.] rather than the more usual [!.]: interactive zsh applies history
    # expansion to the `!` before globbing ever happens, so a pasted [!.] dies
    # with "event not found". Both shells accept [^.], and it matches exactly
    # the same entries. 2>/dev/null covers directories the OS refuses to
    # traverse, such as ~/.Trash on macOS.
    echo "Displaced files were kept as *.dotfiles-bak. Delete them when ready."
    echo "   find ~/.[^.]* -maxdepth 3 -name '*.dotfiles-bak' -print  2>/dev/null   # review"
    echo "   find ~/.[^.]* -maxdepth 3 -name '*.dotfiles-bak' -delete 2>/dev/null   # delete"
fi
echo "-------------------------------------------------------"
