# bitwarden.sh — direnv helpers to export Bitwarden logins as environment variables.
#
# Usage in an .envrc:
#
#   bw_export \
#       "GITHUB_TOKEN          = password : GitHub PAT" \
#       "AWS_ACCESS_KEY_ID     = username : deploy key @ Work" \
#       "AWS_SECRET_ACCESS_KEY = password : deploy key @ Work"
#
# Mapping syntax, one string per credential:
#
#   VARNAME = field : item search [@ folder]
#            └ field is `username` or `password` (aliases: `user`, `pass`)
#            └ "item search" is passed to Bitwarden's own search (name/notes/uri)
#            └ optional "@ folder" restricts the search to a Bitwarden folder
#
# When several items match a search, the one whose name matches exactly
# (case-insensitively) wins; otherwise the first hit is used and a note is
# logged. The vault must already be unlocked — export BW_SESSION beforehand,
# e.g. `export BW_SESSION=$(bw unlock --raw)`.
#
# bw_export_dryrun takes the same mappings but prints "VAR=value" (secrets
# included) to stdout instead of exporting, to preview what bw_export would set.

# direnv defines log_status/log_error before sourcing this file. Provide fallbacks
# for when it is sourced directly in a shell (e.g. to run bw_export_dryrun by hand).
# That leaks these two names into the interactive shell, which is fine: this path is
# only for manual debugging, and direnv itself runs in its own bash so never sees them.
command -v log_status >/dev/null 2>&1 || log_status() { printf '%s\n' "$*" >&2; }
command -v log_error  >/dev/null 2>&1 || log_error()  { printf '%s\n' "$*" >&2; }

_bw_trim() {
    local v="$*"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    printf '%s' "$v"
}

_bw_require() {
    local vault_status
    command -v bw >/dev/null 2>&1 || { log_error "bitwarden: Bitwarden CLI (bw) not found in PATH"; return 1; }
    command -v jq >/dev/null 2>&1 || { log_error "bitwarden: jq not found in PATH"; return 1; }
    vault_status=$(bw status 2>/dev/null | jq -r '.status // "unknown"')
    if [[ "$vault_status" != "unlocked" ]]; then
        log_error "bitwarden: Bitwarden vault is '$vault_status'. Run: export BW_SESSION=\$(bw unlock --raw)"
        return 1
    fi
}

# Resolve a (folder, query) lookup to the matching item as compact JSON, stored in
# the caller-scoped _bw_item. Results are memoized in _bw_cache for the duration of a
# bw_export call so one item feeding several variables (e.g. an access key + secret)
# is only decrypted once. This sets _bw_item instead of echoing because it must run in
# the current shell — a command substitution would subshell away the _bw_cache write.
# Cache records are "key<TAB>compact-json" lines; the JSON is single-line so newlines
# separate them.
_bw_fetch_item() {
    local query="$1" folder="$2"
    local key items folderid count k v
    _bw_item=""

    key="$folder"$'\x1f'"$query"
    while IFS=$'\t' read -r k v; do
        [[ "$k" == "$key" ]] && { _bw_item="$v"; return 0; }
    done <<<"$_bw_cache"

    if [[ -n "$folder" ]]; then
        folderid=$(bw list folders --search "$folder" | jq -r --arg n "$folder" '
            (map(select(.name | ascii_downcase == ($n | ascii_downcase))) + .)[0].id // empty')
        if [[ -z "$folderid" ]]; then
            log_error "bitwarden: no folder matching '$folder'"
            return 1
        fi
        items=$(bw list items --search "$query" --folderid "$folderid")
    else
        items=$(bw list items --search "$query")
    fi

    count=$(jq 'length' <<<"$items")
    if [[ "$count" -eq 0 ]]; then
        log_error "bitwarden: no item matching '$query'${folder:+ in folder '$folder'}"
        return 1
    fi

    _bw_item=$(jq -c --arg q "$query" '
        (map(select(.name | ascii_downcase == ($q | ascii_downcase))) + .)[0]' <<<"$items")
    if [[ "$count" -gt 1 ]]; then
        log_status "bitwarden: '$query' matched $count items; using '$(jq -r '.name' <<<"$_bw_item")'"
    fi

    _bw_cache+="${key}"$'\t'"${_bw_item}"$'\n'
}

# Shared driver for bw_export and bw_export_dryrun. mode "export" assigns each
# resolved value to the environment; mode "dryrun" prints "VAR=value" to stdout
# without touching the environment, so mappings can be previewed.
_bw_resolve() {
    local mode="$1"; shift
    _bw_require || return 1

    # _bw_cache and _bw_item are locals that _bw_fetch_item reads and writes via
    # bash's dynamic scoping — declaring them here keeps them out of the user's shell.
    local _bw_cache="" _bw_item=""
    local rc=0 mapping var rest field target query folder value
    for mapping in "$@"; do
        if [[ "$mapping" != *=* || "$mapping" != *:* ]]; then
            log_error "bitwarden: malformed mapping '$mapping' (expected 'VAR = field : item [@ folder]')"
            rc=1; continue
        fi

        var=$(_bw_trim "${mapping%%=*}")
        rest="${mapping#*=}"
        field=$(_bw_trim "${rest%%:*}")
        target="${rest#*:}"
        if [[ "$target" == *" @ "* ]]; then
            query=$(_bw_trim "${target% @ *}")
            folder=$(_bw_trim "${target##* @ }")
        else
            query=$(_bw_trim "$target")
            folder=""
        fi

        if [[ ! "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
            log_error "bitwarden: invalid variable name '$var'"
            rc=1; continue
        fi
        case "$field" in
            user|username) field=username ;;
            pass|password) field=password ;;
            *) log_error "bitwarden: unknown field '$field' for '$var' (use username/password)"; rc=1; continue ;;
        esac
        if [[ -z "$query" ]]; then
            log_error "bitwarden: empty item search for '$var'"
            rc=1; continue
        fi

        _bw_fetch_item "$query" "$folder" || { rc=1; continue; }
        value=$(jq -r --arg f "$field" '.login[$f] // empty' <<<"$_bw_item")
        if [[ -z "$value" ]]; then
            log_error "bitwarden: item for '$var' has no $field"
            rc=1; continue
        fi

        if [[ "$mode" == dryrun ]]; then
            printf '%s=%s\n' "$var" "$value"
        else
            export "$var=$value"
            log_status "bitwarden: set $var"
        fi
    done

    return "$rc"
}

bw_export() {
    _bw_resolve export "$@"
}

# Preview what bw_export would set: prints "VAR=value" for each mapping to stdout,
# revealing the secrets, without assigning anything to the environment.
bw_export_dryrun() {
    _bw_resolve dryrun "$@"
}
