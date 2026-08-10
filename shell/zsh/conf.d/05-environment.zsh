# Environment: secrets, PATH, package managers, and the machine layers.
#
# Runs at 05 because 10-completion.zsh needs $HOMEBREW_PREFIX to assemble
# fpath, and needs $LS_COLORS (00-options.zsh) for its list-colors.
#
# This lives in conf.d rather than .zprofile because .zprofile only runs for
# LOGIN shells. Shell functions are not inherited by child processes, so the
# nvm stubs below would simply not exist in a non-login interactive shell --
# a tmux pane on Linux would have no `node` at all.

typeset -U path PATH fpath

# Machine identity and secrets. Outside the repo, so it cannot be committed.
# Read first: it can set ZSH_MACHINE, which selects the host file below.
[[ -r ~/.zsh.local ]] && source ~/.zsh.local

# ---------------------------------------------------------------------------
# Homebrew
#
# Not macOS-only: Linuxbrew installs to /home/linuxbrew or ~/.linuxbrew.
# Skipped entirely when HOMEBREW_PREFIX is already set, so nested shells do
# not re-pay the ~20ms `brew shellenv` eval.
# ---------------------------------------------------------------------------
if [[ -z $HOMEBREW_PREFIX ]]; then
    for _brew in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew \
        /home/linuxbrew/.linuxbrew/bin/brew \
        $HOME/.linuxbrew/bin/brew
    do
        if [[ -x $_brew ]]; then
            eval "$($_brew shellenv)"
            break
        fi
    done
    unset _brew
fi

# ---------------------------------------------------------------------------
# PATH additions common to every machine.
# ---------------------------------------------------------------------------
for _dir in $HOME/bin $HOME/.local/bin $HOME/.dotnet/tools; do
    [[ -d $_dir ]] && path+=($_dir)
done
unset _dir

# Ancient standalone git installers put git outside the default PATH. The old
# aliases.sh test for this was `[ $(which git >/dev/null) = $(false) -a ... ]`,
# where both substitutions expanded to nothing -- leaving `[ = -a -d ... ]`,
# which never did what it looked like.
if (( ! $+commands[git] )) && [[ -d /usr/local/git/bin ]]; then
    path+=(/usr/local/git/bin)
fi

# ---------------------------------------------------------------------------
# Node / nvm, lazily.
#
# Sourcing nvm.sh eagerly costs ~330ms, paid by every shell whether or not
# node is used. (~/.nvm/alias/default is `lts/*`, so nvm resolves aliases at
# every load.) These stubs defer that until the first node/npm/nvm call.
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [[ -s $NVM_DIR/nvm.sh ]]; then
    _nvm_load() {
        # Remove the stubs first, so the real definitions win.
        unfunction nvm node npm npx corepack _nvm_load 2>/dev/null
        source $NVM_DIR/nvm.sh
        [[ -s $NVM_DIR/bash_completion ]] && source $NVM_DIR/bash_completion
    }
    for _cmd in nvm node npm npx corepack; do
        eval "${_cmd}() { _nvm_load; ${_cmd} \"\$@\"; }"
    done
    unset _cmd
fi

# ---------------------------------------------------------------------------
# Machine layers, least- to most-specific. Everything OS-specific belongs in
# os/, everything box-specific in hosts/ -- including aliases, which is why
# these are sourced here rather than from .zprofile.
# ---------------------------------------------------------------------------
case $OSTYPE in
    darwin*)       _os=darwin ;;
    linux*)        _os=linux  ;;
    msys*|cygwin*) _os=msys   ;;
    *)             _os=       ;;
esac
[[ -n $_os && -r $ZDOTDIR/os/$_os.zsh ]] && source $ZDOTDIR/os/$_os.zsh

# ZSH_MACHINE (from ~/.zsh.local) wins over the hostname, which on some
# machines is DHCP-assigned and changes between networks.
_machine=${ZSH_MACHINE:-${HOST%%.*}}
[[ -r $ZDOTDIR/hosts/$_machine.zsh ]] && source $ZDOTDIR/hosts/$_machine.zsh

unset _os _machine
