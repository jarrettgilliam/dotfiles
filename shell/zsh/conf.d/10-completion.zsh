# Completion system.
#
# ORDER MATTERS: fpath must be fully assembled before compinit runs. The old
# config appended to fpath *after* calling compinit, which is why the beets
# completion never worked.

typeset -U fpath

# Our own completions. The shell functions that used to live here are plain
# definitions in shared/functions/ now, so bash can use them too; this stays
# on fpath for completion functions (_foo), which have no bash equivalent.
fpath=($ZDOTDIR/functions $fpath)

# Homebrew's site-functions. `brew shellenv` (os/darwin.zsh) already adds this
# for login shells, but fpath is not exported, so non-login interactive shells
# -- tmux panes, nested shells -- would otherwise miss it. typeset -U above
# collapses the duplicate. Uses $HOMEBREW_PREFIX rather than a `brew --prefix`
# subprocess.
if [[ -n $HOMEBREW_PREFIX && -d $HOMEBREW_PREFIX/share/zsh/site-functions ]]; then
    fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
fi

[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR

# cached_eval, used by 90-tools.zsh, now lives in shared/lib.sh so bash can
# use it too.

# ---------------------------------------------------------------------------
# compinit, at most one full rebuild per day.
#
# The dump lives in the cache dir rather than $HOME. A full compinit costs
# ~280ms; -C skips the security check and staleness scan and costs ~30ms.
# ---------------------------------------------------------------------------
autoload -Uz compinit

_zcompdump=$ZSH_CACHE_DIR/zcompdump
_zcompdump_stale=($_zcompdump(Nmh+24))
if (( $#_zcompdump_stale )) || [[ ! -s $_zcompdump ]]; then
    compinit -d $_zcompdump
else
    compinit -C -d $_zcompdump
fi
unset _zcompdump _zcompdump_stale

setopt auto_menu
setopt always_to_end
setopt complete_in_word
unsetopt flow_control
unsetopt menu_complete

zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# use-cache needs a cache-path; without one it silently falls back to
# ~/.zcompcache.
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR/zcompcache
