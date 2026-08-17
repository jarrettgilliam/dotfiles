# macOS
# Homebrew is deliberately NOT here. 05-environment.sh handles macOS AND Linux.

path_append /usr/local/sbin

cache_keychain_vars() {
  local cache_id=$(md5 -q -s "$*")
  local cache_file="/tmp/.env_cache_${USER}_${cache_id}"

  if [[ ! -f "$cache_file" ]]; then
    local expected_count=$(( $# / 2 ))

    # Capture parallel outputs in memory via standard output
    local cache_content
    cache_content=$(
      while (( $# >= 2 )); do
        local env_var="$1" service="$2"
        shift 2
        (
          local val=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)
          if [[ -n "$val" ]]; then
            printf 'export %s=%q\n' "$env_var" "$val"
          fi
        ) &
      done
      wait
    )

    # Count retrieved variables to ensure no Keychain lookup failed
    local fetched_count=0
    [[ -n "$cache_content" ]] && fetched_count=$(printf '%s\n' "$cache_content" | grep -c '^export ')

    # Write cache file only if all requested keys succeeded
    if (( fetched_count == expected_count )); then
      printf '%s\n' "$cache_content" > "$cache_file"
      chmod 600 "$cache_file"
    fi
  fi

  [[ -f "$cache_file" ]] && source "$cache_file"
}