#!/usr/bin/env bash
# Refocus Shell - Generate Reports Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HOME/.local/focus/lib/focus-db.sh" ]]; then
    source "$HOME/.local/focus/lib/focus-db.sh"
    source "$HOME/.local/focus/lib/focus-utils.sh"
else
    source "$SCRIPT_DIR/../lib/focus-db.sh"
    source "$SCRIPT_DIR/../lib/focus-utils.sh"
fi

# Set table names
STATE_TABLE="${STATE_TABLE:-state}"
SESSIONS_TABLE="${SESSIONS_TABLE:-sessions}"

function focus_report_today() {
    local period
    period=$(get_today_period)
    IFS='|' read -r start_time end_time <<< "$period"
    
    echo "📊 Today's Focus Report"
    echo "====================="
    echo "Period: $(date --date="$start_time" +"%Y-%m-%d")"
    echo
    
    work_generate_report "$start_time" "$end_time"
}

function focus_report_week() {
    local period
    period=$(get_week_period)
    IFS='|' read -r start_time end_time <<< "$period"
    
    echo "📊 This Week's Focus Report"
    echo "========================="
    echo "Period: $(date --date="$start_time" +"%Y-%m-%d") to $(date --date="$end_time" +"%Y-%m-%d")"
    echo
    
    work_generate_report "$start_time" "$end_time"
}

function focus_report_month() {
    local period
    period=$(get_month_period)
    IFS='|' read -r start_time end_time <<< "$period"
    
    echo "📊 This Month's Focus Report"
    echo "=========================="
    echo "Period: $(date --date="$start_time" +"%Y-%m-%d") to $(date --date="$end_time" +"%Y-%m-%d")"
    echo
    
    work_generate_report "$start_time" "$end_time"
}

function focus_report_custom() {
    local days_back="$1"
    
    if [[ -z "$days_back" ]]; then
        echo "❌ Number of days is required."
        echo "Usage: focus report custom <days>"
        echo "Example: focus report custom 7"
        exit 1
    fi
    
    if ! validate_numeric_input "$days_back" "Days"; then
        exit 1
    fi
    
    local period
    period=$(get_custom_period "$days_back")
    IFS='|' read -r start_time end_time <<< "$period"
    
    echo "📊 Custom Focus Report (Last $days_back days)"
    echo "==========================================="
    echo "Period: $(date --date="$start_time" +"%Y-%m-%d") to $(date --date="$end_time" +"%Y-%m-%d")"
    echo
    
    work_generate_report "$start_time" "$end_time"
}

function focus_generate_report() {
    local start_time="$1"
    local end_time="$2"
    
    # Get sessions in the specified period
    local sessions
    sessions=$(get_sessions_in_range "$start_time" "$end_time")
    
    if [[ -z "$sessions" ]]; then
        echo "No focus sessions found in the specified period."
        return 0
    fi
    
    # Calculate totals
    local total_duration=0
    local project_totals=()
    local project_sessions=()
    
    while IFS='|' read -r project session_start session_end duration; do
        if [[ "$project" != "[idle]" ]]; then
            total_duration=$((total_duration + duration))
            
            # Track project totals
            local found=0
            for i in "${!project_totals[@]}"; do
                if [[ "${project_totals[$i]}" == "$project" ]]; then
                    project_sessions[$i]=$((${project_sessions[$i]} + 1))
                    found=1
                    break
                fi
            done
            
            if [[ $found -eq 0 ]]; then
                project_totals+=("$project")
                project_sessions+=(1)
            fi
        fi
    done <<< "$sessions"
    
    # Display summary
    local total_hours=$((total_duration / 3600))
    local total_minutes=$(((total_duration % 3600) / 60))
    
    echo "📈 Summary:"
    echo "   Total focus time: ${total_hours}h ${total_minutes}m"
    echo "   Total sessions: $(echo "$sessions" | wc -l)"
    echo "   Active projects: ${#project_totals[@]}"
    echo
    
    # Display project breakdown
    if [[ ${#project_totals[@]} -gt 0 ]]; then
        echo "📋 Project Breakdown:"
        for i in "${!project_totals[@]}"; do
            local project="${project_totals[$i]}"
            local sessions_count="${project_sessions[$i]}"
            
            # Calculate total time for this project in the period
            local project_duration=0
            while IFS='|' read -r p start end dur; do
                if [[ "$p" == "$project" ]]; then
                    project_duration=$((project_duration + dur))
                fi
            done <<< "$sessions"
            
            local proj_hours=$((project_duration / 3600))
            local proj_minutes=$(((project_duration % 3600) / 60))
            
            printf "   %-20s %3d sessions  %2dh %2dm\n" "$project" "$sessions_count" "$proj_hours" "$proj_minutes"
        done
        echo
    fi
    
    # Display recent sessions
    echo "🕒 Recent Sessions:"
    local recent_sessions
    recent_sessions=$(echo "$sessions" | tail -5)
    
    if [[ -n "$recent_sessions" ]]; then
        while IFS='|' read -r project start end duration; do
            if [[ "$project" != "[idle]" ]]; then
                local start_date
                start_date=$(date --date="$start" +"%m-%d %H:%M")
                local end_date
                end_date=$(date --date="$end" +"%H:%M")
                local duration_min
                duration_min=$((duration / 60))
                
                printf "   %-20s %s-%s  %3dm\n" "$project" "$start_date" "$end_date" "$duration_min"
            fi
        done <<< "$recent_sessions"
    else
        echo "   No recent sessions"
    fi
}

function focus_report() {
    local period="$1"
    shift
    
    case "$period" in
        "today")
                    focus_report_today
        ;;
    "week")
        focus_report_week
        ;;
    "month")
        focus_report_month
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
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    focus_report "$@"
fi 