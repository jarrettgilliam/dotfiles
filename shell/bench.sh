#!/usr/bin/env bash

# Written in bash, but also measures zsh. Keep compatible with bash 3.2.

set -u

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

runs=10
mode=time
want_shell=both

usage() {
    echo "Measure shell startup time, and show where it goes."
    echo ""
    echo "  ./bench.sh                 both shells, 10 runs each"
    echo "  ./bench.sh --shell bash    one shell only (zsh | bash | both)"
    echo "  ./bench.sh -n 20           run count"
    echo "  ./bench.sh --breakdown     per-file cost"
    echo "  ./bench.sh --compare       login+interactive vs interactive vs login vs bare"
    echo "  ./bench.sh --profile       zprof function-level profile, zsh only"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n)                  runs="$2"; shift 2 ;;
        --shell|-s)          want_shell="$2"; shift 2 ;;
        --breakdown|-b)      mode=breakdown; shift ;;
        --compare|-c)        mode=compare; shift ;;
        --profile|-p)        mode=profile; shift ;;
        -h|--help)           usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$want_shell" in
    zsh|bash|both) ;;
    *) echo "--shell must be zsh, bash or both (got: $want_shell)" >&2; exit 2 ;;
esac

case "$runs" in
    ''|*[!0-9]*) echo "-n must be a positive integer (got: $runs)" >&2; exit 2 ;;
esac

# %3R is wall-clock seconds to three decimals: enough for startups in tens of ms
TIMEFORMAT='%3R'

# time_once <command...> -> seconds, as a decimal string
time_once() {
    { time "$@" >/dev/null 2>&1; } 2>&1
}

# time_min <command...> -> milliseconds, minimum across $runs
#
# The minimum, not the mean: least noisy estimate of the real cost, which
# matters for the breakdown, where small differences are subtracted
time_min() {
    local i t best=
    "$@" >/dev/null 2>&1        # warm the filesystem cache
    for (( i = 0; i < runs; i++ )); do
        t=$(time_once "$@")
        best=$(awk -v a="$best" -v b="$t" 'BEGIN { print (a == "" || b < a) ? b : a }')
    done
    awk -v s="$best" 'BEGIN { printf "%.0f", s * 1000 }'
}

# report <label> <command...>  -- min/mean/max over $runs
report() {
    local label="$1"; shift
    local i t all=

    "$@" >/dev/null 2>&1        # warm the filesystem cache
    for (( i = 0; i < runs; i++ )); do
        t=$(time_once "$@")
        all="$all $t"
    done

    echo "$all" | awk -v label="$label" '{
        min = max = $1; total = 0
        for (i = 1; i <= NF; i++) {
            if ($i < min) min = $i
            if ($i > max) max = $i
            total += $i
        }
        printf "  %-26s min %5.0fms   mean %5.0fms   max %5.0fms\n",
            label, min * 1000, (total / NF) * 1000, max * 1000
    }'
}

have() { command -v "$1" >/dev/null 2>&1; }

# shells_to_test -> the requested shells that are installed
shells_to_test() {
    local sh
    for sh in zsh bash; do
        case "$want_shell" in
            both|"$sh") ;;
            *) continue ;;
        esac
        if have "$sh"; then
            echo "$sh"
        else
            echo "  (skipping $sh: not installed)" >&2
        fi
    done
}

# start_cmd <shell> <variant>
start_cmd() {
    case "$1:$2" in
        zsh:full)         echo "zsh -i -l -c exit" ;;
        zsh:interactive)  echo "zsh -i -c exit" ;;
        zsh:login)        echo "zsh -l -c exit" ;;
        zsh:bare)         echo "zsh -f -c exit" ;;
        bash:full)        echo "bash -i -l -c exit" ;;
        bash:interactive) echo "bash -i -c exit" ;;
        bash:login)       echo "bash -l -c exit" ;;
        bash:bare)        echo "bash --norc --noprofile -c exit" ;;
    esac
}

