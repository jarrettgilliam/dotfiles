# Grep the process list.
psg() {
    ps aux | grep -E "$1"
}
