#!/usr/bin/env bash
#
# agentpub.sh — reference helper for agentpub publishing.
#
# Encodes the SAFE PATH so anonymous publishing is never an accident:
#   - resolves a key (AGENTPUB_API_KEY env, then ~/.config/agentpub/credentials)
#   - publishes OWNED by default whenever a key exists
#   - honors AGENTPUB_REQUIRE_AUTH=1 (hard-fail instead of falling back to anon)
#   - prints the ownership state (authenticated / anonymous / expiresAt) loudly
#
# Commands:
#   agentpub.sh login [email]            acquire + persist a key (0600), name it
#   agentpub.sh pair [name] [--json]     pair a device: human approves in browser,
#                                        key delivered out-of-band (no code/key in chat)
#   agentpub.sh publish <dir> [--anonymous]   publish a directory (owned by default)
#   agentpub.sh sites                    list your sites (requires a key)
#   agentpub.sh whoami                   show how a key resolves (no secrets printed)
#
# Requires: bash, curl, jq. Copy this file out of the skill and run it directly.
# The API key is written only to the 0600 credential file or read from env —
# never echoed, logged, or committed.

set -euo pipefail

BASE="${AGENTPUB_BASE:-https://agentpub.io}"
CRED_FILE="${AGENTPUB_CREDENTIALS:-$HOME/.config/agentpub/credentials}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

# Resolve an API key: env var first, then the 0600 credential file. Echoes the
# key on stdout for capture in a subshell ONLY; never logged by this script.
resolve_key() {
  if [ -n "${AGENTPUB_API_KEY:-}" ]; then
    printf '%s' "$AGENTPUB_API_KEY"; return 0
  fi
  if [ -f "$CRED_FILE" ]; then
    # First non-empty line of the credential file.
    awk 'NF {print; exit}' "$CRED_FILE"; return 0
  fi
  return 1
}

# Persist a key to the credential file with strict permissions.
save_key() {
  local key="$1" dir
  dir="$(dirname "$CRED_FILE")"
  mkdir -p "$dir"
  ( umask 177; printf '%s\n' "$key" > "$CRED_FILE" )
  chmod 600 "$CRED_FILE"
}

# Guess a content-type from a file extension; default to octet-stream.
content_type_for() {
  case "${1##*.}" in
    html|htm) printf 'text/html' ;;
    css)      printf 'text/css' ;;
    js|mjs)   printf 'application/javascript' ;;
    json)     printf 'application/json' ;;
    svg)      printf 'image/svg+xml' ;;
    png)      printf 'image/png' ;;
    jpg|jpeg) printf 'image/jpeg' ;;
    gif)      printf 'image/gif' ;;
    webp)     printf 'image/webp' ;;
    ico)      printf 'image/x-icon' ;;
    pdf)      printf 'application/pdf' ;;
    txt|md)   printf 'text/plain' ;;
    woff2)    printf 'font/woff2' ;;
    *)        printf 'application/octet-stream' ;;
  esac
}

cmd_login() {
  need curl; need jq
  local email="${1:-}"
  if [ -z "$email" ]; then
    printf 'Email for your agentpub account: ' >&2
    read -r email
  fi
  [ -n "$email" ] || die "an email is required"

  curl -fsS -X POST "$BASE/api/auth/agent/request-code" \
    -H 'content-type: application/json' \
    -d "$(jq -nc --arg e "$email" '{email:$e}')" >/dev/null \
    || die "request-code failed"
  printf 'A 6-digit code was emailed to %s. Enter it: ' "$email" >&2
  local code; read -r code
  [ -n "$code" ] || die "a code is required"

  local resp apikey created
  resp="$(curl -fsS -X POST "$BASE/api/auth/agent/verify-code" \
    -H 'content-type: application/json' \
    -d "$(jq -nc --arg e "$email" --arg c "$code" '{email:$e,code:$c}')")" \
    || die "verify-code failed (bad or expired code?)"
  apikey="$(printf '%s' "$resp" | jq -r '.apiKey // empty')"
  created="$(printf '%s' "$resp" | jq -r '.accountCreated // false')"
  [ -n "$apikey" ] || die "no apiKey in verify-code response"

  save_key "$apikey"
  # Name this key for the tool holding it (best-effort; ignore failure).
  curl -fsS -X POST "$BASE/api/v1/keys" \
    -H "authorization: Bearer $apikey" \
    -H 'content-type: application/json' \
    -d "$(jq -nc --arg n "${AGENTPUB_KEY_NAME:-agentpub.sh}" '{name:$n}')" >/dev/null 2>&1 || true

  printf 'Signed in (account %s). Key saved to %s (mode 600).\n' \
    "$([ "$created" = "true" ] && echo created || echo existing)" "$CRED_FILE" >&2
}

