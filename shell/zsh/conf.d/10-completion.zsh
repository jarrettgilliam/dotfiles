# Completion system.

# ORDER MATTERS: fpath must be fully assembled before compinit runs.

typeset -U fpath

fpath=($ZDOTDIR/functions $fpath)

# Homebrew's site-functions. `brew shellenv` adds this itself, but
# 05-environment.sh skips that eval when HOMEBREW_PREFIX is already set, so a
# nested shell never sees it. typeset -U collapses the duplicate otherwise
if [[ -n $HOMEBREW_PREFIX && -d $HOMEBREW_PREFIX/share/zsh/site-functions ]]; then
    fpath=($HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
fi

[[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR

# compinit, cached and rebuilt at most once per day. A full compinit is expensive.
# -C skips the security check and staleness scan for a 10x speedup
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

# use-cache needs a cache-path, or it silently falls back to ~/.zcompcache
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR/zcompcache
