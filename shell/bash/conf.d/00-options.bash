# Shell options and environment.

. "$DOTFILES_SHELL/shared/00-options.sh"

# History cannot be shared with zsh
# histappend and `history -a; history -n` in PROMPT_COMMAND (20-prompt.bash) work together
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
