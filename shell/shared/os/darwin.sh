# macOS
# Homebrew is deliberately NOT here. 05-environment.sh handles macOS AND Linux.

path_append /usr/local/sbin

cache_keychain_vars() {
  # Never /tmp: it is world-writable, and this file gets sourced.
  # A stripped environment can lack both of these; caching is then skipped.
  local cache_dir="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)}"
  local cache_id=$(md5 -q -s "$*" 2>/dev/null)
  local cache_file=
  if [[ -n "$cache_id" && -d "$cache_dir" ]]; then
    cache_file="${cache_dir%/}/.env_cache_${cache_id}"
  fi

  if [[ -n "$cache_file" && -f "$cache_file" ]]; then
    source "$cache_file"
    return
  fi

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

  # Apply and cache only if all requested keys succeeded
  if (( fetched_count == expected_count )); then
    if [[ -n "$cache_file" ]]; then
      # Scoped so the umask does not leak into the interactive shell.
      ( umask 077; printf '%s\n' "$cache_content" > "$cache_file" )
    fi
    eval "$cache_content"
  fi
}