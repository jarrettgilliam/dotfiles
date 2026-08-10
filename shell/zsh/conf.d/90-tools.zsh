# External tool integration.
#
# Every one of these shells out to generate its init script. cached_eval
# (10-completion.zsh) stores the output and regenerates only when the tool's
# binary is newer than the cache, so a normal startup does no forking here.
# Loaded last so these can override anything configured above.

# zoxide, replacing cd with a frecency-ranked version. It preserves normal cd
# semantics, so auto_cd and auto_pushd (00-options.zsh) still behave.
cached_eval zoxide zoxide init --cmd cd zsh

cached_eval fzf fzf --zsh

# The expensive one: ~230 lines of generated completion, previously
# regenerated on every single startup.
cached_eval kubectl kubectl completion zsh
