# Prompt.
#
# Three variants, differing only in how loudly they identify the machine:
# root is a warning, SSH needs the hostname, local needs neither. Same as
# zsh's 20-prompt.zsh.
#
#   \[...\]           wrap non-printing bytes, so line wrapping stays correct
#   \e[38;5;Nm        foreground color N
#   \e[4m / \e[1m     underline / bold
#   \h                short hostname        \w  cwd, ~ abbreviated
#   \$                # for root, $ otherwise (zsh's %# uses % instead)
#
# bash has no equivalent of zsh's %(?.A.B), so the exit status is the one part
# that has to be recomputed each prompt; everything else is a static string.

# Sets $__ps_status to a green check or the red exit code.
#
# The escapes here are \001/\002 rather than \[/\], which is not a typo: bash
# translates \[ and \] while expanding PS1 itself, and does not rescan the
# result of a variable it expanded, so \[ inside a variable would be printed
# literally and readline would miscount the prompt width. \001/\002 are the
# bytes \[ and \] translate to, and they survive the round trip.
__ps_status() {
    local status=$?    # MUST be first: anything else overwrites it
    if [ "$status" -eq 0 ]; then
        __ps_status=$'\001\e[32m\002√\001\e[0m\002'
    else
        __ps_status=$'\001\e[38;5;196m\002'$status$'\001\e[0m\002'
    fi
}

# history -a; history -n pairs with histappend (00-options.bash) to approximate
# zsh's share_history: flush this shell's new commands, then read other shells'.
PROMPT_COMMAND='__ps_status; history -a; history -n'

# root
if [ "$EUID" -eq 0 ]; then
    #    | exit code   | hostname                | cwd                       | prompt
    PS1='${__ps_status} \[\e[4;38;5;196m\]\h\[\e[0m\] \[\e[1;38;5;39m\]\w\[\e[0m\] \$ '
# ssh
elif [ -n "$SSH_CONNECTION" ]; then
    PS1='${__ps_status} \[\e[1;38;5;163m\]\h\[\e[0m\] \[\e[1;38;5;39m\]\w\[\e[0m\] \$ '
# local
else
    PS1='${__ps_status} \[\e[1;38;5;39m\]\w\[\e[0m\] \$ '
fi

# zsh truncates the path with %50<...<%~. bash's nearest equivalent trims by
# component rather than by width, and needs bash 4; on 3.2 the path is simply
# shown in full.
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    PROMPT_DIRTRIM=4
fi
