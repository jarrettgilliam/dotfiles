# Completion. Sourced if present, silently skipped otherwise

for _bc in \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/etc/profile.d/bash_completion.sh" \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion
do
    if [ -r "$_bc" ]; then
        . "$_bc"
        break
    fi
done
unset _bc
