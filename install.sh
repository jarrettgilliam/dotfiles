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
STAMP="$(date +%Y%m%d%H%M%S)"

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

    if [ $DRY_RUN -eq 1 ]; then
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "   would back up ${dest/#$HOME/~} -> $(basename "$dest").bak.$STAMP"
        fi
        echo "   would link    ${dest/#$HOME/~} -> ${src/#$DOTFILES_DIR/.}"
        linked=$((linked + 1))
        return
    fi

    mkdir -p "$(dirname "$dest")"

    # A real file is precious; a wrong symlink is not.
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.bak.$STAMP"
        echo "   💾 Backed up $(basename "$dest") -> $(basename "$dest").bak.$STAMP"
        backed_up=$((backed_up + 1))
    fi

    ln -sfn "$src" "$dest"
    echo "   ✅ ${dest/#$HOME/~}"
    linked=$((linked + 1))
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
