# Key bindings.
#
# The same set as zsh's 30-keybinds.zsh, in readline syntax. Both groups are
# bound unconditionally: the escape sequences do not collide, and binding a
# sequence the local terminal never emits is harmless. That is cheaper than
# detecting the terminal, and it means one config works over SSH from any of
# these machines to any other.

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

# ---------------------------------------------------------------------------
# Up/down search history for what has already been typed, rather than walking
# it blindly. This is bash's built-in equivalent of the
# zsh-history-substring-search plugin, with one difference worth knowing:
# readline anchors the match at the start of the line, while the zsh plugin
# matches a substring anywhere in it.
# ---------------------------------------------------------------------------
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'
