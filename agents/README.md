# coding agent configuration

Configuration for Claude Code, GitHub Copilot CLI and OpenAI Codex CLI. The
instructions and the skills are written once in `shared/` and installed into all
three; everything a single tool owns lives beside its own name.

## Install

```sh
./install.sh          # or ../install.sh agents
```

This package has its own installer rather than being mirrored into `$HOME`,
because each shared file has three destinations and every tool spells them
differently:

| | Instructions | Skills |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/` |
| Copilot CLI | `~/.copilot/copilot-instructions.md` | `~/.copilot/skills/` |
| Codex CLI | `~/.codex/AGENTS.md` | `~/.codex/skills/` |

## Layout

```
install.sh      Mirrors claude/ into $HOME, then links shared/ three times.

shared/         Read by every tool.
  AGENTS.md     Global instructions
  skills/       One directory per skill, each with a SKILL.md

claude/         Claude Code only, laid out as it appears under $HOME.
  .claude/settings.json     Permissions, model, hooks, status line
  .claude/statusline.sh     Status line, invoked by settings.json
  .claude/output-styles/    Output styles
```

A skill is a directory under `shared/skills/` holding a `SKILL.md` — YAML
frontmatter naming and describing it, then the instructions. Every file in the
directory is installed, so a skill may carry scripts and reference files
alongside it. All three tools read the same format; adding a skill needs no
installer change.

## Adding a tool's own configuration

Give it a `$HOME`-shaped subtree next to `claude/` — `codex/.codex/config.toml`,
`copilot/.copilot/config.json` — and one more `mirror_tree` line in
`install.sh`. Anything a tool writes for itself (credentials, session history,
caches) lands in the real `~/.claude`, `~/.copilot` or `~/.codex`, because files
are linked one by one and never as whole directories.
