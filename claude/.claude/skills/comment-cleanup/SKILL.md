---
name: comment-cleanup
description: Comb through code comments to remove duplication, trivia, restated signatures, copied upstream docs, stale historical narrative, rotting facts, and wrong claims, then fix spelling and grammar. Use when asked to clean up, tidy, prune, or audit comments, or when comments have "gotten out of hand."
---

# Comment cleanup

The default is no comment. Code should be self-documenting; a comment is an
admission that it isn't. Delete on sight unless the comment fits one of the two
exceptions below or the never-touch list.

**This skill removes and corrects. It never adds.** Creating a comment where none
exists is out of scope, even when one is clearly missing — say so in the report
instead. Fixing an existing comment that is wrong *is* in scope.

## Never touch

Not explanation — program input, process artifacts, or legally required. Deleting
one breaks lint, CI, or licensing, usually silently.

- Machine-readable directives: `//nolint`, `# type: ignore`, `# noqa`,
  `# shellcheck disable=SCxxxx`, `#pragma warning disable`, `// eslint-disable`.
- `// Code generated ... DO NOT EDIT.`, license and copyright headers.
- Docs on exported symbols where a linter mandates them — `revive`, CS1591 as
  error. The linter outranks every judgment in this file. Check the config.
- `TODO`/`FIXME`, and workaround comments that name a specific upstream issue and
  a removal trigger: `// brew bug 12345, drop when fixed`. These are the only
  thing making the workaround removable later. Vague narrative is still deleted
  (see below).

## Keep: the two exceptions

### 1. Surprise guard

A fact about *this system* that no external doc can state, which a developer
would otherwise reasonably change and be wrong.

```sh
# nvm prepends to PATH on load; source ours first or its node shadows ours.
```

No man page owns this. It exists nowhere but this repo, the failure is silent,
and the natural tidy-up — alphabetizing the sources — breaks it.

The test is not "does this feel surprising." **Go read the external
documentation first.** If the tool's own docs explain the call site, the comment
dies:

```sh
ln -sfn "$src" "$dst"   # -n needs no comment; ln(1) documents this exact idiom
```

These should be rare. Prefer restructuring the code so the surprise disappears —
but only if that genuinely removes it. Extracting a function relocates a
surprise behind a name; it doesn't eliminate it.

### 2. Public API documentation

Only for symbols exposed from a module for callers elsewhere to use, and only
stating what the signature cannot.

**The signature-alone test.** Hide the body and the existing doc. Read only the
name, parameters, return, and types. If you can still answer all of these, delete
the doc:

- empty vs. error vs. null on the missing/empty case
- does it mutate its arguments
- what it throws or panics on
- units and bounds (`timeout` — ms or seconds?)
- who owns the returned value; must the caller close or dispose it

Judge from the signature, not from the body you just read. Everything looks
obvious once you've read the implementation; the caller hasn't.

`parseConfig(path string) (*Config, error)` needs nothing. `trim(s, cutset
string) string` needs nothing. `resize(buf []byte, n int) []byte` needs to say
whether `buf` remains valid.

Weakly typed languages need more of these — the signature carries less. Private
and module-internal symbols generally need none. Packages published for third
parties (NuGet, npm, Go module) are the strong case for keeping thorough docs;
an internal helper is not.

**Document this symbol's contract, not the wrapped thing's.** Copied upstream
docs are wrong on arrival when the wrapper differs:

```csharp
/// <exception cref="InvalidOperationException">The fileName or arguments parameter is null.</exception>
public IProcess Start(string fileName, string? arguments) =>
    new ProcessWrapper(Process.Start(fileName, arguments ?? ""));
```

`arguments ?? ""` means null cannot throw, and `string?` invites it. The doc
contradicts the signature beside it.

Where behavior really is passthrough, inherit instead of copying —
`<inheritdoc cref="..."/>`, `{@inheritDoc}` — and write only the delta. One
caveat: IDEs resolve inheritance against external assemblies reliably, but
static doc generators may emit empty summaries when the referenced XML is
absent. Verify against the project's doc pipeline before applying it broadly.

## Delete

1. **Trivia.** Restating the code, the signature, or the language's semantics.
   `/// <param name="fileName">The file name</param>`.
2. **Anything an external doc owns.** A tool's man page, a library's reference,
   a design doc, README, or the program's own `--help`. Point to it; never copy
   it. A second copy is how the two start disagreeing. This does *not* cover
   facts about how your program's state makes that behavior load-bearing here —
   that's a surprise guard.
3. **Duplication within the codebase.** Same rationale at the definition, the
   call site, and the test. Keep one copy at the definition; elsewhere
   `// See <function>: <one-line summary>.`
4. **Historical narrative.** "This used to…", "the old suite did…", "the gap this
   change closed." Git holds this. Watch for stale references to removed flags,
   files, or functions — those are also category 7.
5. **Facts that rot.** Benchmark timings, environment-specific counts, "~40 of
   them", "takes about 0.2s". The reasoning survives without the number.
6. **Restating a test name or the assertion below it.** A subtest called "keeps
   every line" needs no comment saying nothing is truncated. Keep only the part
   explaining *why it matters*.
7. **Wrong comments.** These outrank everything — a drifted comment is worse than
   no comment. See the audit.

## Prefer code over comments

- A comment above several lines usually wants to be an extracted function whose
  name replaces it.
- A comment explaining a magic value wants to be a named constant:
  `return 127 // not found, as a shell reports it` becomes `return exitNotFound`.
- A comment explaining a cryptic name wants a rename.

**A refactor is never a reason a surprise guard dies.** After extraction the
comment sits beside different code, and the easy read is "no longer matches what's
below — cut." It doesn't: it explains one line, and it follows that line into its
new home.

## The audit

Do not take a comment's word for anything. For each claim about behavior:

- Read the code it sits on and confirm it still does that. Wrapper docs are the
  richest source of false claims — compare against the local body first.
- For a claim about a dependency, **read the dependency's source** — not its
  docs, and not memory. Module cache, vendor directory, or standard library.
- For a claim about an external tool, run the tool.

When a claim is wrong, check whether its *conclusion* still holds. Often the
stated fact is wrong while the reasoning survives: correct the fact and keep the
reasoning rather than deleting both.

## Spelling and grammar

- American spelling unless the project has clearly settled on another convention
  — then match the project and say so rather than converting it.
- Sweep by pattern rather than by what you happened to notice: `-our`, `-ise`,
  `-isation`, `-re`, doubled-`l`, `-ement`. Most hits are false positives
  (`exercise`, `otherwise`, `promises`, `detour`), so read every one.
- Fix subject-verb agreement, misplaced modifiers, sentence fragments, and
  antecedents left dangling by your own trimming.
- Do not "fix" deliberate fragments. Comments idiomatically drop subjects.

## Working rules

- Read whole files before cutting. Duplication is only visible across a file, and
  often only across files.
- Trimming a sentence frequently strands a pronoun or a "so" in the next one.
  Re-read what you edited; cutting your own earlier edit is normal.
- Before editing user-facing help text or subtest names, check whether any test
  asserts on that prose.
- Run the formatter, the linter, and the full test suite when done.
- Report removals grouped by category. Surface judgment calls and missing-doc
  gaps explicitly instead of burying them in a diff.