# Pair a device: the human approves in their browser and the minted key is
# delivered out-of-band on poll — neither the userCode nor the key passes
# through chat. The deviceSecret is held only here. --json emits the start
# fields and each poll status as JSON lines; default is pretty text on stderr.
cmd_pair() {
  need curl; need jq
  local name="" json=0
  for arg in "$@"; do
    case "$arg" in
      --json) json=1 ;;
      -*)     die "unknown flag: $arg" ;;
      *)      name="$arg" ;;
    esac
  done
  [ -n "$name" ] || name="${AGENTPUB_KEY_NAME:-}"

  local start_body='{}'
  [ -n "$name" ] && start_body="$(jq -nc --arg n "$name" '{name:$n}')"

  local start
  start="$(curl -fsS -X POST "$BASE/api/v1/pair/start" \
    -H 'content-type: application/json' -d "$start_body")" \
    || die "pair/start failed"

  local pairing_id device_secret user_code verify_url interval expires
  pairing_id="$(jq -r '.pairingId' <<<"$start")"
  device_secret="$(jq -r '.deviceSecret' <<<"$start")"
  user_code="$(jq -r '.userCode' <<<"$start")"
  verify_url="$(jq -r '.verificationUrlComplete' <<<"$start")"
  interval="$(jq -r '.pollIntervalSeconds' <<<"$start")"
  expires="$(jq -r '.expiresInSeconds' <<<"$start")"
  [ -n "$pairing_id" ] && [ "$pairing_id" != "null" ] || die "no pairingId in pair/start response"

  if [ "$json" -eq 1 ]; then
    jq -nc --arg u "$verify_url" --arg c "$user_code" --argjson i "$interval" --argjson e "$expires" \
      '{event:"start",verificationUrlComplete:$u,userCode:$c,pollIntervalSeconds:$i,expiresInSeconds:$e}'
  else
    printf 'Open this URL to approve; waiting…\n' >&2
    printf '  URL:  %s\n' "$verify_url" >&2
    printf '  code: %s\n' "$user_code" >&2
  fi

  local poll_body deadline now status apikey key_id key_name
  poll_body="$(jq -nc --arg p "$pairing_id" --arg s "$device_secret" '{pairingId:$p,deviceSecret:$s}')"
  now="$(date +%s)"
  deadline=$((now + expires))

  while :; do
    sleep "$interval"
    now="$(date +%s)"
    [ "$now" -lt "$deadline" ] || die "pairing timed out"

    # ONE request per iteration capturing body + status (mint-on-poll is
    # single-use: a separate status-probe request would consume the approval and
    # discard the one-time key). Status code is appended on a final line.
    local resp http body
    resp="$(curl -sS -w $'\n%{http_code}' -X POST "$BASE/api/v1/pair/poll" \
      -H 'content-type: application/json' -d "$poll_body")" || die "pair/poll request failed"
    http="${resp##*$'\n'}"
    body="${resp%$'\n'*}"
    if [ "$http" = "429" ]; then
      # slow_down — back off an extra interval and continue.
      sleep "$interval"
      continue
    fi
    [ "$http" = "200" ] || die "pair/poll failed (HTTP $http)"

    status="$(jq -r '.status' <<<"$body")"
    if [ "$json" -eq 1 ]; then
      jq -nc --arg s "$status" '{event:"poll",status:$s}'
    fi
    case "$status" in
      pending)  [ "$json" -eq 1 ] || printf '.' >&2 ;;
      approved)
        apikey="$(jq -r '.apiKey // empty' <<<"$body")"
        key_id="$(jq -r '.keyId // empty' <<<"$body")"
        key_name="$(jq -r '.keyName // empty' <<<"$body")"
        [ -n "$apikey" ] || die "approved but no apiKey in poll response"
        # Persist BEFORE printing success so a crash never loses the one-time key.
        save_key "$apikey"
        if [ "$json" -eq 1 ]; then
          jq -nc --arg i "$key_id" --arg n "$key_name" --arg f "$CRED_FILE" \
            '{event:"approved",keyId:$i,keyName:$n,credentials:$f}'
        else
          printf '\nPaired. Key saved to %s (mode 600).\n' "$CRED_FILE" >&2
          printf '  keyName: %s\n' "${key_name:-"(unnamed)"}" >&2
          printf '  keyId:   %s\n' "$key_id" >&2
        fi
        break ;;
      denied)   die "pairing denied" ;;
      expired)  die "pairing expired" ;;
      consumed) die "pairing already used" ;;
      *)        die "unexpected pairing status: $status" ;;
    esac
  done
}

# Build the files[] manifest JSON for a directory: path, size, contentType, hash.
build_manifest() {
  local dir="$1" f rel
  local entries='[]'
  while IFS= read -r f; do
    rel="${f#"$dir"/}"
    local size hash ct
    size="$(wc -c < "$f" | tr -d ' ')"
    hash="$(shasum -a 256 "$f" | awk '{print $1}')"
    ct="$(content_type_for "$f")"
    entries="$(jq -c \
      --arg p "$rel" --argjson s "$size" --arg c "$ct" --arg h "$hash" \
      '. + [{path:$p,size:$s,contentType:$c,hash:$h}]' <<<"$entries")"
  done < <(find "$dir" -type f ! -name '.*')
  printf '%s' "$entries"
}

