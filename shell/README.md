# shell configuration

A framework-free zsh and bash setup. Everything both shells understand lives in
`shared/` and is defined once. `ZDOTDIR` points at `zsh/`, so zsh reads its
startup files from this repository directly rather than from `$HOME`; bash gets
ordinary symlinks, having no equivalent.

## Install

```sh
./install.sh          # or ../install.sh shell
```

This package has its own installer rather than being mirrored into `$HOME`,
because zsh is not installed file by file: one symlink, `~/.zshenv`, sets
`ZDOTDIR` and everything else follows. bash gets `~/.bashrc` and
`~/.bash_profile`. Open a new terminal to pick up the change, keeping the old
one open until you have confirmed it works. Rollback instructions are printed at
the end of the run.

**Both shells are always installed**, not just the current login shell. bash is
what you land in on machines where zsh is unavailable, and those are exactly the
machines where you cannot run an installer first.

## Layout

```
install.sh      Places ~/.zshenv, ~/.bashrc, ~/.bash_profile; seeds
                ~/.shell.local; makes the cache directories.
bench.sh        Startup benchmark for both shells.

shared/         Sourced by BOTH shells.
  lib.sh        has_command, path_prepend/append, cached_eval, is_interactive
  00-options.sh Environment variables and ls colors
  05-environment.sh  ~/.shell.local, Homebrew, PATH, lazy nvm, os/ + hosts/
  50-aliases.sh Every portable alias; sources functions/
  functions/    One function per file, plain definitions
  os/           Per-OS config: environment, PATH and aliases
  hosts/        Per-machine config: environment, PATH and aliases

zsh/            <- ZDOTDIR
  .zshenv       Every zsh, including scripts. Sets ZDOTDIR. Keep it tiny.
  .zshrc        Interactive shells. Sources conf.d/ in order.
  conf.d/       zsh config, loaded in filename order
  functions/    On fpath, for completion functions (_foo)
  plugins/      Third-party git submodules, checked out by ../install.sh

bash/
  .bash_profile Login shells; hands straight over to ~/.bashrc
  .bashrc       Interactive shells. Sources conf.d/ in order.
  conf.d/       bash config, loaded in filename order

~/.shell.local  Secrets and machine identity, for both shells. Outside the
                repo, never tracked.
```

### What is shared, and what is not

The numbering is mirrored: the same number means the same topic in all three
places, and a shell's file sources its shared counterpart at the top before
adding its own part.

| Topic | Shared | zsh only | bash only |
|---|---|---|---|
| Environment, `ls` colors | ✅ | | |
| PATH, Homebrew, nvm, os/, hosts/ | ✅ | | |
| Aliases | ✅ | `mmv` (`zmv`) | |
| Functions | ✅ | | |
| History, shell options | | `setopt`, `HISTFILE` | `shopt`, `HISTFILE` |
| Prompt | | `PROMPT`, async git `RPROMPT` | `PROMPT_COMMAND` |
| Key bindings | | `bindkey` | `bind` |
| Completion | | `compinit` | `bash-completion` |
| Plugins | | zsh-async, history-substring-search | |

Shared code targets **bash and zsh**, not POSIX `sh`. `local`, `[[ ]]` and
`$(( ))` are fine. Arrays are not — the two shells index them differently — so
`shared/lib.sh` provides `path_append` in place of zsh's `path+=()`.

There is no `.zprofile`. Everything loads from `.zshrc`, because shell
functions are not inherited by child processes: the lazy `nvm` stubs defined
in a login-only file would simply not exist in a non-login interactive shell,
such as a tmux pane on Linux. Non-interactive shells inherit the finished
environment from their parent, as they always did.

### Load order

```
zsh:   ~/.zshenv → ZDOTDIR → .zshrc → shared/lib.sh → zsh/conf.d/*.zsh
bash:  ~/.bash_profile → ~/.bashrc → shared/lib.sh → bash/conf.d/*.bash

both:  NN-*.{zsh,bash} → shared/NN-*.sh, then the shell-specific part
                └─ 05-environment → ~/.shell.local → os/$OS.sh → hosts/$MACHINE.sh
```

`~/.shell.local` is read first because it can set `SHELL_MACHINE`, which selects
the host file. It holds secrets, so it lives outside the repository — that makes
committing it impossible rather than merely discouraged. Both shells read it, so
keep it compatible with both.

### conf.d numbering

The prefixes encode dependencies, not preference:

| File | Why there |
|---|---|
| `00-options` | No dependencies. Pins `HISTFILE` and sets the color variables. |
| `05-environment` | Needs `LS_COLORS` from `00`; provides `HOMEBREW_PREFIX` to `10`. |
| `10-completion` | zsh: must finish building `fpath` *before* `compinit`. bash: sources `bash-completion` if installed. |
| `20-prompt` | Plain `PROMPT` strings; bash builds `PS1` in `PROMPT_COMMAND`. |
| `30-keybinds` | Before plugins, so plugins can override bindings. |
| `40-plugins` | zsh only. Needs `fpath` in place. |
| `41-vcs-prompt` | zsh only. Needs zsh-async from `40`. |
| `50-aliases` | Sources `shared/functions/`. |
| `90-tools` | External inits last, so they win. |
| `95-orphan-rc` | zsh only. Warns about `~/.zshrc` and `~/.zprofile`. Last, so it is seen. |

