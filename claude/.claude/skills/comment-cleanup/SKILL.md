---
name: comment-cleanup
description: Comb through code comments to remove duplication, trivia, stale historical narrative, rotting facts, and wrong claims, then fix spelling and grammar. Use when asked to clean up, tidy, prune, or audit comments, or when comments have "gotten out of hand."
---

# Comment cleanup

Comments are load-bearing or they are noise. Remove the noise without gutting the
reasoning that keeps the next reader from making a mistake.

## The keep test

**A comment survives if it names a plausible wrong alternative and says why it
lost.** "Lstat, not Stat, so a symlinked entry stays excluded" earns its place.
"increment the counter" does not.

Apply this before reaching for the categories below — it decides the close calls.

## Remove

1. **Duplication.** The same rationale at the definition, at the call site, and
   again in the test. Keep one copy, at the definition; elsewhere point to it by
   name — `// See <function>: <one-line summary>.`

   Also across units: a comment restating what a design doc, README, or the
   program's own `--help` output already says. The dedicated document wins, and
   a stale second copy is how the two start disagreeing.

2. **Trivia.** Restating the code, the signature, or the language's semantics.

3. **Historical narrative.** "This used to…", "the old suite did…", "the gap this
   change closed." Git history holds this. Watch for stale references to removed
   flags, files, or functions; those are also category 7.

4. **Facts that rot.** Benchmark timings, environment-specific counts, "~40 of
   them", "takes about 0.2s". The reasoning survives without the number.

5. **Restating the test name or the assertion below it.** A subtest called "keeps
   every line" needs no comment saying nothing is truncated, and a section header
   above assertions whose failure messages already say it is noise. Keep only the
   part explaining *why it matters*.

6. **Arguing with a hypothetical editor.** "Guards against a fix that reaches
   for…" Keep the fact, drop the framing.

7. **Wrong comments.** These outrank everything — a drifted comment is worse than
   no comment. See the audit below.

## Prefer code over comments

A comment explaining a magic value usually wants to be a named constant:
`return 127 // not found, as a shell reports it` becomes `return exitNotFound`.
Same for a comment explaining a cryptic name — rename the thing instead.

## The audit

Do not take a comment's word for anything. For each claim about behavior:

- Read the code it sits on and confirm it still does that.
- For a claim about a dependency, **read the dependency's source** — not its
  docs, and not memory. Module cache, vendor directory, or standard library.
- For a claim about an external tool, run the tool.

When a claim turns out to be wrong, check whether its *conclusion* still holds.
Often the stated fact is wrong while the reasoning survives: correct the fact and
keep the reasoning, rather than deleting both.

## Spelling and grammar

- Use American spelling unless the project has clearly settled on another
  convention — then match the project and say so rather than converting it.
- Sweep by pattern rather than by what you happened to notice: `-our`, `-ise`,
  `-isation`, `-re`, doubled-`l`, `-ement`. Most hits are false positives
  (`exercise`, `otherwise`, `promises`, `detour`), so read every one.
- Fix real errors: subject-verb agreement, misplaced modifiers, sentence
  fragments, and antecedents left dangling by your own trimming.
- Do not "fix" deliberate fragments. Comments idiomatically drop subjects.

## Working rules

- Read whole files before cutting. Duplication is only visible across a file, and
  often only across files.
- Trimming a sentence frequently strands a pronoun or a "so" in the next one.
  Re-read what you edited; cutting your own earlier edit is normal.
- Before editing user-facing help text or subtest names, check whether any test
  asserts on that prose.
- Run the formatter, the vetter/linter, and the full test suite when done.
- Report removals grouped by category, and surface judgment calls explicitly
  instead of burying them in a diff.
