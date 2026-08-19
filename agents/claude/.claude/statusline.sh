#!/usr/bin/env bash
#
# Claude Code status line. Receives session JSON on stdin; see
# https://code.claude.com/docs/en/statusline

set -uo pipefail

DIM=$'\033[2m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
CYAN=$'\033[36m'

input="$(cat)"

if ! command -v jq >/dev/null; then
    printf '%s' "${RED}statusline: jq not found${RESET}"
    exit 0
fi

IFS=$'\t' read -r model dir ctx_used ctx_size fh_used fh_reset sd_used cost <<EOF
$(jq -r '[
    .model.display_name,
    .workspace.current_dir,
    (.context_window.used_percentage // -1),
    (.context_window.context_window_size // 0),
    (.rate_limits.five_hour.used_percentage // -1),
    (.rate_limits.five_hour.resets_at // 0),
    (.rate_limits.seven_day.used_percentage // -1),
    (.cost.total_cost_usd // 0)
] | @tsv' <<<"$input")
EOF

round() { printf '%.0f' "$1"; }

usage_color() {
    local used="$1" warn="$2" crit="$3"

    if [ "$used" -le "$warn" ]; then
        printf '%s' "$GREEN"
    elif [ "$used" -le "$crit" ]; then
        printf '%s' "$YELLOW"
    else
        printf '%s' "$RED"
    fi
}

CONTEXT_WARN=30
CONTEXT_CRIT=85
QUOTA_WARN=60
QUOTA_CRIT=85

bar() {
    local used="$1" width=10 filled i out=""
    filled=$(( (used * width + 50) / 100 ))
    for ((i = 0; i < width; i++)); do
        if [ "$i" -lt "$filled" ]; then out+="█"; else out+="░"; fi
    done
    printf '%s' "$out"
}

human_duration() {
    local secs="$1"
    if [ "$secs" -ge 86400 ]; then
        printf '%dd' $(( secs / 86400 ))
    elif [ "$secs" -ge 3600 ]; then
        printf '%dh' $(( secs / 3600 ))
    else
        printf '%dm' $(( secs / 60 ))
    fi
}

segments=()

segments+=("${CYAN}${model}${RESET}")

branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
[ -n "$branch" ] && segments+=("${DIM}${branch}${RESET}")

ctx_used="$(round "$ctx_used")"
if [ "$ctx_used" -ge 0 ]; then
    color="$(usage_color "$ctx_used" "$CONTEXT_WARN" "$CONTEXT_CRIT")"
    label="ctx used"
    [ "$ctx_size" -gt 200000 ] && label="ctx used (1M)"
    segments+=("${color}$(bar "$ctx_used")${RESET} ${ctx_used}% ${DIM}${label}${RESET}")
else
    segments+=("${DIM}$(bar 0) --% ctx used${RESET}")
fi

fh_used="$(round "$fh_used")"
if [ "$fh_used" -ge 0 ]; then
    quota="$(usage_color "$fh_used" "$QUOTA_WARN" "$QUOTA_CRIT")${fh_used}%${RESET}"
    now="$(date +%s)"
    if [ "$fh_reset" -gt "$now" ]; then
        quota+=" ${DIM}5h (resets $(human_duration $(( fh_reset - now ))))${RESET}"
    else
        quota+=" ${DIM}5h${RESET}"
    fi

    sd_used="$(round "$sd_used")"
    if [ "$sd_used" -ge 0 ]; then
        quota+=" ${DIM}|${RESET} $(usage_color "$sd_used" "$QUOTA_WARN" "$QUOTA_CRIT")${sd_used}%${RESET} ${DIM}7d${RESET}"
    fi

    segments+=("$quota")
fi

segments+=("${DIM}\$$(printf '%.2f' "$cost")${RESET}")

printf '%s' "${segments[0]}"
for seg in "${segments[@]:1}"; do
    printf '%s' " ${DIM}·${RESET} $seg"
done
