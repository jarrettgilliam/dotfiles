#!/bin/bash
# Install the coding agent configuration. See README.md.
# Safe to re-run. Called by the top-level install.sh, or directly.

set -u

PKG_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$PKG_DIR/../install-lib.sh"

SHARED="$PKG_DIR/shared"

# install_shared <instructions path> <skills directory>
#
# Both relative to $HOME. This is the one thing the package cannot express by
# mirroring $HOME: the instructions and the skills have a single source, and
# every tool reads them from a path of its own.
install_shared() {
    local instructions="$1" skills="$2" src

    link_home "$SHARED/AGENTS.md" "$instructions"

    # Every file below shared/skills, not the SKILL.md alone: a skill may carry
    # scripts or reference files, and adding one needs no change here. Linked
    # leaf by leaf like everything else, so whatever a tool writes into its own
    # skills directory stays out of this repository.
    while IFS= read -r src; do
        link_home "$src" "$skills/${src#"$SHARED/skills/"}"
    done < <(find "$SHARED/skills" -type f ! -name .DS_Store | sort)
}

# Claude's own files -- settings, status line, output styles -- are laid out as
# they appear under $HOME, so they install the way any other package would.
mirror_tree "$PKG_DIR/claude"

install_shared ".claude/CLAUDE.md"                ".claude/skills"
install_shared ".copilot/copilot-instructions.md" ".copilot/skills"
install_shared ".codex/AGENTS.md"                 ".codex/skills"

exit "$DOTFILES_FAILED"
