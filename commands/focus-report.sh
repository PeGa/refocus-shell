#!/usr/bin/env bash
# Refocus Shell - Report Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# Source bootstrap module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"

function focus_report_today() {
    local raw_mode=false
    local args=("$@")
    
    # Check for --raw flag
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--raw" ]]; then
            raw_mode=true
            break
        fi
    done
    
    local period
    period=$(get_today_period)
    IFS='|' read -r start_time end_time <<< "$period"
    
    # Convert ISO timestamps to epoch for format_ts
    local start_epoch end_epoch
    start_epoch=$(date -d "$start_time" +%s)
    end_epoch=$(date -d "$end_time" +%s)
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        echo "📊 Today's Focus Report"
        echo "====================="
        echo "Period: $(format_ts "$start_epoch" "%Y-%m-%d")"
        echo
        
        focus_generate_report "$start_time" "$end_time"
    fi
}

function focus_report_week() {
    local raw_mode=false
    local args=("$@")
    
    # Check for --raw flag
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--raw" ]]; then
            raw_mode=true
            break
        fi
    done
    
    local period
    period=$(get_week_period)
    IFS='|' read -r start_time end_time <<< "$period"
    
    # Convert ISO timestamps to epoch for format_ts
    local start_epoch end_epoch
    start_epoch=$(date -d "$start_time" +%s)
    end_epoch=$(date -d "$end_time" +%s)
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        echo "📊 This Week's Focus Report"
        echo "========================="
        echo "Period: $(format_ts "$start_epoch" "%Y-%m-%d") to $(format_ts "$end_epoch" "%Y-%m-%d")"
        echo
        
        focus_generate_report "$start_time" "$end_time"
    fi
}

function focus_report_month() {
    local raw_mode=false
    local args=("$@")
    
    # Check for --raw flag
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--raw" ]]; then
            raw_mode=true
            break
        fi
    done
    
    local period
    period=$(get_month_period)
    IFS='|' read -r start_time end_time <<< "$period"
    
    # Convert ISO timestamps to epoch for format_ts
    local start_epoch end_epoch
    start_epoch=$(date -d "$start_time" +%s)
    end_epoch=$(date -d "$end_time" +%s)
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        echo "📊 This Month's Focus Report"
        echo "=========================="
        echo "Period: $(format_ts "$start_epoch" "%Y-%m-%d") to $(format_ts "$end_epoch" "%Y-%m-%d")"
        echo
        
        focus_generate_report "$start_time" "$end_time"
    fi
}

function focus_report_custom() {
    local days_back="$1"
    shift
    local raw_mode=false
    local args=("$@")
    
    # Check for --raw flag
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--raw" ]]; then
            raw_mode=true
            break
        fi
    done
    
    if [[ -z "$days_back" ]]; then
        echo "❌ Number of days is required."
        echo "Usage: focus report custom <days> [--raw]"
        echo "Example: focus report custom 7"
        echo "Example: focus report custom 7 --raw"
        exit 1
    fi
    
    # Basic validation - check if it's a number
    if ! [[ "$days_back" =~ ^[0-9]+$ ]]; then
        echo "❌ Days must be a positive number."
        exit 1
    fi
    
    local period
    period=$(get_custom_period "$days_back")
    IFS='|' read -r start_time end_time <<< "$period"
    
    # Convert ISO timestamps to epoch for format_ts
    local start_epoch end_epoch
    start_epoch=$(date -d "$start_time" +%s)
    end_epoch=$(date -d "$end_time" +%s)
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        echo "📊 Custom Focus Report (Last $days_back days)"
        echo "==========================================="
        echo "Period: $(format_ts "$start_epoch" "%Y-%m-%d") to $(format_ts "$end_epoch" "%Y-%m-%d")"
        echo
        
        focus_generate_report "$start_time" "$end_time"
    fi
}

