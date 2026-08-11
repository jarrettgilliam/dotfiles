# Prompt. Three variants: root is a warning, SSH shows the hostname, local needs neither.

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
