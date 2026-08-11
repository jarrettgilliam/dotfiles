# Warn about $HOME startup files that ZDOTDIR has made inert -- see README.md.
# The marker is exported, so tmux panes and nested shells stay quiet

if [[ -z $ZSH_ORPHAN_RC_CHECKED ]]; then
    export ZSH_ORPHAN_RC_CHECKED=1

    # If ZDOTDIR is $HOME then zsh really does read these
    if [[ ${ZDOTDIR:A} != ${HOME:A} ]]; then
        for _orphan in ~/.zshrc ~/.zprofile; do
            [[ -s $_orphan ]] || continue
            print -u2 -r -- "⚠️  ${_orphan/#$HOME/~} exists but zsh never reads it: ZDOTDIR points at $ZDOTDIR."
            print -u2 -r -- "   Something appended to it. Move what you need into ~/.shell.local, then delete it."
        done
        unset _orphan
    fi
fi
