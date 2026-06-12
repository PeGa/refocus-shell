#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"

# ENV_FILE is exported by config.sh — no need to re-derive it here.

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
        # Strip REFOCUS_ prefix for readability
        sed 's/^REFOCUS_/  /;t;s/^/  /' "$ENV_FILE"
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
        [[ -z "$key" || -z "$val" ]] && { echo "Usage: focus config set <KEY> <value>" >&2; exit 2; }
        _valid_key "$key" || { echo "❌ Unknown key: $key" >&2
            echo "Valid: NUDGE_INTERVAL MAX_PROJECT_LENGTH DATE_FORMAT DATE_SHORT_FORMAT REPORT_LIMIT DB_PATH" >&2
            exit 2; }
        env_key="REFOCUS_${key}"
        touch "$ENV_FILE"
        if grep -q "^${env_key}=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^${env_key}=.*|${env_key}=${val}|" "$ENV_FILE"
        else
            echo "${env_key}=${val}" >> "$ENV_FILE"
        fi
        echo "✅ $key=$val"
        ;;
    unset)
        key="${1:-}"; [[ -z "$key" ]] && { echo "Usage: focus config unset <KEY>" >&2; exit 2; }
        env_key="REFOCUS_${key}"
        [[ -f "$ENV_FILE" ]] && sed -i "/^${env_key}=/d" "$ENV_FILE" || true
        echo "✅ Unset $key (reverts to default)"
        ;;
    *)
        echo "Usage: focus config <show|set|unset>" >&2; exit 2
        ;;
esac