# ---------------------------------------------------------------------------
# Breakdown by cumulative ablation.
#
# Time a shell that loads only the first file of conf.d, then the first two,
# and so on; each file's cost is the difference between consecutive totals.
# That needs no in-shell clock, so it works identically in zsh and in every
# bash version, and it charges each file for its side effects -- compinit's
# cost lands on 10-completion, where it belongs.
#
# The per-file numbers will not sum to the totals reported by the default
# mode: the baseline below covers the shell's own startup plus lib.sh, and
# /etc files are outside this config entirely. The baseline is printed so the
# gap is visible rather than mysterious.
# ---------------------------------------------------------------------------
breakdown() {
    local shell="$1"
    local confd ext
    case "$shell" in
        zsh)  confd="$SOURCE_DIR/zsh/conf.d";  ext=zsh ;;
        bash) confd="$SOURCE_DIR/bash/conf.d"; ext=bash ;;
    esac

    local files file
    files=$(ls "$confd"/*."$ext" 2>/dev/null) || return 0
    [ -n "$files" ] || return 0

    local tmp
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT INT TERM

    echo ""
    echo "$shell: cost per conf.d file"
    echo ""

    local k=0 prev base
    prev=$(ablation_time "$shell" "$tmp" 0 "")
    base=$prev
    printf "  %-26s %5sms   (shell startup + lib.sh)\n" "baseline" "$base"

    local loaded=
    for file in $files; do
        k=$((k + 1))
        loaded="$loaded $file"
        local now cost
        now=$(ablation_time "$shell" "$tmp" "$k" "$loaded")
        # Clamp: a cheap file can measure a few tenths negative from noise.
        cost=$(awk -v a="$prev" -v b="$now" 'BEGIN { d = b - a; print (d < 0) ? 0 : d }')
        printf "  %-26s %5.0fms\n" "$(basename "$file" ".$ext")" "$cost"
        prev=$now
    done

    echo "  ------------------------------------"
    printf "  %-26s %5sms\n" "measured total" "$prev"

    rm -rf "$tmp"
    trap - EXIT INT TERM
}

# ablation_time <shell> <tmpdir> <k> <files>  -> milliseconds
#
# The scaffolding mirrors what each shell really does, which is what makes the
# numbers comparable to a normal startup.
ablation_time() {
    local shell="$1" tmp="$2" k="$3" files="$4"
    local rc file

    if [ "$shell" = zsh ]; then
        rc="$tmp/z$k"
        mkdir -p "$rc"

        # The real .zshenv has to run in its normal slot, not from .zshrc.
        # Setting ZDOTDIR in the environment makes zsh read $ZDOTDIR/.zshenv
        # instead of ~/.zshenv, so without this the real one never runs:
        # ZSH_CACHE_DIR is unset, and -- the expensive part -- macOS's
        # /etc/zshrc_Apple_Terminal does not see SHELL_SESSIONS_DISABLE and
        # starts its session save/restore.
        #
        # It sets ZDOTDIR to the real directory, so point it back here
        # afterwards or zsh would read the real .zshrc next and load the whole
        # config regardless of which files this run is meant to include.
        {
            echo "source '$SOURCE_DIR/zsh/.zshenv'"
            echo "ZDOTDIR='$rc'"
        } > "$rc/.zshenv"

        {
            # conf.d files refer to $ZDOTDIR; give them the real one.
            echo "ZDOTDIR='$SOURCE_DIR/zsh'"
            echo "source '$SOURCE_DIR/shared/lib.sh'"
            for file in $files; do echo "source '$file'"; done
        } > "$rc/.zshrc"
        ZDOTDIR="$rc" time_min zsh -i -c exit
    else
        # Stands in for the readlink self-location in bash/.bashrc.
        rc="$tmp/b$k.bash"
        {
            echo "DOTFILES_SHELL='$SOURCE_DIR'"
            echo ': "${XDG_CACHE_HOME:=$HOME/.cache}"'
            echo 'DOTFILES_CACHE_DIR="$XDG_CACHE_HOME/bash"'
            echo "source '$SOURCE_DIR/shared/lib.sh'"
            for file in $files; do echo "source '$file'"; done
        } > "$rc"
        time_min bash --rcfile "$rc" -i -c exit
    fi
}

case "$mode" in
    time)
        echo "Startup time over $runs runs:"
        echo ""
        for sh in $(shells_to_test); do
            report "$sh  login + interactive" $(start_cmd "$sh" full)
        done
        ;;

    compare)
        echo "Startup time over $runs runs:"
        for sh in $(shells_to_test); do
            echo ""
            report "$sh  login + interactive" $(start_cmd "$sh" full)
            report "$sh  interactive only"    $(start_cmd "$sh" interactive)
            report "$sh  login only"          $(start_cmd "$sh" login)
            report "$sh  bare (no rc files)"  $(start_cmd "$sh" bare)
        done
        echo ""
        echo "login+interactive is what a new terminal tab costs."
        ;;

    breakdown)
        echo "Per-file cost, minimum of $runs runs each."
        for sh in $(shells_to_test); do
            breakdown "$sh"
        done
        ;;

    profile)
        case "$want_shell" in
            bash)
                echo "--profile is zsh only." >&2
                echo "bash has no zprof; the equivalent needs BASH_XTRACEFD, which" >&2
                echo "macOS's bash 3.2 does not have. Use --breakdown instead." >&2
                exit 2 ;;
        esac
        have zsh || { echo "zsh is not installed." >&2; exit 2; }

        echo "Profiling a single interactive zsh startup..."
        echo ""
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT INT TERM

        # Same two-step as the breakdown: the real .zshenv must run in its own
        # slot so /etc/zshrc sees SHELL_SESSIONS_DISABLE, then ZDOTDIR points
        # back here so zsh reads the wrapper below rather than the real .zshrc.
        {
            echo "source '$SOURCE_DIR/zsh/.zshenv'"
            echo "ZDOTDIR='$tmp'"
        } > "$tmp/.zshenv"

        {
            echo 'zmodload zsh/zprof'
            echo "ZDOTDIR='$SOURCE_DIR/zsh'"
            echo "source '$SOURCE_DIR/zsh/.zshrc'"
            echo 'zprof'
        } > "$tmp/.zshrc"
        ZDOTDIR="$tmp" zsh -i -c exit
        rm -rf "$tmp"
        trap - EXIT INT TERM
        ;;
esac
