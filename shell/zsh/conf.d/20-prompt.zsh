# Prompt.
#
# Three variants, differing only in how loudly they identify the machine:
# root is a warning, SSH needs the hostname, local needs neither.
#
#   %(?.A.B)          A if last exit status was 0, else B
#   %F{n}...%f        foreground colour n
#   %U...%u           underline
#   %B...%b           bold
#   %50<...<%~%<<     cwd, truncated to 50 chars with a leading ellipsis

# root
if [[ $EUID -eq 0 ]]; then
    #      | exit code                  | hostname       | cwd                      | prompt
    PROMPT='%(?.%F{green}√%f.%F{196}%?%f) %U%F{196}%m%u%f %B%F{39}%50<...<%~%<<%b%f %# '
# ssh
elif [[ -n $SSH_CONNECTION ]]; then
    PROMPT='%(?.%F{green}√%f.%F{196}%?%f) %B%F{163}%m%b%f %B%F{39}%50<...<%~%<<%b%f %# '
# local
else
    PROMPT='%(?.%F{green}√%f.%F{196}%?%f) %B%F{39}%50<...<%~%<<%b%f %# '
fi
