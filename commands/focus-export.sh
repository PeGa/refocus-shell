#!/usr/bin/env bash
# Refocus Shell - Export Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Table name variables
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"
PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

generate_json_export() {
    local json_file="$1"
    
    # Get current timestamp in ISO format
    local export_timestamp
    export_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Start building JSON structure
    local json_content='{
  "schema_version": "1.0",
  "export_timestamp": "'"$export_timestamp"'",
  "refocus_version": "1.0.0",
  "data": {
'
    
    # Export state data
    local state_data
    state_data=$(execute_sqlite "SELECT active, project, start_time, prompt_content, prompt_type, nudging_enabled, focus_disabled, last_focus_off_time, paused, pause_notes, pause_start_time, previous_elapsed FROM $STATE_TABLE WHERE id = 1;" "generate_json_export")
    
    if [[ -n "$state_data" ]]; then
        IFS='|' read -r active project start_time prompt_content prompt_type nudging_enabled focus_disabled last_focus_off_time paused pause_notes pause_start_time previous_elapsed <<< "$state_data"
        
        # Escape JSON strings properly
        project=$(echo "$project" | sed 's/\\/\\\\/g; s/"/\\"/g')
        start_time=$(echo "$start_time" | sed 's/\\/\\\\/g; s/"/\\"/g')
        prompt_content=$(echo "$prompt_content" | sed 's/\\/\\\\/g; s/"/\\"/g')
        prompt_type=$(echo "$prompt_type" | sed 's/\\/\\\\/g; s/"/\\"/g')
        last_focus_off_time=$(echo "$last_focus_off_time" | sed 's/\\/\\\\/g; s/"/\\"/g')
        pause_notes=$(echo "$pause_notes" | sed 's/\\/\\\\/g; s/"/\\"/g')
        pause_start_time=$(echo "$pause_start_time" | sed 's/\\/\\\\/g; s/"/\\"/g')
        
        # Convert null values
        [[ "$project" == "" ]] && project="null" || project="\"$project\""
        [[ "$start_time" == "" ]] && start_time="null" || start_time="\"$start_time\""
        [[ "$prompt_content" == "" ]] && prompt_content="null" || prompt_content="\"$prompt_content\""
        [[ "$prompt_type" == "" ]] && prompt_type="\"default\"" || prompt_type="\"$prompt_type\""
        [[ "$last_focus_off_time" == "" ]] && last_focus_off_time="null" || last_focus_off_time="\"$last_focus_off_time\""
        [[ "$pause_notes" == "" ]] && pause_notes="null" || pause_notes="\"$pause_notes\""
        [[ "$pause_start_time" == "" ]] && pause_start_time="null" || pause_start_time="\"$pause_start_time\""
        
        # Convert boolean values
        [[ "$nudging_enabled" == "1" ]] && nudging_enabled="true" || nudging_enabled="false"
        [[ "$focus_disabled" == "1" ]] && focus_disabled="true" || focus_disabled="false"
        
        json_content+='    "state": {
      "active": '"$active"',
      "project": '"$project"',
      "start_time": '"$start_time"',
      "prompt_content": '"$prompt_content"',
      "prompt_type": '"$prompt_type"',
      "nudging_enabled": '"$nudging_enabled"',
      "focus_disabled": '"$focus_disabled"',
      "last_focus_off_time": '"$last_focus_off_time"',
      "paused": '"$paused"',
      "pause_notes": '"$pause_notes"',
      "pause_start_time": '"$pause_start_time"',
      "previous_elapsed": '"$previous_elapsed"'
    },
'
    else
        json_content+='    "state": null,
'
    fi
    
    # Export sessions data
    json_content+='    "sessions": [
'
    
    local sessions_data
    sessions_data=$(execute_sqlite "SELECT id, project, start_time, end_time, duration_seconds, notes, duration_only, session_date FROM $SESSIONS_TABLE ORDER BY id;" "generate_json_export")
    
    local session_count=0
    if [[ -n "$sessions_data" ]]; then
        while IFS='|' read -r id project start_time end_time duration_seconds notes duration_only session_date; do
            if [[ $session_count -gt 0 ]]; then
                json_content+=',
'
            fi
            
            # Escape JSON strings properly
            project=$(echo "$project" | sed 's/\\/\\\\/g; s/"/\\"/g')
            start_time=$(echo "$start_time" | sed 's/\\/\\\\/g; s/"/\\"/g')
            end_time=$(echo "$end_time" | sed 's/\\/\\\\/g; s/"/\\"/g')
            notes=$(echo "$notes" | sed 's/\\/\\\\/g; s/"/\\"/g')
            session_date=$(echo "$session_date" | sed 's/\\/\\\\/g; s/"/\\"/g')
            
            # Convert null values
            [[ "$start_time" == "" ]] && start_time="null" || start_time="\"$start_time\""
            [[ "$end_time" == "" ]] && end_time="null" || end_time="\"$end_time\""
            [[ "$notes" == "" ]] && notes="null" || notes="\"$notes\""
            [[ "$session_date" == "" ]] && session_date="null" || session_date="\"$session_date\""
            
            # Convert boolean values
            [[ "$duration_only" == "1" ]] && duration_only="true" || duration_only="false"
            
            json_content+='      {
        "id": '"$id"',
        "project": "'"$project"'",
        "start_time": '"$start_time"',
        "end_time": '"$end_time"',
        "duration_seconds": '"$duration_seconds"',
        "notes": '"$notes"',
        "duration_only": '"$duration_only"',
        "session_date": '"$session_date"'
      }'
            
            session_count=$((session_count + 1))
        done <<< "$sessions_data"
    fi
    
    json_content+='
    ],
