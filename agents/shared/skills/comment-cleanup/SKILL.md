---
name: comment-cleanup
description: Comb through code comments and delete the ones that shouldn't exist - trivia, restated signatures, copied upstream docs, historical narrative, rotting facts, stale markers, and wrong claims - then fix what survives. Use when asked to clean up, tidy, prune, or audit comments, or when comments have "gotten out of hand."
---

# Comment cleanup

Delete. That is the job. Code should be self-documenting; a comment is an
admission that it isn't. Every comment starts condemned and must earn its place
by matching one of the survivors below. "It seems helpful" is not a match.

**This skill removes and corrects. It never adds.** If a comment is clearly
missing, say so in the report rather than writing it. Fixing an existing comment
that is wrong *is* in scope.

## Survivors

Everything else goes.

1. **Machine-readable directives.** `//nolint`, `# type: ignore`, `# noqa`,
   `# shellcheck disable=SCxxxx`, `#pragma warning disable`, `// eslint-disable`,
   `// Code generated ... DO NOT EDIT.`, license and copyright headers. These are
   program input, not explanation.
2. **Linter-mandated docs.** Where `revive`, CS1591-as-error, or similar require
   a doc on an exported symbol. Check the config; the linter outranks this file.
3. **`TODO` / `FIXME` / `HACK` / `TEMP` — only while still true.** Verify each
   one. If the TODO is done, the FIXME is fixed, the hack is gone, or the temp
   code is now permanent, delete the marker. A marker for work that already
   happened is a lie with a keyword on it.
4. **Public API documentation**, on symbols exposed for callers elsewhere, and
   only stating what the signature cannot: null/empty/error cases, argument
   mutation, what it throws, units, who owns or disposes the return. Hide the
   body and the doc; if the name, parameters, and types already answer those,
   delete it. Judge from the signature, not the body you just read. Private and
   module-internal symbols get none. Document this symbol's contract, never the
   wrapped thing's — inherit (`<inheritdoc cref="..."/>`, `{@inheritDoc}`) and
   write only the delta.

## Delete

- **Wrong comments.** These outrank everything; a drifted comment is worse than
  none.
- **Trivia.** Restating the code, the signature, or the language's semantics.
- **Anything an external doc owns.** A man page, library reference, design doc,
  README, or the program's own `--help`. Don't copy it and don't point to it —
  assume the reader has read it.
- **Duplication.** Same rationale at the definition, the call site, and the test.
  Keep the definition's copy; elsewhere `// See <function>.`
- **Historical narrative.** "This used to…", "the old suite did…". Git holds it.
- **Facts that rot.** Timings, counts, "~40 of them".
- **Restated test names and assertions.**
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
