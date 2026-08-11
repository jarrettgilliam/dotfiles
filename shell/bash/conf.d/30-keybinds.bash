# Key bindings

# macOS / Terminal.app
bind '"\eb": backward-word'
bind '"\ef": forward-word'
bind '"\C-a": beginning-of-line'
bind '"\C-e": end-of-line'

# Windows / Linux console
bind '"\e[1;5C": forward-word'
bind '"\e[1;5D": backward-word'
bind '"\e[H": beginning-of-line'
bind '"\e[F": end-of-line'
bind '"\e[3~": delete-char'

# Up/down search history for what has already been typed. Bash's
# built-in equivalent of the zsh-history-substring-search plugin, except
# readline anchors the match at the start of the line only
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'
