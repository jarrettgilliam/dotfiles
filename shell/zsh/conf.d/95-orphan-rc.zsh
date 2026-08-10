# Warn about $HOME startup files that ZDOTDIR has made inert.
#
# Once ZDOTDIR is set, zsh reads $ZDOTDIR/.zshrc and $ZDOTDIR/.zprofile and
# never looks at ~/.zshrc or ~/.zprofile again. Installers do not know that:
# conda, nvm and pyenv append to ~/.zshrc; Homebrew and rustup append to
# ~/.zprofile. Their additions then silently do nothing, which is a miserable
# thing to debug months later with no memory of why.
#
# Warning rather than sourcing the files is deliberate. Much of what those
# installers add -- Homebrew's shellenv, nvm -- is already handled in
# conf.d/05-environment.zsh, so sourcing them would run it twice and hide the
# duplication instead of surfacing it.
#
# The marker is exported, so this warns once per terminal rather than once per
# shell: tmux panes and nested shells stay quiet.

if [[ -z $ZSH_ORPHAN_RC_CHECKED ]]; then
    export ZSH_ORPHAN_RC_CHECKED=1

    # If ZDOTDIR is $HOME then these files are the ones zsh actually reads,
    # and there is nothing orphaned about them.
    if [[ ${ZDOTDIR:A} != ${HOME:A} ]]; then
        for _orphan in ~/.zshrc ~/.zprofile; do
            [[ -s $_orphan ]] || continue
            print -u2 -r -- "⚠️  ${_orphan/#$HOME/~} exists but zsh never reads it: ZDOTDIR points at $ZDOTDIR."
            print -u2 -r -- "   Something appended to it. Move what you need into ~/.zsh.local, then delete it."
        done
        unset _orphan
    fi
fi
