# Archive a path as <name>.tar.gz in the current directory.
agz() {
    apack -F tar.gz "$(basename "$1")".tar.gz "$1"
}