cmd_publish() {
  need curl; need jq; need shasum
  local dir="" anonymous=0
  for arg in "$@"; do
    case "$arg" in
      --anonymous) anonymous=1 ;;
      --owned)     anonymous=0 ;;
      -*)          die "unknown flag: $arg" ;;
      *)           dir="$arg" ;;
    esac
  done
  [ -n "$dir" ] || die "usage: agentpub.sh publish <dir> [--anonymous]"
  [ -d "$dir" ] || die "not a directory: $dir"
  dir="${dir%/}"

  local key=""; key="$(resolve_key)" || true
  local require_auth="${AGENTPUB_REQUIRE_AUTH:-0}"

  # Safe path is automatic: anonymous is an EXPLICIT choice, never a silent
  # fallback. Bare `publish <dir>` publishes owned, or hard-stops if no key.
  if [ "$anonymous" -eq 1 ]; then
    [ "$require_auth" = "1" ] && \
      die "AGENTPUB_REQUIRE_AUTH=1 forbids anonymous publishing (even with --anonymous)"
  elif [ -z "$key" ]; then
    die "no key resolved — run 'agentpub.sh login' to publish an owned site, or pass --anonymous for a throwaway 24h site"
  fi

  local manifest auth_args=()
  manifest="$(build_manifest "$dir")"
  [ "$(jq 'length' <<<"$manifest")" -gt 0 ] || die "no files found under $dir"
  if [ "$anonymous" -eq 0 ]; then auth_args=(-H "authorization: Bearer $key"); fi

  local create
  create="$(curl -fsS -X POST "$BASE/api/v1/publish" \
    ${auth_args[@]+"${auth_args[@]}"} -H 'content-type: application/json' \
    -d "$(jq -nc --argjson f "$manifest" '{files:$f}')")" \
    || die "create failed"

  local version_id finalize_url
  version_id="$(jq -r '.upload.versionId' <<<"$create")"
  finalize_url="$(jq -r '.upload.finalizeUrl' <<<"$create")"

  # Upload each presigned file.
  local n i path url ct
  n="$(jq '.upload.uploads | length' <<<"$create")"
  for ((i = 0; i < n; i++)); do
    path="$(jq -r ".upload.uploads[$i].path" <<<"$create")"
    url="$(jq -r ".upload.uploads[$i].url" <<<"$create")"
    ct="$(content_type_for "$path")"
    curl -fsS -X PUT "$url" -H "content-type: $ct" \
      --data-binary "@$dir/$path" >/dev/null || die "upload failed for $path"
  done

  curl -fsS -X POST "$finalize_url" -H 'content-type: application/json' \
    -d "$(jq -nc --arg v "$version_id" '{versionId:$v}')" >/dev/null \
    || die "finalize failed (a declared file may not have uploaded)"

  # Surface ownership state loudly.
  printf 'siteUrl:       %s\n' "$(jq -r '.siteUrl' <<<"$create")"
  printf 'authenticated: %s\n' "$(jq -r '.authenticated' <<<"$create")"
  printf 'anonymous:     %s\n' "$(jq -r '.anonymous' <<<"$create")"
  printf 'expiresAt:     %s\n' "$(jq -r '.expiresAt // "null"' <<<"$create")"
  local claim_url; claim_url="$(jq -r '.claimUrl // empty' <<<"$create")"
  if [ -n "$claim_url" ]; then
    printf 'claimUrl:      %s\n' "$claim_url"
    printf '>> Anonymous 24h site. Share or open claimUrl now to keep it — it is shown only once.\n' >&2
  fi
}

cmd_sites() {
  need curl; need jq
  local key=""; key="$(resolve_key)" || die "no key resolved — run 'agentpub.sh login'"
  curl -fsS "$BASE/api/v1/sites" -H "authorization: Bearer $key" \
    | jq -r '.sites[]? | "\(.slug)\t\(.siteUrl)"'
}

cmd_whoami() {
  if [ -n "${AGENTPUB_API_KEY:-}" ]; then
    printf 'key source: AGENTPUB_API_KEY env var\n'
  elif [ -f "$CRED_FILE" ]; then
    printf 'key source: %s\n' "$CRED_FILE"
  else
    printf 'no key resolved — run "agentpub.sh login"\n'
  fi
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    login)   cmd_login "$@" ;;
    pair)    cmd_pair "$@" ;;
    publish) cmd_publish "$@" ;;
    sites)   cmd_sites "$@" ;;
    whoami)  cmd_whoami "$@" ;;
    ""|-h|--help)
      sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) die "unknown command: $cmd (try --help)" ;;
  esac
}

main "$@"
