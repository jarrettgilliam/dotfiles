# Interactive shell configuration.
#
# Everything lives in conf.d/, loaded in filename order. The numeric prefixes
# exist to make dependencies explicit:
#
#   00  options       nothing depends on it, it depends on nothing
#   05  environment   secrets, PATH, brew, nvm, os/ + hosts/. Needs 00's
#                     LS_COLORS; provides HOMEBREW_PREFIX to 10.
#   10  completion    must finish assembling fpath before compinit runs
#   20  prompt
#   30  keybinds      before plugins, so plugins can override bindings
#   40  plugins       needs fpath (10) in place
#   41  vcs-prompt    needs zsh-async from 40
#   50  aliases
#   90  tools         external inits last, so they can override anything above
#
# See README.md before adding a file.

for _rc in $ZDOTDIR/conf.d/*.zsh(N); do
    source $_rc
done
unset _rc