function focus_generate_report() {
    local start_time="$1"
    local end_time="$2"
    local raw_mode=false
    
    # Check for --raw flag
    if [[ "$3" == "--raw" ]]; then
        raw_mode=true
    fi
    
    # Get sessions in the specified period (including duration-only sessions)
    local sessions
    # Escape timestamps for SQL
    local escaped_start_time
    local escaped_end_time
    escaped_start_time=$(_sql_escape "$start_time")
    escaped_end_time=$(_sql_escape "$end_time")
    
    sessions=$(execute_sqlite "SELECT project, start_time, end_time, duration_seconds, notes, duration_only, session_date FROM ${REFOCUS_SESSIONS_TABLE:-sessions} WHERE project != '[idle]' AND (end_time >= '$escaped_start_time' AND end_time <= '$escaped_end_time') OR (duration_only = 1 AND session_date >= '$escaped_start_time' AND session_date <= '$escaped_end_time') ORDER BY COALESCE(end_time, session_date) DESC;" "focus_generate_report")
    
    if [[ -z "$sessions" ]]; then
        echo "No focus sessions found in the specified period."
        return 0
    fi
    
    # Calculate totals
    local total_duration=0
    local project_totals=()
    local project_sessions=()
    local project_durations=()
    local project_date_ranges=()
    local session_count=0
    
    while IFS='|' read -r project session_start session_end duration notes duration_only session_date; do
        if [[ "$project" != "[idle]" ]]; then
            total_duration=$((total_duration + duration))
            session_count=$((session_count + 1))
            
            # Track project totals
            local found=0
            for i in "${!project_totals[@]}"; do
                if [[ "${project_totals[$i]}" == "$project" ]]; then
                    project_sessions[$i]=$((${project_sessions[$i]} + 1))
                    project_durations[$i]=$((${project_durations[$i]} + duration))
                    found=1
                    break
                fi
            done
            
            if [[ $found -eq 0 ]]; then
                project_totals+=("$project")
                project_sessions+=(1)
                project_durations+=($duration)
                if [[ "$duration_only" == "1" ]]; then
                    project_date_ranges+=("$session_date|$session_date")
                else
                    project_date_ranges+=("$session_start|$session_end")
                fi
            fi
        fi
    done <<< "$sessions"
    
    # Display summary
    local total_hours=$((total_duration / 3600))
    local total_minutes=$(((total_duration % 3600) / 60))
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "total_duration_seconds,total_sessions,active_projects"
        echo "$total_duration,$session_count,${#project_totals[@]}"
        echo
    else
        echo "📈 Summary:"
        echo "   Total focus time: ${total_hours}h ${total_minutes}m"
        echo "   Total sessions: $session_count"
        echo "   Active projects: ${#project_totals[@]}"
        echo
    fi
    
    # Generate markdown report file
    local report_filename
    report_filename="focus-report-$(format_ts "$(date -d "$end_time" +%s)" "%Y-%m-%d").md"
    
    # Create markdown report
    {
        echo "# Focus Report - $(format_ts "$(date -d "$start_time" +%s)" "%Y-%m-%d") to $(format_ts "$(date -d "$end_time" +%s)" "%Y-%m-%d")"
        echo ""
        echo "## Summary"
        echo "- **Total focus time**: ${total_hours}h ${total_minutes}m"
        echo "- **Total sessions**: $session_count"
        echo "- **Active projects**: ${#project_totals[@]}"
        echo ""
        
        if [[ ${#project_totals[@]} -gt 0 ]]; then
            echo "## Project Breakdown"
            echo "| Project | Sessions | Total Time | Date Range |"
            echo "|---------|----------|------------|------------|"
            
            for i in "${!project_totals[@]}"; do
                local project="${project_totals[$i]}"
                local sessions_count="${project_sessions[$i]}"
                local project_duration="${project_durations[$i]}"
                local date_range="${project_date_ranges[$i]}"
                
                local proj_hours=$((project_duration / 3600))
                local proj_minutes=$(((project_duration % 3600) / 60))
                
                # Parse date range
                IFS='|' read -r earliest_start latest_end <<< "$date_range"
                local start_date=$(format_ts "$(date -d "$earliest_start" +%s)" "%Y-%m-%d")
                local end_date=$(format_ts "$(date -d "$latest_end" +%s)" "%Y-%m-%d")
                
                if [[ "$start_date" == "$end_date" ]]; then
                    local date_display="$start_date"
                else
                    local date_display="$start_date to $end_date"
                fi
                
                echo "| $project | $sessions_count | ${proj_hours}h ${proj_minutes}m | $date_display |"
            done
            echo ""
        fi
        
        echo "## Session Details"
        echo ""
        
        if [[ -n "$sessions" ]]; then
            local session_num=1
            while IFS='|' read -r project start end duration notes duration_only session_date; do
                if [[ "$project" != "[idle]" ]]; then
                    local duration_min
                    duration_min=$((duration / 60))
                    local duration_hours=$((duration / 3600))
                    local duration_remaining_min=$(((duration % 3600) / 60))
                    
                    local duration_display
                    if [[ $duration_hours -gt 0 ]]; then
                        duration_display="${duration_hours}h ${duration_remaining_min}m"
                    else
                        duration_display="${duration_min}m"
                    fi
                    
                    if [[ "$duration_only" == "1" ]]; then
                        # Duration-only session
                        local session_date_display
                        session_date_display=$(format_ts "$(date -d "$session_date" +%s)" "%Y-%m-%d")
                        echo "$session_num. **$project** (Manual entry: $session_date_display, $duration_display)"
                    else
                        # Regular session
                        local start_date
                        start_date=$(format_ts "$(date -d "$start" +%s)" "%Y-%m-%d %H:%M")
                        local end_date
                        end_date=$(format_ts "$(date -d "$end" +%s)" "%H:%M")
                        echo "$session_num. **$project** ($start_date - $end_date, $duration_display)"
                    fi
                    
                    # Show notes with proper line breaks
                    if [[ -n "$notes" ]]; then
                        echo "   - $notes"
                    else
                        # If no session notes, try to show project description
                        local project_desc
                        project_desc=$(get_project_description "$project")
                        if [[ -n "$project_desc" ]]; then
                            echo "   - $project_desc"
                        fi
                    fi
                    echo ""
                    
                    session_num=$((session_num + 1))
                fi
            done <<< "$sessions"
        else
            echo "No sessions found"
        fi
    } > "$report_filename"
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "project,start_time,end_time,duration_seconds,notes,duration_only,session_date"
        if [[ -n "$sessions" ]]; then
            while IFS='|' read -r project start end duration notes duration_only session_date; do
                if [[ "$project" != "[idle]" ]]; then
                    echo "$project,$start,$end,$duration,$notes,$duration_only,$session_date"
                fi
            done <<< "$sessions"
        fi
    else
        echo "📄 Detailed report saved to: $report_filename"
    fi
}

function focus_report() {
    local period="$1"
    shift
    
    case "$period" in
        "today")
            focus_report_today "$@"
        ;;
        "week")
            focus_report_week "$@"
        ;;
        "month")
            focus_report_month "$@"
        ;;
        "custom")
            focus_report_custom "$@"
        ;;
        *)
            echo "❌ Unknown period: $period"
            echo "Available periods:"
            echo "  today   - Today's focus"
            echo "  week    - This week's focus"
            echo "  month   - This month's focus"
            echo "  custom  - Custom period (specify days)"
            echo
            echo "Examples:"
            echo "  focus report today"
            echo "  focus report week"
            echo "  focus report month"
            echo "  focus report custom 7"
            echo "  focus report today --raw"
            echo "  focus report custom 7 --raw"
            exit 1
        ;;
    esac
}


# Main execution
refocus_script_main focus_report "$@"
