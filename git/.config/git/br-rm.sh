#!/usr/bin/env bash
#
# git br-rm -- switch to the default branch and delete the branch left behind.
#
# Deletes only when the branch's work survives somewhere else: its commits are
# reachable from another ref, or the same changes landed under different commit
# ids through a squash or rebase merge. A branch whose work exists nowhere but
# here is kept, and nothing is checked out.

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

# Where a squash or rebase merge would have landed. Only the default branch:
# a pull request against anything else is rare enough to handle by hand.
merge_targets() {
    local target="$1" ref

    for ref in "refs/heads/$target" "refs/remotes/origin/$target"; do
        git show-ref --verify --quiet "$ref" && printf '%s\n' "$ref"
    done
}

# A rebase merge rewrites the commits but not the patches they carry, so every
# one of them turns up in `git cherry` as an equivalent the target already has.
is_rebase_merged() {
    local commits

    commits=$(git cherry "$2" "$1") || return 1
    [ -n "$commits" ] || return 1

    ! printf '%s\n' "$commits" | grep -q '^+'
}

# A squash merge leaves one commit carrying the whole branch as its patch, and
# no individual commit of the branch resembles it. Rolling the branch up into
# the same shape -- one commit, the branch's tree, sitting on the merge base --
# gives `git cherry` something it can match against it.
is_squash_merged() {
    local branch="$1" target="$2" base rollup

    base=$(git merge-base "$target" "$branch") || return 1
    rollup=$(git commit-tree "$branch^{tree}" -p "$base" -m _) || return 1

    git cherry "$target" "$rollup" | grep -q '^-'
}

is_safe_to_delete() {
    local branch="$1" target="$2" ref

    [ -n "$(other_refs_containing "$branch")" ] && return 0

    while IFS= read -r ref; do
        is_rebase_merged "$branch" "$ref" && return 0
        is_squash_merged "$branch" "$ref" && return 0
    done < <(merge_targets "$target")

    return 1
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

# The expensive, and usually needless, half of the answer: only worth a round
# trip to the remote once everything already here has said no.
if ! is_safe_to_delete "$current" "$target"; then
    if git remote | grep -q .; then
        echo "Nothing here contains $current; fetching..."
        git fetch --quiet
    fi

    if ! is_safe_to_delete "$current" "$target"; then
        echo "Refusing to delete $current: its commits are not merged into $target and exist nowhere else" >&2
        echo "Delete it anyway with: git branch -D $current" >&2
        exit 1
    fi
fi

git checkout "$target" || exit 1
git branch -D "$current"
