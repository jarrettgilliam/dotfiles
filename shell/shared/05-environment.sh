# Environment: secrets, PATH, package managers, and the machine layers.
#
# Loaded from each shell's conf.d rather than a login-only file, because shell
# functions are not inherited by child processes: the nvm stubs below would
# simply not exist in a non-login interactive shell -- a tmux pane on Linux
# would have no `node` at all.

# Machine identity and secrets. Outside the repository, so it cannot be
# committed. Read first: it can set SHELL_MACHINE, which selects the host file
# at the bottom of this file.
[ -r "$HOME/.shell.local" ] && . "$HOME/.shell.local"

# ---------------------------------------------------------------------------
# Homebrew
#
# Not macOS-only: Linuxbrew installs to /home/linuxbrew or ~/.linuxbrew.
# Skipped entirely when HOMEBREW_PREFIX is already set, so nested shells do
# not re-pay the ~20ms `brew shellenv` eval. The generated output is plain
# `export` statements, identical for bash and zsh.
# ---------------------------------------------------------------------------
if [ -z "${HOMEBREW_PREFIX-}" ]; then
    for _brew in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew \
        /home/linuxbrew/.linuxbrew/bin/brew \
        "$HOME/.linuxbrew/bin/brew"
    do
        if [ -x "$_brew" ]; then
            eval "$("$_brew" shellenv)"
            break
        fi
    done
    unset _brew
fi

# ---------------------------------------------------------------------------
# PATH additions common to every machine.
# ---------------------------------------------------------------------------
path_append "$HOME/bin"
path_append "$HOME/.local/bin"
path_append "$HOME/.dotnet/tools"

# Ancient standalone git installers put git outside the default PATH.
if ! has_command git && [ -d /usr/local/git/bin ]; then
    path_append /usr/local/git/bin
fi

export PATH

# ---------------------------------------------------------------------------
# Node / nvm, lazily.
#
# Sourcing nvm.sh eagerly costs ~330ms, paid by every shell whether or not
# node is used. (~/.nvm/alias/default is `lts/*`, so nvm resolves aliases at
# every load.) These stubs defer that until the first node/npm/nvm call.
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    _nvm_load() {
        # Remove the stubs first, so the real definitions win. `unset -f` is
        # the portable spelling of zsh's `unfunction`.
        unset -f nvm node npm npx corepack _nvm_load 2>/dev/null
        . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    }
    for _cmd in nvm node npm npx corepack; do
        eval "${_cmd}() { _nvm_load; ${_cmd} \"\$@\"; }"
    done
    unset _cmd
fi

# ---------------------------------------------------------------------------
# Machine layers, least- to most-specific. Everything OS-specific belongs in
# os/, everything box-specific in hosts/ -- including aliases, which is why
# these are sourced here rather than from a login-only file.
# ---------------------------------------------------------------------------
case "$OSTYPE" in
    darwin*)       _os=darwin ;;
    linux*)        _os=linux  ;;
    msys*|cygwin*) _os=msys   ;;
    *)             _os=       ;;
esac
if [ -n "$_os" ] && [ -r "$DOTFILES_SHELL/shared/os/$_os.sh" ]; then
    . "$DOTFILES_SHELL/shared/os/$_os.sh"
fi

# SHELL_MACHINE (from ~/.shell.local) wins over the hostname, which on some
# machines is DHCP-assigned and changes between networks.
if [ -n "${SHELL_MACHINE-}" ]; then
    _machine=$SHELL_MACHINE
else
    _machine=$(uname -n)
    _machine=${_machine%%.*}
fi
if [ -r "$DOTFILES_SHELL/shared/hosts/$_machine.sh" ]; then
    . "$DOTFILES_SHELL/shared/hosts/$_machine.sh"
fi

unset _os _machine
