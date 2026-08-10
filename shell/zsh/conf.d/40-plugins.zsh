# Third-party plugins (git submodules under plugins/).
#
# Run `install.sh` or `git submodule update --init` if these are missing; each
# block degrades to a no-op rather than erroring.

# ---------------------------------------------------------------------------
# History substring search: type a prefix, then Up/Down to walk matches.
# ---------------------------------------------------------------------------
if [[ -r $ZDOTDIR/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    source $ZDOTDIR/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

    # Case sensitive.
    unset HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS

    # Bold the matched text, without the default magenta background.
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

# ---------------------------------------------------------------------------
# zsh-async: runs jobs in worker processes. Used only by 41-vcs-prompt.zsh, to
# keep `git status` off the interactive path.
# ---------------------------------------------------------------------------
if [[ -r $ZDOTDIR/plugins/zsh-async/async.zsh ]]; then
    source $ZDOTDIR/plugins/zsh-async/async.zsh
    async_init
fi
