#!/usr/bin/env bash
set -euo pipefail
source "$REFOCUS_ROOT/config.sh"
source "$REFOCUS_ROOT/services/database.sh"

db_ensure

sub="${1:-list}"; shift || true

case "$sub" in
    add|set)
        project="${1:-}"; desc="${2:-}"
        [[ -z "$project" || -z "$desc" ]] && { echo "Usage: focus describe add <project> <description>" >&2; exit 2; }
        db_set_description "$project" "$desc"
        echo "✅ Description set for '$project'."
        ;;
    show|get)
        project="${1:-}"; [[ -z "$project" ]] && { echo "Usage: focus describe show <project>" >&2; exit 2; }
        desc=$(db_get_description "$project")
        [[ -z "$desc" ]] && { echo "No description for '$project'."; exit 0; }
        echo "$project: $desc"
        ;;
    remove|rm|del)
        project="${1:-}"; [[ -z "$project" ]] && { echo "Usage: focus describe remove <project>" >&2; exit 2; }
        db_rm_description "$project"
        echo "✅ Description removed for '$project'."
        ;;
    list|ls)
        while IFS='|' read -r name desc; do
            printf "%-24s %s\n" "$name" "$desc"
        done < <(db_list_descriptions)
        ;;
    *)
        echo "Usage: focus describe <add|show|remove|list>" >&2; exit 2
        ;;
esac
