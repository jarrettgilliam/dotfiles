# External tool integration.
#
# Every one of these shells out to generate its init script. cached_eval
# (shared/lib.sh) stores the output and regenerates only when the tool's
# binary is newer than the cache, so a normal startup does no forking here.
# Loaded last so these can override anything configured above.

# zoxide, replacing cd with a frecency-ranked version.
cached_eval zoxide zoxide init --cmd cd bash

cached_eval fzf fzf --bash

# The expensive one: hundreds of lines of generated completion.
cached_eval kubectl kubectl completion bash
