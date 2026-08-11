# Third-party plugins (git submodules under plugins/).

# History substring search
if [[ -r $ZDOTDIR/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    source $ZDOTDIR/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

    # Case sensitive.
    unset HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS

    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=red,bold'

    # terminfo sequences cover most terminals; the raw ^[[A/^[[B fallbacks
    # cover the rest (notably tmux and the Windows console).
    [[ -n $terminfo[kcuu1] ]] && {
        bindkey -M emacs "$terminfo[kcuu1]" history-substring-search-up
        bindkey -M viins "$terminfo[kcuu1]" history-substring-search-up
    }
    [[ -n $terminfo[kcud1] ]] && {
        bindkey -M emacs "$terminfo[kcud1]" history-substring-search-down
        bindkey -M viins "$terminfo[kcud1]" history-substring-search-down
    }
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

# zsh-async: Used to make git integration asynchronous
if [[ -r $ZDOTDIR/plugins/zsh-async/async.zsh ]]; then
    source $ZDOTDIR/plugins/zsh-async/async.zsh
    async_init
fi
