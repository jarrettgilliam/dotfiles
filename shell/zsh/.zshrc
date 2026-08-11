# Interactive shell configuration. Everything lives in conf.d/, loaded in filename order.

source $DOTFILES_SHELL/shared/lib.sh

for _rc in $ZDOTDIR/conf.d/*.zsh(N); do
    source $_rc
done
unset _rc
