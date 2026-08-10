# dotfiles

Personal configuration, organised as independent packages and installed by
symlink.

## Install

```sh
./install.sh                 # every package
./install.sh shell vim       # only the named ones
./install.sh --list          # what is available
./install.sh --dry-run       # show what would happen, change nothing
```

Safe to re-run. An existing correct symlink is left alone; anything real that is
in the way is renamed before being replaced, so nothing is lost.

### Cleaning up backups

Every file this repository displaces is renamed to

```
<original name>.<timestamp>.dotfiles-bak
```

The distinctive final extension exists so that all of them, from every package
and every run, can be found and removed with one command:

```sh
find ~ -maxdepth 4 -path ~/Library -prune -o -name '*.dotfiles-bak' -print    # review
find ~ -maxdepth 4 -path ~/Library -prune -o -name '*.dotfiles-bak' -delete   # delete
```

Pruning `~/Library` is only for macOS, where descending into it is slow and
emits permission errors for protected directories.

The extension is deliberately not `.bak`: other software uses that, and this
machine already has unrelated `.bak.1` files under `~/.lmstudio`. A cleanup
command should never be able to catch something this repository did not create.

Package installers use the same convention; the top-level script exports
`DOTFILES_BAK_SUFFIX` so a whole run shares one timestamp.

## Packages

| Package | What it configures |
|---|---|
| `shell` | zsh (and, shortly, bash) |
| `git` | `~/.gitconfig`, the global ignore file, and the default identity |
| `tmux` | `~/.tmux.conf` |
| `vim` | `~/.vimrc` and colorschemes |

## How a package is installed

A package is any top-level directory. There are two ways one gets installed,
and the installer picks automatically:

**1. Mirror `$HOME`** — the default, and what most packages want. The package's
inner tree mirrors `$HOME`, and every file in it is symlinked to the matching
path:

```
vim/.vimrc                    ->  ~/.vimrc
vim/.vim/colors/dante.vim     ->  ~/.vim/colors/dante.vim
ghostty/.config/ghostty/config -> ~/.config/ghostty/config
```

Files are linked individually rather than linking whole directories. That way
files an application writes itself — `~/.vim/.netrwhist`, swap files, spell
dictionaries — land in your real home directory instead of turning up as
untracked changes here.

`install.sh`, `README*`, `LICENSE*`, `.gitignore` and `.DS_Store` are treated as
repository files and never linked.

**2. Its own `install.sh`** — if a package contains an executable `install.sh`,
that script runs instead and is entirely responsible for the package. `shell`
does this: zsh is not installed file by file, but by pointing `ZDOTDIR` at the
repository with a single `~/.zshenv` symlink.

Submodules are **not** a package's concern. The top-level script checks out
every submodule in the repository before installing anything, so a package that
gains one later needs no installer change and there is no list to keep in sync.

A package installer should be idempotent and should honour `DOTFILES_DRY_RUN=1`
by reporting what it would do without doing it.

## Adding a package

1. Create the directory, laying its contents out as they appear under `$HOME`.
2. Add an `install.sh` only if symlinking files is not enough.
3. Add a `README.md` only if the package has behaviour that is not obvious.
   `shell/` earns one; a package that is four symlinked files does not.
4. Add it to the table above.

## Machine-local overrides

Two files, both outside the tree so that committing them is impossible rather
than merely discouraged:

| File | Holds |
|---|---|
| `~/.zsh.local` | `ZSH_MACHINE`, secrets, anything shell-specific to one box |
| `~/.gitconfig.local` | git settings for one machine, including a different identity |

`.gitignore` additionally covers shell history, completion caches and installer
backups, as defence in depth.

### A machine with a different git identity

`git/.gitconfig` includes `~/.gitconfig.local` **last**, and for a single-valued
key such as `user.email` the last value read wins — so that file can replace the
default identity outright. Exceptions to the new default point back at the
tracked `identity-personal` snippet, which is why the identity lives in its own
file rather than inline:

```ini
# ~/.gitconfig.local -- untracked, on a machine that defaults to another address
[user]
	email = you@example.com

[includeIf "hasconfig:remote.*.url:git@github.com:*/**"]
	path = ~/.config/git/identity-personal
[includeIf "hasconfig:remote.*.url:https://github.com/**"]
	path = ~/.config/git/identity-personal
```

Two things silently break this if you get them wrong:

- **Order matters.** The unconditional `[user]` block must come *before* the
  `includeIf` blocks. After them, it overwrites the identity they just set.
- **Patterns need `**`, not `*`.** Matching uses gitdir's globbing rules, where
  `*` does not cross `/`. So `*github.com*` fails to match
  `git@github.com:you/repo.git` — the trailing `*` would have to cover
  `:you/repo.git`. Hence `git@github.com:*/**`, and a second block if you clone
  over both SSH and HTTPS.

`includeIf` cannot be negated and selects a *file* rather than a value, which is
why the exception needs something to point at. It cannot point at `.gitconfig`
itself: that file includes `~/.gitconfig.local`, which would create a loop.
`hasconfig` needs git 2.36+, and is evaluated against config as it is read, so
it behaves oddly during `git clone` itself — by the time you commit, the remote
exists and it resolves correctly.

## Third-party code

- `shell/zsh/plugins/` — git submodules, each under its own license:
  [zsh-async](https://github.com/mafredri/zsh-async) (MIT) and
  [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
  (BSD-3-Clause).
- `shell/zsh/conf.d/41-vcs-prompt.zsh` is adapted from
  [vincentbernat/zshrc](https://github.com/vincentbernat/zshrc).
- `vim/.vim/colors/solarized.vim` — Ethan Schoonover, MIT.
- `vim/.vim/colors/dante.vim` — Caciano Machado, 2002. States no license; its
  header comment is the only attribution and is preserved intact.
