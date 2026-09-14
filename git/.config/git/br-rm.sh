#!/usr/bin/env bash
#
# git br-rm -- switch to the default branch and delete the branch left behind.
#
# Deletes only when the branch's commits are reachable from some other ref:
# merged into another branch, pushed to a remote, or tagged. A branch that is
# the only thing pointing at its commits is kept, and nothing is checked out.

set -u

default_branch() {
    local branch

    branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | cut -d/ -f2)

    if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
        if git show-ref --verify --quiet refs/heads/main; then
            branch=main
        else
            branch=master
        fi
    fi

    printf '%s\n' "$branch"
}

# The branch's own ref always contains its tip and says nothing about whether
# the commits survive the delete, so it is the one ref that does not count.
other_refs_containing() {
    local ref

    git for-each-ref --contains "$1" --format='%(refname)' \
        refs/heads refs/remotes refs/tags |
        while IFS= read -r ref; do
            [ "$ref" = "refs/heads/$1" ] || printf '%s\n' "$ref"
        done
}

current=$(git branch --show-current)
if [ -z "$current" ]; then
    echo "Not on a branch" >&2
    exit 1
fi

target=$(default_branch)
if [ "$current" = "$target" ]; then
    echo "Already on $target" >&2
    exit 1
fi

if [ -z "$(other_refs_containing "$current")" ]; then
    echo "Refusing to delete $current: no other branch, remote or tag contains its commits" >&2
    exit 1
fi

git checkout "$target" || exit 1
git branch -D "$current"
