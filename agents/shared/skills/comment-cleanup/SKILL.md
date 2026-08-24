---
name: comment-cleanup
description: Delete useless comments
---

# Comment cleanup

Delete. That is the job. Code should be self-documenting; a comment is an
admission that it isn't. Every comment starts condemned and must earn its place
by matching one of the survivors below. "It seems helpful" is not a match.
Adding or correcting comments is out of scope.

**This skill only removes. It never adds or updates.** If a comment is clearly
missing, say so in the report rather than writing it. Fixing an existing comment
that is wrong *is* in scope.

## Survivors

Everything else goes.

1. **Machine-readable directives.** `//nolint`, `# type: ignore`, `# noqa`,
   `# shellcheck disable=SCxxxx`, `#pragma warning disable`, `// eslint-disable`,
   `// Code generated ... DO NOT EDIT.`, license and copyright headers. These are
   program input, not explanation.
2. **`TODO` / `FIXME` / `HACK` / `TEMP` — only while still true.** Verify each
   one. If the TODO is done, the FIXME is fixed, the hack is gone, or the temp
   code is now permanent, delete the marker.
3. **Public API documentation** Documentation on symbols exposed for callers
   elsewhere stay (nuget, npm, etc). Callers who can't read the code need
   documentation. Documentation on symbols not exposed elsewhere stay *only*
   if the documentation adds something the signature doesn't already state:
   details about how the function works, thrown exceptions, specifics on return
   values, etc. Documentation that only restates the signature should be deleted.
   This means dynamically typed languages need more documentation than statically
   typed ones.
5. **Existing links.** A URL, an issue number, the source a snippet was adapted from,
   the page a magic constant came from. A link is not a copy: it does not drift,
   and it is often the only route back to why a value is what it is.
6. **Section separators.** A banner or a one-line label marking where one part
   of a file ends and the next begins, in a file long enough to navigate rather
   than read. It orients; it does not explain.
7. **Commented-out code** If it's there, it's there for a reason. An alternative
   theme, a disabled option, a config line kept beside its live sibling, and code
   the developer might need to add back later.

## Delete

- **Wrong comments.** These outrank everything; a drifted comment is worse than
  none.
- **Trivia.** Restating the code, the signature, or the language's semantics.
- **Anything an external doc owns.** A man page, library reference, design doc,
  README, or the program's own `--help`. Don't copy it, and don't add a pointer
  to it — assume the reader has read it. An existing link stays; see Survivors.
- **Duplication.** Same rationale at the definition, the call site, and the test.
  Keep the definition's copy; elsewhere `// See <function>.`
- **Historical narrative.** "This used to…", "the old suite did…". Git holds it.
- **Anything you'd keep only because it feels surprising.** Restructure the code
  instead: extract a function, name the constant, rename the cryptic variable.
  Report the ones you couldn't restructure; don't quietly keep them.

## Verify before you cut

Do not take a comment's word for anything. Confirm the code still does what the
comment claims. For a claim about a dependency, read the dependency's source —
not its docs, not memory. For a claim about an external tool, run the tool. When
a claim is wrong but its conclusion survives, correct the fact rather than
deleting both.

## Working rules

- Read whole files first; duplication is only visible across a file.
- Trimming strands pronouns and dangling "so"s in neighboring sentences. Re-read
  what you edited. Fix spelling, agreement, and fragments left by your own cuts.
  American spelling unless the project clearly settled otherwise.
- Check whether a test asserts on help text or subtest prose before editing it.
- Run the formatter, the linter, and the test suite when done.
- Report removals grouped by category, and surface judgment calls explicitly.
