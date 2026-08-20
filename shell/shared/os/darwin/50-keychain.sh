# _keychain_touched_since <file>
#
# True when any of the user's keychains has been modified more recently than
# <file>. Reads leave the mtime alone; adding or editing an item bumps it. The
# subshell contains zsh's fatal error when a pattern matches nothing, which
# also means a system with no *.keychain-db skips the legacy check below it.
_keychain_touched_since() {
  local ref="$1" kc
  ( for kc in "$HOME"/Library/Keychains/*.keychain-db; do
      [[ -e "$kc" && "$kc" -nt "$ref" ]] && exit 0
    done
    for kc in "$HOME"/Library/Keychains/*.keychain; do
      [[ -e "$kc" && "$kc" -nt "$ref" ]] && exit 0
    done
    exit 1 ) 2>/dev/null
}

# cache_keychain_vars [--hex] <var> <service> [[--hex] <var> <service>]...
#
# --hex applies only to the pair that follows it, for secrets the Keychain
# dumps as hex because they contain non-printable bytes (any multi-line value,
# such as a PEM key). Nothing in the output distinguishes such a dump from a
# secret whose plaintext is hex digits, so the caller has to say which is which.
cache_keychain_vars() {
  local -a specs=()
  local expected_count=0 hex=

  while (( $# )); do
    if [[ "$1" == --hex ]]; then
      hex=1
      shift
      continue
    fi
    if (( $# < 2 )); then
      printf 'cache_keychain_vars: expected <var> <service> pairs\n' >&2
      return 2
    fi
    specs+=("${hex:-0}" "$1" "$2")
    expected_count=$(( expected_count + 1 ))
    hex=
    shift 2
  done

  if [[ -n "$hex" ]]; then
    printf 'cache_keychain_vars: --hex must precede a <var> <service> pair\n' >&2
    return 2
  fi

  (( expected_count )) || return 0

  # Never /tmp: it is world-writable, and this file gets sourced.
  # A stripped environment can lack both of these; caching is then skipped.
  local cache_dir="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)}"
  local cache_id=$(md5 -q -s "${specs[*]}" 2>/dev/null)
  local cache_file=
  if [[ -n "$cache_id" && -d "$cache_dir" ]]; then
    cache_file="${cache_dir%/}/.env_cache_${cache_id}"
  fi

  if [[ -n "$cache_file" && -f "$cache_file" ]]; then
    if _keychain_touched_since "$cache_file"; then
      rm -f "$cache_file"
    else
      source "$cache_file"
      return
    fi
  fi

  # Capture parallel outputs in memory via standard output
  local cache_content
  cache_content=$(
    set -- "${specs[@]}"
    while (( $# >= 3 )); do
      local is_hex="$1" env_var="$2" service="$3"
      shift 3
      (
        local val
        if [[ "$is_hex" == 1 ]]; then
          # The sentinel keeps trailing newlines that $() would strip.
          val=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null \
            | xxd -r -p 2>/dev/null && printf x) || val=
          val="${val%x}"
        else
          val=$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null)
        fi
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
