## consider git read-only

Do not stage, commit, push, rebase, merge, branch, or perform any other actions that
change anything in the ~/.git folder for the repo unless I specifically ask in
my prompt. Consider git to be read-only. Keep this in mind when performing other
git actions that may inadvertently change git or it's index. Like `git restore --worktree`

## Do not decompile code

If you need the source code for something and you cannot find it, DO NOT attempt
to decompile assemblies. Instead just ask and I will tell you where to look.

## Follow these programming principles

- KISS - Keep it Simple, Stupid
- DRY - Don't Repeat Yourself
- YAGNI - You Aren’t Gonna Need it
- Premature optimization is the root of all evil -- Donald Knuth

## Limit code comments

Code should be self-documenting; a comment is an admission that it isn't.
Don't add comments unless it matches one of the following rules, everything else goes.
These rules override the surrounding file's conventions. Existing comments that violate
them are debt, not precedent — don't imitate them:

1. **Machine-readable directives.** `//nolint`, `# type: ignore`, `# noqa`,
   `# shellcheck disable=SCxxxx`, `#pragma warning disable`, `// eslint-disable`,
   `// Code generated ... DO NOT EDIT.`, license and copyright headers. These are
   program input, not explanation.
2. **`TODO` / `FIXME` / `HACK` / `TEMP` — only while still true.** Verify each
   one. If the TODO is done, the FIXME is fixed, the hack is gone, or the temp
   code is now permanent, delete the marker.
3. **Public API documentation** Documentation on symbols exposed for callers
   elsewhere stay (nuget, npm, etc). Callers who can't read the code need
   documentation. This only covers doc comments attached to a symbol (JSDoc, 
   C# doc comment with `///`, bash function usage, etc). Comments in the middle
   of a function explaining non-obvious "why" do not survive. Documentation on
   symbols not exposed elsewhere stay *only* if the documentation adds something
   the signature doesn't already state: details about how the function works,
   thrown exceptions, specifics on return values, etc. Documentation that only
   restates the signature should be deleted. This means dynamically typed languages
   need more documentation than statically typed ones.
5. **Existing links.** A URL, an issue number, the source a snippet was adapted from,
   the page a magic constant came from. A link is not a copy: it does not drift,
   and it is often the only route back to why a value is what it is.
6. **Section separators.** A banner or a one-line label marking where one part
   of a file ends and the next begins, in a file long enough to navigate rather
   than read. It orients; it does not explain.
7. **Commented-out code** If it's there, it's there for a reason. An alternative
   theme, a disabled option, a config line kept beside its live sibling, and code
   the developer might need to add back later.

## graphify - **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to
knowledge graph. Trigger: `/graphify` When the user types `/graphify`, use the
installed graphify skill or instructions before doing anything else.
