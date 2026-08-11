# Key bindings. Both sets are bound unconditionally: the sequences do not
# collide, and binding one the local terminal never emits is harmless

# macOS / Terminal.app
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^A'  beginning-of-line
bindkey '^E'  end-of-line

# Windows / Linux console
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[3~'   delete-char
