# Shell options and environment.

# Environment variables and ls colors, shared with zsh.
. "$DOTFILES_SHELL/shared/00-options.sh"

# ---------------------------------------------------------------------------
# History
#
# Separate from zsh's: the file formats differ, so ~/.zsh_history and
# ~/.bash_history cannot be shared. The settings mirror zsh's intent --
# ignoredups is hist_ignore_dups, ignorespace is hist_ignore_space.
#
# histappend plus `history -a; history -n` in PROMPT_COMMAND (20-prompt.bash)
# is the closest bash gets to zsh's share_history: each prompt flushes new
# commands to the file and reads back anything other shells have added.
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoredups:ignorespace

shopt -s histappend
shopt -s checkwinsize

# ---------------------------------------------------------------------------
# Options that need bash 4. macOS ships 3.2.57 (2007), so these are guarded
# rather than assumed: autocd is zsh's auto_cd, globstar is its ** glob.
# ---------------------------------------------------------------------------
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    shopt -s autocd
    shopt -s cdspell
    shopt -s dirspell
    shopt -s globstar
fi
