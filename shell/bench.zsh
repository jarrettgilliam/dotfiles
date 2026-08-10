#!/usr/bin/env zsh
# Measure zsh startup time, or profile where it goes.
#
#   ./bench.zsh              10 login+interactive runs, min/mean/max
#   ./bench.zsh -n 20        20 runs
#   ./bench.zsh --profile    zprof breakdown of a single startup
#   ./bench.zsh --compare    login+interactive vs interactive vs bare

emulate -L zsh
setopt err_return

typeset -i runs=10
typeset mode=time

while (( $# )); do
    case $1 in
        -n)                runs=$2; shift 2 ;;
        --profile|-p)      mode=profile; shift ;;
        --compare|-c)      mode=compare; shift ;;
        -h|--help)
            print "Usage: bench.zsh [-n RUNS] [--profile] [--compare]"
            return 0 ;;
        *) print -u2 "Unknown option: $1"; return 1 ;;
    esac
done

# Runs a shell N times and reports timings in milliseconds.
_bench() {
    local label=$1; shift
    local -a samples
    local -F start elapsed

    # Warm the filesystem cache so the first run does not skew the minimum.
    "$@" >/dev/null 2>&1

    repeat $runs; do
        start=$EPOCHREALTIME
        "$@" >/dev/null 2>&1
        elapsed=$(( (EPOCHREALTIME - start) * 1000 ))
        samples+=$elapsed
    done

    local -F min=$samples[1] max=$samples[1] total=0
    local -F s
    for s in $samples; do
        (( s < min )) && min=$s
        (( s > max )) && max=$s
        (( total += s ))
    done

    printf "%-28s min %6.0fms   mean %6.0fms   max %6.0fms\n" \
        $label $min $(( total / runs )) $max
}

zmodload zsh/datetime

case $mode in
    time)
        print "Startup time over $runs runs:\n"
        _bench "login + interactive" zsh -i -l -c exit
        ;;

    compare)
        print "Startup time over $runs runs:\n"
        _bench "login + interactive" zsh -i -l -c exit
        _bench "interactive only"    zsh -i -c exit
        _bench "login only"          zsh -l -c exit
        _bench "bare (no rc files)"  zsh -f -c exit
        print "\nlogin+interactive is what a new terminal tab costs."
        ;;

    profile)
        print "Profiling a single interactive startup...\n"
        # zprof must be loaded before the config runs, so inject it via a
        # temporary ZDOTDIR whose .zshrc wraps the real one.
        local real=${ZDOTDIR:-$HOME}
        local tmp=$(mktemp -d)
        {
            # .zshenv must run first: it defines ZSH_CACHE_DIR, without which
            # compinit and cached_eval fall back to unwritable paths and the
            # profile measures a cache miss rather than a normal startup.
            print 'zmodload zsh/zprof'      > $tmp/.zshrc
            print "source $real/.zshenv"   >> $tmp/.zshrc
            print "source $real/.zshrc"    >> $tmp/.zshrc
            print 'zprof'                  >> $tmp/.zshrc
            ZDOTDIR=$tmp zsh -i -c exit
        } always {
            rm -rf $tmp
        }
        ;;
esac
