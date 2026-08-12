Do not stage, commit, push, rebase, merge, or perform any other actions that
change anything in the ~/.git folder for the repo unless I specifically ask in
my prompt. Consider git to be read-only. Keep this in mind when performing other
git actions that may inadvertently change git or it's index. Consider using `git
show <commit>:<path> > <path>` or `git restore --worktree --source=<commit>`
when restoring files.

If you need the source code for something and you cannot find it, don't attempt
to decompile assemblies. Instead just ask and I will tell you where to look.

Default to no comment; code should be self-documenting. Two exceptions. First, a
surprise guard: a fact about this system that no external doc can state, which
I'd otherwise reasonably change and be wrong ("nvm prepends to PATH on load;
source ours first or its node shadows ours"). Read the external docs before
deciding something is surprising -- if a man page or reference owns it, skip the
comment. These should be rare; prefer restructuring so the surprise is gone.
Second, public API docs, only on symbols exposed for callers elsewhere, and only
stating what the signature can't: null/empty/error cases, mutation of arguments,
what it throws, units, who owns or disposes the return. Judge that from the
signature alone, not from the body you just wrote. Private and module-internal
symbols get none. This covers members you write or whose contract you change; if
you touch a public member that was already undocumented, leave it and mention
the gap rather than filling it unprompted. Document your own contract, never
copy the wrapped thing's -- inherit (`<inheritdoc cref>`, `{@inheritDoc}`) and
write only the delta.

Otherwise: don't restate the code, the signature, the language's semantics, the
test name, or the assertion below it. Don't repeat what a man page, design doc,
README, or `--help` already says -- point to it instead. No historical narrative
("this used to...", "the gap this change closed") -- that's git's job. No facts
that rot (timings, counts). Prefer an extracted function, a named constant, or a
better name over a comment. Machine-readable directives (`//nolint`, `#
shellcheck disable`, generated-file and license headers), TODOs, and workarounds
naming a specific upstream issue and a removal trigger are all fine. Refactoring
is never a reason a surprise guard dies -- it explains one line and follows that
line. When you trim a comment, re-read the neighbors you stranded.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
