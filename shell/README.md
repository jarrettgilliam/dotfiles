# shell configuration

A framework-free zsh setup. `ZDOTDIR` points at `zsh/`, so zsh reads its
startup files from this repository directly rather than from `$HOME`.

## Install

```sh
./install.sh          # or ../install.sh shell
```

This package has its own installer rather than being mirrored into `$HOME`,
because zsh is not installed file by file: exactly one file is placed in
`$HOME` — `~/.zshenv`, a symlink to `zsh/.zshenv`. It sets `ZDOTDIR`, and
everything else follows from that. Open a new terminal to pick up the change,
keeping the old one open until you have confirmed it works. Rollback
instructions are printed at the end of the run.

## Layout

```
install.sh     Places ~/.zshenv, seeds ~/.zsh.local, makes the cache dir.
bench.zsh      Startup benchmark. Kept out of zsh/ so ZDOTDIR holds only
               files zsh reads.

zsh/           <- ZDOTDIR
  .zshenv      Every zsh, including scripts. Sets ZDOTDIR. Keep it tiny.
  .zshrc       Interactive shells. Sources conf.d/ in order.

  conf.d/      Config, loaded in filename order.
  functions/   Autoloaded functions, one per file.
  os/          Per-OS config: environment, PATH and aliases.
  hosts/       Per-machine config: environment, PATH and aliases.
  plugins/     Third-party git submodules, checked out by ../install.sh.

~/.zsh.local   Secrets and machine identity. Outside the repo, never tracked.
```

`bash/` and `shared/` will join `zsh/` here: bash config, and the POSIX subset
both shells source rather than duplicate. Paths below are relative to `zsh/`.

There is no `.zprofile`. Everything loads from `.zshrc`, because shell
functions are not inherited by child processes: the lazy `nvm` stubs defined
in a login-only file would simply not exist in a non-login interactive shell,
such as a tmux pane on Linux. Non-interactive shells inherit the finished
environment from their parent, as they always did.

### Load order

```
~/.zshenv → ZDOTDIR
   ↓
.zshrc → conf.d/*.zsh
             └─ 05-environment.zsh → ~/.zsh.local → os/$OS.zsh → hosts/$MACHINE.zsh
```

`~/.zsh.local` is read first because it can set `ZSH_MACHINE`, which selects
the host file. It holds secrets, so it lives outside the repository — that
makes committing it impossible rather than merely discouraged.

### conf.d numbering

The prefixes encode dependencies, not preference:

| File | Why there |
|---|---|
| `00-options` | No dependencies. Pins `HISTFILE` and sets the color variables. |
| `05-environment` | Needs `LS_COLORS` from `00`; provides `HOMEBREW_PREFIX` to `10`. |
| `10-completion` | Must finish building `fpath` *before* `compinit`. Defines `cached_eval`. |
| `20-prompt` | Plain `PROMPT` strings. |
| `30-keybinds` | Before plugins, so plugins can override bindings. |
| `40-plugins` | Needs `fpath` in place. |
| `41-vcs-prompt` | Needs zsh-async from `40`. |
| `50-aliases` | Registers the `functions/` autoloads. |
| `90-tools` | External inits last, so they win. |

## Adding configuration

The rule is by *scope*, not by kind. Aliases, PATH entries and environment
variables all follow the same three tiers:

| Applies to | Goes in |
|---|---|
| Every machine | `conf.d/` |
| One OS | `os/<os>.zsh` |
| One box | `hosts/<machine>.zsh` |
| Secret, or this machine only | `~/.zsh.local` |

**An alias or interactive setting** → `conf.d/50-aliases.zsh`, or a new
`conf.d/` file if it is substantial. Where a capability check is more accurate
than an OS check, prefer it:

```zsh
if (( $+commands[fatrace] )) && [[ -d /mnt/tank ]]; then ... fi
```

**A function** → a new file in `functions/` named after the function,
containing the body only (no `function name() { ... }` wrapper), then add the
name to the `autoload -Uz` line in `conf.d/50-aliases.zsh`.

**PATH** → use `path+=(...)` in whichever tier applies; `typeset -U`
deduplicates.

**A secret** → `~/.zsh.local`. Never anywhere in this repository.

One deliberate exception: the `ls` color variables are all set together in
`00-options.zsh`, including the macOS-only pair, rather than being split
across `os/` files. They are one topic, and `10-completion.zsh` needs
`LS_COLORS` set early regardless.

### A new machine

1. Run `install.sh`.
2. Set `ZSH_MACHINE=<name>` in `~/.zsh.local` (install.sh guesses it for you).
3. Add `hosts/<name>.zsh` if that machine needs anything specific.

Host selection is `${ZSH_MACHINE:-${HOST%%.*}}`. The explicit variable exists
because DHCP-assigned hostnames change between networks.

## Performance

Startup is roughly 46ms for a login+interactive shell, down from ~1.05s:

- **nvm is lazy-loaded** (`05-environment.zsh`). Sourcing `nvm.sh` costs
  ~330ms and was paid by every terminal tab. Stub functions for
  `nvm`/`node`/`npm`/`npx`/`corepack` load it on first use instead.
- **Tool inits are cached** (`cached_eval` in `10-completion.zsh`).
  `zoxide`, `fzf` and `kubectl` each shelled out on every startup to
  regenerate identical output; now that output is cached and regenerated only
  when the tool's binary is newer.
- **`compinit` rebuilds at most daily**, with `-C` otherwise, and its dump
  lives in `$XDG_CACHE_HOME/zsh` rather than `$HOME`.

Measure with `./bench.zsh`, or `./bench.zsh --profile` for a `zprof`
breakdown.

> Because `compinit` only does a full rebuild once a day, **adding or removing
> a completion may not take effect immediately** — a deleted one can linger as
> a broken autoload stub. Force a rebuild with:
>
> ```sh
> rm "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/zcompdump
> ```
>
> The same applies to `cached_eval` output if a tool changes its init script
> without the binary's timestamp changing: `rm ~/.cache/zsh/<tool>.zsh`.

## Notes

**`HISTFILE` is pinned in `00-options.zsh`, deliberately.** macOS `/etc/zshrc`
contains `HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history`. Since `ZDOTDIR` is now
set, that would relocate shell history *into this repository*. The assignment
must be unconditional, because `/etc/zshrc` has already run by that point.

**`ZDOTDIR` is not exported.** Every zsh re-reads `~/.zshenv` and re-derives
it, so exporting gains nothing — but an exported value would follow you into
`sudo -s` and point root's shell at this config.

## Third-party code

`plugins/` contains git submodules, each under its own license:

- [zsh-async](https://github.com/mafredri/zsh-async) — MIT
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) — BSD-3-Clause

`conf.d/41-vcs-prompt.zsh` is adapted from
[vincentbernat/zshrc](https://github.com/vincentbernat/zshrc).
