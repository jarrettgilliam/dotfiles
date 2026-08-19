#!/bin/bash

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
mirror_tree "$PKG_DIR/copilot"

install_shared ".claude/CLAUDE.md"                ".claude/skills"
install_shared ".copilot/copilot-instructions.md" ".copilot/skills"
install_shared ".codex/AGENTS.md"                 ".codex/skills"

for x in \
    "engineering/improve-codebase-architecture" \
    "engineering/codebase-design" \
    "engineering/domain-modeling" \
    "productivity/grill-me" \
    "productivity/grilling"
do
    link_home "$PKG_DIR/shared/mattpocock_skills/skills/$x/" ".claude/skills/$(basename "$x")"
    link_home "$PKG_DIR/shared/mattpocock_skills/skills/$x/" ".copilot/skills/$(basename "$x")"
    link_home "$PKG_DIR/shared/mattpocock_skills/skills/$x/" ".codex/skills/$(basename "$x")"
done

exit "$DOTFILES_FAILED"
