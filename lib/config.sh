#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/env.sh"
source "$REFOCUS_ROOT/services/help.sh"

wants_help "$@" && show_help config

# ENV_FILE is exported by env.sh — no need to re-derive it here.

_rewrite_env() {
    # <sed-expr> -> apply it to ENV_FILE in place. Writes into the original
    # file rather than `mv`-replacing it: mktemp defaults to mode 0600, and
    # `mv` would swap the inode in, silently dropping ENV_FILE's real
    # permissions to 0600 on every edit.
    local expr="$1" tmp
    tmp=$(mktemp "${ENV_FILE}.XXXXXX")
    sed "$expr" "$ENV_FILE" > "$tmp" && cat "$tmp" > "$ENV_FILE"
    rm -f "$tmp"
}

_show() {
    echo "Effective configuration:"
    printf "  %-24s = %s\n" "DB_PATH"            "$DB_PATH"
    printf "  %-24s = %s\n" "NUDGE_INTERVAL"     "$NUDGE_INTERVAL"
    printf "  %-24s = %s\n" "MAX_PROJECT_LENGTH"  "$MAX_PROJECT_LENGTH"
    printf "  %-24s = %s\n" "DATE_FORMAT"         "$DATE_FORMAT"
    printf "  %-24s = %s\n" "DATE_SHORT_FORMAT"   "$DATE_SHORT_FORMAT"
    printf "  %-24s = %s\n" "REPORT_LIMIT"        "$REPORT_LIMIT"
    echo ""
    if [[ -f "$ENV_FILE" && -s "$ENV_FILE" ]]; then
        echo "Overrides ($ENV_FILE):"
        # Strip REFOCUS_ prefix for readability. Split into -e clauses: BSD sed
        # requires a `t` label to end at a newline, and reads a `;`-terminated
        # label as part of the label name, so `t;s/^/  /` errors as an
        # "undefined label" on macOS even though GNU sed accepts it inline.
        sed -e 's/^REFOCUS_/  /' -e t -e 's/^/  /' "$ENV_FILE"
    else
        echo "(no overrides — $ENV_FILE)"
    fi
}

_valid_key() {
    case "$1" in
        NUDGE_INTERVAL|MAX_PROJECT_LENGTH|DATE_FORMAT|DATE_SHORT_FORMAT|REPORT_LIMIT|DB_PATH) return 0 ;;
        *) return 1 ;;
    esac
}

sub="${1:-show}"; shift || true

case "$sub" in
    show)
        _show
        ;;
    set)
        key="${1:-}"; val="${2:-}"
        [[ -z "$key" || -z "$val" ]] && usage_error config
        _valid_key "$key" || { echo "❌ Unknown key: $key" >&2
            echo "Valid: NUDGE_INTERVAL MAX_PROJECT_LENGTH DATE_FORMAT DATE_SHORT_FORMAT REPORT_LIMIT DB_PATH" >&2
            exit 2; }
        env_key="REFOCUS_${key}"
        touch "$ENV_FILE"
        if grep -q "^${env_key}=" "$ENV_FILE" 2>/dev/null; then
            _rewrite_env "s|^${env_key}=.*|${env_key}=${val}|"
        else
            echo "${env_key}=${val}" >> "$ENV_FILE"
        fi
        echo "✅ $key=$val"
        ;;
    unset)
        key="${1:-}"; [[ -z "$key" ]] && usage_error config
        env_key="REFOCUS_${key}"
        [[ -f "$ENV_FILE" ]] && _rewrite_env "/^${env_key}=/d"
        echo "✅ Unset $key (reverts to default)"
        ;;
    *)
        usage_error config
        ;;
esac
