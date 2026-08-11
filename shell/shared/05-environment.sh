# Environment: secrets, PATH, package managers, and the machine layers.

# Read first: it can set SHELL_MACHINE, which selects the host file at the
# bottom of this file.
[ -r "$HOME/.shell.local" ] && . "$HOME/.shell.local"

# Homebrew (macOS AND Linux)
# Skipping this when HOMEBREW_PREFIX is already set saves nested shells a
# subprocess, but also means they never see the fpath entry brew emits.
# 10-completion.(zsh|bash) adds that back.
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

path_append "$HOME/bin"
path_append "$HOME/.local/bin"
path_append "$HOME/.dotnet/tools"

# Ancient standalone git installers put git outside the default PATH.
if ! has_command git && [ -d /usr/local/git/bin ]; then
    path_append /usr/local/git/bin
fi

export PATH

# Node / nvm, lazily. A `default` alias of `lts/*` is what makes an eager load
# so expensive: nvm resolves aliases every time.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    _nvm_load() {
        # Remove the stubs first, so the real definitions win.
        unset -f nvm node npm npx corepack _nvm_load 2>/dev/null
        . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    }
    for _cmd in nvm node npm npx corepack; do
        eval "${_cmd}() { _nvm_load; ${_cmd} \"\$@\"; }"
    done
    unset _cmd
fi

# Load OS-specific things
case "$OSTYPE" in
    darwin*)       _os=darwin ;;
    linux*)        _os=linux  ;;
    msys*|cygwin*) _os=msys   ;;
    *)             _os=       ;;
esac
if [ -n "$_os" ] && [ -r "$DOTFILES_SHELL/shared/os/$_os.sh" ]; then
    . "$DOTFILES_SHELL/shared/os/$_os.sh"
fi

# Load machine specific things
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
