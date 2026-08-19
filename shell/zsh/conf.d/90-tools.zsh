# External tool integration, loaded last so these can override anything above.

cached_eval zoxide zoxide init --cmd cd zsh
cached_eval fzf fzf --zsh
cached_eval kubectl kubectl completion zsh