'
    
    # Export projects data
    json_content+='    "projects": [
'
    
    local projects_data
    projects_data=$(execute_sqlite "SELECT project, description, created_at, updated_at FROM $PROJECTS_TABLE ORDER BY project;" "generate_json_export")
    
    local project_count=0
    if [[ -n "$projects_data" ]]; then
        while IFS='|' read -r project description created_at updated_at; do
            if [[ $project_count -gt 0 ]]; then
                json_content+=',
'
            fi
            
            # Escape JSON strings properly
            project=$(echo "$project" | sed 's/\\/\\\\/g; s/"/\\"/g')
            description=$(echo "$description" | sed 's/\\/\\\\/g; s/"/\\"/g')
            created_at=$(echo "$created_at" | sed 's/\\/\\\\/g; s/"/\\"/g')
            updated_at=$(echo "$updated_at" | sed 's/\\/\\\\/g; s/"/\\"/g')
            
            json_content+='      {
        "project": "'"$project"'",
        "description": "'"$description"'",
        "created_at": "'"$created_at"'",
        "updated_at": "'"$updated_at"'"
      }'
            
            project_count=$((project_count + 1))
        done <<< "$projects_data"
    fi
    
    json_content+='
    ]
  }
}'
    
    # Write JSON to file
    echo "$json_content" > "$json_file"
    
    if [[ $? -eq 0 ]]; then
        return 0
    else
        echo "❌ Failed to write JSON export file: $json_file" >&2
        return 1
    fi
}

function focus_export() {
    local output_file="$1"
    
    # Handle help flag
    if [[ "$output_file" == "--help" ]] || [[ "$output_file" == "-h" ]]; then
        echo "Usage: focus export [filename]"
        echo
        echo "Export focus data to SQLite dump and JSON files."
        echo
        echo "Arguments:"
        echo "  filename    Optional base filename (without extension)"
        echo "              If not provided, generates: refocus-export-YYYYMMDD_HHMMSS"
        echo
        echo "Output files:"
        echo "  filename.sql   - SQLite database dump"
        echo "  filename.json  - Structured JSON export"
        echo
        echo "Examples:"
        echo "  focus export                    # Export with auto-generated filename"
        echo "  focus export my-backup          # Export to my-backup.sql and my-backup.json"
        echo "  focus export /path/to/backup    # Export to absolute path"
        return 0
    fi
    
    if [[ -z "$output_file" ]]; then
        # Generate default filename
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        output_file="refocus-export-${timestamp}"
    fi
    
    # Check if database exists
    if [[ ! -f "$DB" ]]; then
        echo "❌ Database not found: $DB"
        exit 1
    fi
    
    # Generate filenames for both formats
    local sql_file="${output_file}.sql"
    local json_file="${output_file}.json"
    
    # Validate file paths
    if ! validate_file_path "$sql_file" "SQLite output file"; then
        exit 1
    fi
    if ! validate_file_path "$json_file" "JSON output file"; then
        exit 1
    fi
    
    echo "📤 Exporting focus data..."
    echo "   SQLite dump: $sql_file"
    echo "   JSON export: $json_file"
    
    # Create SQLite dump
    execute_sqlite ".dump" "focus_export" > "$sql_file"
    local sql_exit_code=$?
    
    # Create JSON export
    generate_json_export "$json_file"
    local json_exit_code=$?
    
    if [[ $sql_exit_code -eq 0 ]] && [[ $json_exit_code -eq 0 ]]; then
        echo "✅ Focus data exported successfully!"
        echo "📊 Export contains:"
        echo "   - Database schema"
        echo "   - All focus sessions (live and duration-only)"
        echo "   - Current focus state"
        echo "   - Project descriptions"
        echo "   - Pause/resume session data"
        echo ""
        echo "To import this data, use: focus import $sql_file"
        echo "   OR: focus import $json_file"
    else
        echo "❌ Export failed"
        if [[ $sql_exit_code -ne 0 ]]; then
            echo "   SQLite dump failed"
        fi
        if [[ $json_exit_code -ne 0 ]]; then
            echo "   JSON export failed"
        fi
        exit 1
    fi
}


# Main execution
refocus_script_main focus_export "$@"