## Adding configuration

The rule is by *scope*, not by kind. Aliases, PATH entries and environment
variables all follow the same three tiers:

| Applies to | Goes in |
|---|---|
| Every machine | `shared/`, or a shell's `conf.d/` if it cannot be shared |
| One OS | `shared/os/<os>.sh` |
| One box | `shared/hosts/<machine>.sh` |
| Secret, or this machine only | `~/.shell.local` |

Prefer `shared/`. Drop to a shell's own `conf.d/` only when the two shells
genuinely spell something differently.

**An alias or interactive setting** → `shared/50-aliases.sh`, or a new file in
both `conf.d/` directories if it is substantial. Where a capability check is
more accurate than an OS check, prefer it:

```sh
if has_command fatrace && [ -d /mnt/tank ]; then ... fi
```

**A function** → a new file in `shared/functions/` named after the function,
containing a normal `name() { ... }` definition. It is picked up automatically;
there is no list to update. If the shells differ, branch on `$ZSH_VERSION`
*inside* the one function rather than writing two — see `functions/h.sh`.

**PATH** → `path_append` or `path_prepend` from `shared/lib.sh`, in whichever
tier applies. They skip directories that do not exist and never add a duplicate.

**A secret** → `~/.shell.local`. Never anywhere in this repository.

One deliberate exception: the `ls` color variables are all set together in
`shared/00-options.sh`, including the macOS-only pair, rather than being split
across `os/` files. They are one topic, and zsh's `10-completion.zsh` needs
`LS_COLORS` set early regardless.

### A new machine

1. Run `install.sh`.
2. Set `SHELL_MACHINE=<name>` in `~/.shell.local` (install.sh guesses it for you).
3. Add `shared/hosts/<name>.sh` if that machine needs anything specific.

Host selection is `$SHELL_MACHINE`, falling back to the short hostname. The
explicit variable exists because DHCP-assigned hostnames change between
networks.

## Performance

A new terminal tab costs roughly 46ms in zsh, down from ~1.05s, and 56ms in
bash — most of bash's being macOS's login-time `/etc/profile` and `path_helper`,
which cost ~17ms there and only ~1ms in zsh.

- **nvm is lazy-loaded** (`shared/05-environment.sh`). Sourcing `nvm.sh` costs
  ~330ms and was paid by every terminal tab. Stub functions for
  `nvm`/`node`/`npm`/`npx`/`corepack` load it on first use instead.
- **Tool inits are cached** (`cached_eval` in `shared/lib.sh`).
  `zoxide`, `fzf` and `kubectl` each shelled out on every startup to
  regenerate identical output; now that output is cached and regenerated only
  when the tool's binary is newer.
- **`compinit` rebuilds at most daily**, with `-C` otherwise, and its dump
  lives in `$XDG_CACHE_HOME/zsh` rather than `$HOME`.

### Measuring

```sh
./bench.sh                 # both shells, 10 runs each
./bench.sh --shell bash    # one shell
./bench.sh --compare       # login+interactive vs interactive vs login vs bare
./bench.sh --breakdown     # cost per conf.d file
./bench.sh --profile       # zprof, function level, zsh only
```

`--breakdown` answers "what is making this slow". It starts a shell loading
only the first `conf.d` file, then the first two, and so on, and reports each
file's cost as the difference — so it needs no in-shell clock and works
identically in zsh and in bash 3.2. Its totals are lower than the default
mode's because the harness skips the system files a login shell reads; the
baseline line makes that gap visible.

`--profile` goes finer for zsh, attributing time to functions rather than
files. The two agree: `compinit` at ~10ms and `cached_eval` at ~8ms account for
`10-completion` and `90-tools` respectively.

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

**`~/.zshrc` and `~/.zprofile` are dead here, and that is warned about.** With
`ZDOTDIR` set, zsh reads `zsh/.zshrc` and never looks at the copies in `$HOME`.
Installers do not know this — conda, nvm and pyenv append to `~/.zshrc`,
Homebrew and rustup to `~/.zprofile` — so their additions silently do nothing.
`install.sh` moves any existing pair aside as `*.dotfiles-bak`, and
`conf.d/95-orphan-rc.zsh` warns on startup if either reappears.

The warning is deliberately not a fix. Sourcing those files instead would run
things twice, since Homebrew and nvm are already handled in
`05-environment.zsh`, and would paper over the duplication rather than showing
it. Move what you need into `~/.shell.local` and delete the file. The warning
prints once per terminal, not once per pane, and only for non-empty files.

## Third-party code

`plugins/` contains git submodules, each under its own license:

- [zsh-async](https://github.com/mafredri/zsh-async) — MIT
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) — BSD-3-Clause

`conf.d/41-vcs-prompt.zsh` is adapted from
[vincentbernat/zshrc](https://github.com/vincentbernat/zshrc).
