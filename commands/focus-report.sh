#!/usr/bin/env bash
# Refocus Shell - Report Subcommand
# Copyright (c) 2025 PeGa
# Licensed under the GNU General Public License v3

PROJECTS_TABLE="${PROJECTS_TABLE:-projects}"

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/focus-bootstrap.sh"
source "$SCRIPT_DIR/../lib/focus-db.sh"
source "$SCRIPT_DIR/../lib/focus-output.sh"

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
    
    # Convert ISO timestamps to date format
    local start_date end_date
    start_date=$(date --date="$start_time" +"%Y-%m-%d" 2>/dev/null || echo "$start_time")
    end_date=$(date --date="$end_time" +"%Y-%m-%d" 2>/dev/null || echo "$end_time")
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        print_report_header "Today's Focus Report" "$start_date" "$end_date"
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
    
    # Convert ISO timestamps to date format
    local start_date end_date
    start_date=$(date --date="$start_time" +"%Y-%m-%d" 2>/dev/null || echo "$start_time")
    end_date=$(date --date="$end_time" +"%Y-%m-%d" 2>/dev/null || echo "$end_time")
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        print_report_header "This Week's Focus Report" "$start_date" "$end_date"
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
    
    # Convert ISO timestamps to date format
    local start_date end_date
    start_date=$(date --date="$start_time" +"%Y-%m-%d" 2>/dev/null || echo "$start_time")
    end_date=$(date --date="$end_time" +"%Y-%m-%d" 2>/dev/null || echo "$end_time")
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        print_report_header "This Month's Focus Report" "$start_date" "$end_date"
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
    
    # Convert ISO timestamps to date format
    local start_date end_date
    start_date=$(date --date="$start_time" +"%Y-%m-%d" 2>/dev/null || echo "$start_time")
    end_date=$(date --date="$end_time" +"%Y-%m-%d" 2>/dev/null || echo "$end_time")
    
    if [[ "$raw_mode" == "true" ]]; then
        echo "start_time,end_time"
        echo "$start_time,$end_time"
        echo
        focus_generate_report "$start_time" "$end_time" --raw
    else
        print_report_header "Custom Focus Report (Last $days_back days)" "$start_date" "$end_date"
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
    
    # Convert ISO timestamps to date range for db_stats
    local start_date end_date
    start_date=$(date --date="$start_time" +"%Y-%m-%d" 2>/dev/null || echo "$start_time")
    end_date=$(date --date="$end_time" +"%Y-%m-%d" 2>/dev/null || echo "$end_time")
    
    # Use db_stats --detailed to get all the data we need
    local stats_data
    stats_data=$(db_stats --detailed "$start_date,$end_date")
    
    if [[ -z "$stats_data" ]]; then
        echo "No focus sessions found in the specified period."
        return 0
    fi
    
    # Parse the stats data
    local summary_line
    local projects_section
    local sessions_section
    
    summary_line=$(echo "$stats_data" | grep "^SUMMARY:" | cut -d: -f2)
    projects_section=$(echo "$stats_data" | grep "^PROJECTS:" | cut -d: -f2-)
    sessions_section=$(echo "$stats_data" | grep "^SESSIONS:" | cut -d: -f2-)
    
    # Parse summary
    IFS='|' read -r total_sessions total_duration avg_duration projects_count <<< "$summary_line"
    
    # Display summary
    if [[ "$raw_mode" == "true" ]]; then
        echo "total_duration_seconds,total_sessions,active_projects"
        echo "$total_duration,$total_sessions,$projects_count"
        echo
    else
        print_report_summary "$total_sessions" "$total_duration" "$projects_count"
    fi
    
    # Generate markdown report file
    local report_filename
    local end_epoch_for_filename
    end_epoch_for_filename=$(date -d "$end_time" +%s)
    report_filename="focus-report-$(format_ts "$end_epoch_for_filename" "%Y-%m-%d").md"
    
    # Create markdown report using centralized functions
    {
        echo "# Focus Report - $start_date to $end_date"
        echo ""
        echo "## Summary"
        echo "- **Total focus time**: $((total_duration / 3600))h $(((total_duration % 3600) / 60))m"
        echo "- **Total sessions**: $total_sessions"
        echo "- **Active projects**: $projects_count"
        echo ""
        
        if [[ -n "$projects_section" ]]; then
            echo "## Project Breakdown"
            echo "| Project | Sessions | Total Time | Date Range |"
            echo "|---------|----------|------------|------------|"
            
            while IFS='|' read -r project sessions duration earliest_start latest_end; do
                print_report_project_row "$project" "$sessions" "$duration" "$earliest_start" "$latest_end"
            done <<< "$projects_section"
            echo ""
        fi
        
        echo "## Session Details"
        echo ""
        
        if [[ -n "$sessions_section" ]]; then
            local session_num=1
            while IFS='|' read -r project start end duration notes duration_only session_date; do
                print_report_table_row "$session_num" "$project" "$start" "$end" "$duration" "$notes" "$duration_only" "$session_date"
                session_num=$((session_num + 1))
            done <<< "$sessions_section"
        else
            echo "No sessions found"
        fi
    } > "$report_filename"
    
    if [[ "$raw_mode" == "true" ]]; then
        print_report_table_header
        if [[ -n "$sessions_section" ]]; then
            while IFS='|' read -r project start end duration notes duration_only session_date; do
                if [[ "$project" != "[idle]" ]]; then
                    print_report_row_raw "$project" "$start" "$end" "$duration" "$notes" "$duration_only" "$session_date"
                fi
            done <<< "$sessions_section"
        fi
    else
        print_report_footer "$report_filename"
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
