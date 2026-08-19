#!/bin/bash
# Install the coding agent configuration. See README.md.
# Safe to re-run. Called by the top-level install.sh, or directly.

set -u

PKG_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$PKG_DIR/../install-lib.sh"

SHARED="$PKG_DIR/shared"

# install_shared <instructions path> <skills directory>
install_shared() {
    local instructions="$1" skills="$2" src

    link_home "$SHARED/AGENTS.md" "$instructions"

    while IFS= read -r src; do
        is_repo_file "$src" && continue
        link_home "$src" "$skills/${src#"$SHARED/skills/"}"
    done < <(find "$SHARED/skills" -type f | sort)
}

mirror_tree "$PKG_DIR/claude"

install_shared ".claude/CLAUDE.md"                ".claude/skills"
install_shared ".copilot/copilot-instructions.md" ".copilot/skills"
install_shared ".codex/AGENTS.md"                 ".codex/skills"

exit "$DOTFILES_FAILED"
