# Aliases and functions shared by both shells.

for _fn in "$DOTFILES_SHELL"/shared/functions/*.sh; do
    [ -r "$_fn" ] && . "$_fn"
done
unset _fn

# Colors come from 00-options.sh
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

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias chx='chmod +x'
alias c='clear'
alias grep='grep --color=auto'

alias less='less -R'
alias more='more -R'

alias u='sudo du -sh *'
alias us='sudo du -sh * | sort -hr'
alias asuser='sudo -iHu'

if has_command tmux; then
    alias tmuxa='tmux a -d 2>/dev/null || tmux'
fi

if has_command rsync; then
    alias rsync-cp='sudo rsync --delete -avhHAX --info=progress2'
    alias rsync-mrg='sudo rsync -avhHAX --info=progress2'
fi

if has_command git; then
    alias gst='git status'
    alias gdf='git diff'
    alias gdfs='git diff --staged'
    alias gcm='git commit'
    alias gbr='git branch'
    alias gcb='git checkout -b'
    alias gl='git log'
    alias gpl='git pull -p'
fi

if has_command npx; then
    alias nx='npx nx'
fi
