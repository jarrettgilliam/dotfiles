#!/usr/bin/env bash

set -u

DOTFILES_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DOTFILES_DIR/install-lib.sh"

export DOTFILES_BAK_SUFFIX

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

DOTFILES_DRY_RUN=$DRY_RUN
export DOTFILES_DRY_RUN

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

# Deliberately not scoped by pathspec: a pathspec naming a package that is not
# committed yet fails with "did not match any file(s) known to git", which would
# break exactly when adding a package.
init_submodules() {
    local count pending

    command -v git >/dev/null 2>&1 || return 0
    git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1 || return 0
    [ -f "$DOTFILES_DIR/.gitmodules" ] || return 0

    count=$(git -C "$DOTFILES_DIR" config -f .gitmodules --get-regexp '^submodule\..*\.path$' | wc -l | tr -d ' ')
    [ "$count" -gt 0 ] || return 0

    echo ""
    echo "🚀 Checking out submodules..."

    # Anything not checked out at the recorded commit is marked -, + or U.
    pending=$(git -C "$DOTFILES_DIR" submodule status --recursive 2>/dev/null | grep -c '^[-+U]')

    if [ "$pending" -eq 0 ]; then
        echo "   ℹ️  $count submodule(s) already checked out"
        return 0
    fi

    if [ $DRY_RUN -eq 1 ]; then
        echo "   would check out $pending of $count submodule(s)"
        return 0
    fi

    if git -C "$DOTFILES_DIR" submodule update --init --recursive; then
        echo "   ✅ $pending submodule(s) checked out"
    else
        # Not fatal: config that does not depend on a submodule still installs,
        # and the shell config skips plugins it cannot find.
        echo "   ⚠️  Could not check out submodules; anything depending on one will be skipped" >&2
    fi
}

# Matching this run's exact suffix catches backups made inside a package
# installer's own process, which no variable here could see, and cannot be
# fooled by backups left over from an earlier run.
#
# Searching only $HOME's dot entries never descends into ~/Library, which on
# macOS is slow and noisy with permission errors. The backups are not all
# dotfiles themselves -- ~/.config/git/ignore.<stamp>.dotfiles-bak is not -- but
# the top-level entry always starts with a dot, which holds as long as packages
# install to dot paths.
#
# [^.] rather than the more usual [!.]: interactive zsh applies history
# expansion to the `!` before globbing ever happens, so a pasted [!.] dies with
# "event not found". Both shells accept [^.], and it matches exactly the same
# entries.
report_displaced() {
    if [ $DRY_RUN -eq 1 ]; then
        # A package installer's would-be backups happen in another process and
        # leave nothing behind to find, so claim nothing either way.
        echo "✨ Dry run complete! Displaced files would be saved as *.$DOTFILES_BAK_SUFFIX"
        echo "Re-run without --dry-run to apply."
        return 0
    fi

    if [ -n "$(find ~/.[^.]* -maxdepth 3 -name "*.$DOTFILES_BAK_SUFFIX" -print -quit 2>/dev/null)" ]; then
        echo "✨ Installation complete! Displaced files were saved as *.$DOTFILES_BAK_SUFFIX"
        echo "   find ~/.[^.]* -maxdepth 3 -name '*.dotfiles-bak' -print  # review"
        echo "   find ~/.[^.]* -maxdepth 3 -name '*.dotfiles-bak' -delete # delete"
    else
        echo "✨ Installation complete! No files were displaced."
    fi
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
        echo "🚀 Installing $pkg (own installer)..."
        "$pkg_dir/install.sh" || {
            echo "   ❌ $pkg/install.sh failed" >&2
            exit 1
        }
    else
        echo "🚀 Installing $pkg..."
        mirror_tree "$pkg_dir"
    fi
done

echo ""
echo "-------------------------------------------------------"
report_displaced
echo "-------------------------------------------------------"

[ "$DOTFILES_FAILED" = 0 ]
