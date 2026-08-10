# Aliases and function registration.
#
# Guards use (( $+commands[x] )), which is a hash lookup rather than the
# subprocess-and-pipe that `which x >/dev/null` used to cost.

# ---------------------------------------------------------------------------
# Functions, autoloaded from functions/. Bodies are not read until first call.
# ---------------------------------------------------------------------------
autoload -Uz mkcd mvcd cpcd h psg le mvln agz azip

# zmv, for bulk renames: mmv '*.txt' '*.md'
autoload -Uz zmv
alias mmv='noglob zmv -W'

# ---------------------------------------------------------------------------
# ls
#
# --color=auto, not bare --color: the bare form means "always", which emits
# escape codes into pipes (`ls | cat`). macOS's BSD ls has accepted both
# spellings for several releases now, so this needs no OS branching. The
# color variables themselves live in 00-options.zsh, all three together.
# ---------------------------------------------------------------------------
alias ls='ls -CF --color=auto'

alias l='ls'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -al'
alias llh='ls -lh'
alias llah='ls -alh'

alias cl='clear && ls'
alias cll='clear && ls -l'
alias cla='clear && ls -a'
alias clla='clear && ls -al'
alias cllh='clear && ls -lh'
alias cllah='clear && ls -alh'

# cd
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias chx='chmod +x'
alias c='clear'
alias grep='grep --color=auto'

# Pass color through the pager rather than showing escape codes.
alias less='less -R'
alias more='more -R'

alias u='sudo du -sh *'
alias us='sudo du -sh * | sort -hr'
alias asuser='sudo -iHu'

if (( $+commands[tmux] )); then
    alias tmuxa='tmux a -d 2>/dev/null || tmux'
fi

if (( $+commands[rsync] )); then
    alias rsync-cp='sudo rsync --delete -avhHAX --info=progress2'
    alias rsync-mrg='sudo rsync -avhHAX --info=progress2'
fi

if (( $+commands[git] )); then
    alias gst='git status'
    alias gdf='git diff'
    alias gdfs='git diff --staged'
    alias gcm='git commit'
    alias gbr='git branch'
    alias gcb='git checkout -b'
    alias gl='git log'
    alias gpl='git pull -p'
fi

# npx may be a real binary or the lazy nvm stub from .zprofile, so check both.
if (( $+commands[npx] || $+functions[npx] )); then
    alias nx='npx nx'
fi

# Anything that only makes sense on one OS lives in os/, and anything specific
# to one box in hosts/. Both are sourced by 05-environment.zsh.
