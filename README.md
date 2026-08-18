# dotfiles

Personal configuration, organized as independent packages and installed by
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

> If symlinks are unavailable the installer writes a **copy** instead of failing. Re-run `./install.sh`
> to get updates. Backups are only created when the files have different contents.

### Cleaning up backups

Every file this repository displaces is renamed to

```
<original name>.<timestamp>.dotfiles-bak
```

The distinctive final extension exists so that all of them, from every package
and every run, can be found and removed with one command:

```sh
find ~/.[^.]* -maxdepth 3 -name '*.dotfiles-bak' -print  # review
find ~/.[^.]* -maxdepth 3 -name '*.dotfiles-bak' -delete # delete
```

## Machine-local overrides

Two files, both outside the tree and untracked:

| File | Holds |
|---|---|
| `~/.shell.local` | `SHELL_MACHINE`, secrets, anything specific to one box. Read by bash and zsh. |
| `~/.gitconfig.local` | git settings for one machine, including a different identity |

## How a package is installed

A package is any top-level directory not starting with a dot. There are two ways
one gets installed, and the installer picks automatically:

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

Targets are relative to the link's own directory when this repository lives
under `$HOME`, so a `$HOME` that moves — a restored backup, a different mount
point — keeps working. A checkout outside `$HOME` gets absolute targets instead.

**2. Its own `install.sh`** — if a package contains an executable `install.sh`,
that script runs instead and is entirely responsible for the package. `shell`
does this: zsh is not installed file by file, but by pointing `ZDOTDIR` at the
repository with a single `~/.zshenv` symlink.

Submodules are **not** a package's concern. The top-level script checks out
every submodule in the repository before installing anything, so a package that
gains one later needs no installer change and there is no list to keep in sync.

A package installer sources `install-lib.sh` and gets idempotency, backups,
`--dry-run` and the copy fallback from it. See "Writing a package installer".

## Adding a package

1. Create the directory, laying its contents out as they appear under `$HOME`.
2. Add an `install.sh` only if symlinking files is not enough.
3. Add a `README.md` only if the package has behavior that is not obvious.
   `shell/` earns one; a package that is four symlinked files does not.

There is no list to register it in: `install.sh` discovers packages by looking
for top-level directories.

### Writing a package installer

Only for a package that symlinking files cannot express. Three lines of header,
then say what the package needs:

```bash
#!/bin/bash
set -u

PKG_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$PKG_DIR/../install-lib.sh"

link_home "$PKG_DIR/.tmux.conf"
ensure_dir "$HOME/.tmux/plugins"

write_file --no-clobber "$HOME/.tmux.local.conf" <<'EOF'
# Machine-local tmux settings. Not tracked in git.
EOF
```

Every verb below already honors `DOTFILES_DRY_RUN`, backs up whatever it
displaces, falls back to a copy where symlinks are unavailable, and prints one
line per path — so an installer contains only its own decisions, and
`./install.sh --dry-run` covers it without the script doing anything special.

| Verb | Does |
|---|---|
| `link_file [--no-copy] <src> <dest>` | Idempotent symlink. `--no-copy` returns 1 rather than copying, for a file that would be wrong as a copy. |
| `link_home [--no-copy] <src> [name]` | `link_file` into `$HOME`; `name` defaults to the basename and may contain slashes. |
| `mirror_tree <package-dir>` | Link every file in the package to the matching path under `$HOME` — what a package with no installer gets. |
| `write_file [--no-clobber] [--not-linked] <path> [mode]` | Write from stdin. `--no-clobber` keeps an existing file, correcting only a mode looser than `mode`. Identical content is left alone. |
| `ensure_dir <dir>...` | Create directories. |
| `backup_file <path>` | Move a path aside; sets `DOTFILES_LAST_BACKUP`. |
| `tildify <path>` | Shorten a path under `$HOME`, for your own messages. |

Two flags are there to read: `DOTFILES_CHANGED`, set when anything was changed
(or in a dry run would have been), and `DOTFILES_FAILED`.

Exit non-zero if something genuinely failed; the top-level installer treats that
as fatal for the whole run. Print only your own package's portion — the summary
and the backup notice belong to the top-level script.

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
