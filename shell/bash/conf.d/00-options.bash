# Shell options and environment.

. "$DOTFILES_SHELL/shared/00-options.sh"

# History cannot be shared with zsh. histappend is half of a pair; see
# 20-prompt.bash.
HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoredups:ignorespace

shopt -s histappend
shopt -s checkwinsize

if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    shopt -s autocd
    shopt -s cdspell
    shopt -s dirspell
    shopt -s globstar
fi
