# Aliases and functions shared by both shells.
#
# Guards use has_command (lib.sh), which covers external commands, functions
# and aliases alike -- so the lazy nvm stubs from 05-environment.sh count.

# ---------------------------------------------------------------------------
# Functions, one definition per file.
#
# These used to be zsh autoload bodies, loaded on first call. They are plain
# definitions now so bash can use them too; defining nine functions costs
# microseconds, which is why the laziness was never worth much.
# ---------------------------------------------------------------------------
for _fn in "$DOTFILES_SHELL"/shared/functions/*.sh; do
    [ -r "$_fn" ] && . "$_fn"
done
unset _fn

# ---------------------------------------------------------------------------
# ls
#
# --color=auto, not bare --color: the bare form means "always", which emits
# escape codes into pipes (`ls | cat`). macOS's BSD ls has accepted both
# spellings for several releases now, so this needs no OS branching. The
# color variables themselves live in 00-options.sh, all three together.
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

# npx may be a real binary or the lazy nvm stub from 05-environment.sh;
# has_command matches either.
if has_command npx; then
    alias nx='npx nx'
fi

# Anything that only makes sense on one OS lives in shared/os/, and anything
# specific to one box in shared/hosts/. Both are sourced by 05-environment.sh.
