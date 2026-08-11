# Prompt. Three variants: root is a warning, SSH shows the hostname, local needs neither.

# The exit status is the one part that has to be recomputed each prompt;
# everything else below is a static string.
__ps_status() {
    local status=$?    # MUST be first: anything else overwrites it
    if [ "$status" -eq 0 ]; then
        __ps_status=$'\001\e[32m\002√\001\e[0m\002'
    else
        __ps_status=$'\001\e[38;5;196m\002'$status$'\001\e[0m\002'
    fi
}

# history -a; history -n is the other half of histappend (00-options.bash):
# flush this shell's new commands, then read what other shells have added.
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

if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    PROMPT_DIRTRIM=4
fi
