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

Safe to re-run. An existing correct symlink is left alone; a real file is moved
to `<name>.bak.<timestamp>` before it is replaced, so nothing is lost.

## Packages

| Package | What it configures |
|---|---|
| `shell` | zsh (and, shortly, bash) |

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

A package installer should be idempotent and should honour `DOTFILES_DRY_RUN=1`
by reporting what it would do without doing it.

## Adding a package

1. Create the directory, laying its contents out as they appear under `$HOME`.
2. Add an `install.sh` only if symlinking files is not enough.
3. Add a `README.md` only if the package has behaviour that is not obvious.
   `shell/` earns one; a package that is four symlinked files does not.
4. Add it to the table above.

## Secrets

Nothing secret belongs in this repository. Machine-specific secrets live in
`~/.zsh.local`, outside the tree, which makes committing them impossible rather
than merely discouraged. `.gitignore` covers shell history, completion caches
and installer backups as defence in depth.
