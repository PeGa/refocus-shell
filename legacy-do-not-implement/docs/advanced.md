# Advanced Usage

This guide covers power-user features, automation, and advanced integration techniques for Refocus Shell.

## Shell Integration and Automation

### Advanced Prompt Customization

#### Custom Prompt Functions
Create sophisticated prompt integration:

```bash
# Add to ~/.bashrc
advanced_refocus_prompt() {
    if [[ -f "$HOME/.local/refocus/refocus.db" ]]; then
        local state
        state=$(sqlite3 "$HOME/.local/refocus/refocus.db" \
            "SELECT active, project, start_time, paused FROM state WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$state" ]]; then
            IFS='|' read -r active project start_time paused <<< "$state"
            
            if [[ "$active" -eq 1 ]] && [[ -n "$project" ]]; then
                if [[ "$paused" -eq 1 ]]; then
                    # Paused session - yellow
                    export PS1="⏸️  \[\033[1;33m\][$project]\[\033[0m\] $REFOCUS_ORIGINAL_PS1"
                else
                    # Active session - green
                    local now=$(date +%s)
                    local start_ts=$(date --date="$start_time" +%s 2>/dev/null)
                    if [[ -n "$start_ts" ]]; then
                        local elapsed=$(( (now - start_ts) / 60 ))
                        export PS1="⏳ \[\033[1;32m\][$project ${elapsed}m]\[\033[0m\] $REFOCUS_ORIGINAL_PS1"
                    else
                        export PS1="⏳ \[\033[1;32m\][$project]\[\033[0m\] $REFOCUS_ORIGINAL_PS1"
                    fi
                fi
            else
                # No active session
                export PS1="$REFOCUS_ORIGINAL_PS1"
            fi
        fi
    fi
}

# Update prompt after each command
PROMPT_COMMAND="advanced_refocus_prompt; $PROMPT_COMMAND"
```

#### Multi-Line Prompt Integration
```bash
# Two-line prompt with focus info
refocus_multiline_prompt() {
    local focus_line=""
    if [[ -f "$HOME/.local/refocus/refocus.db" ]]; then
        local project
        project=$(sqlite3 "$HOME/.local/refocus/refocus.db" \
            "SELECT project FROM state WHERE active = 1;" 2>/dev/null)
        
        if [[ -n "$project" ]]; then
            focus_line="\n🎯 Currently focusing on: \[\033[1;36m\]$project\[\033[0m\]"
        fi
    fi
    
    export PS1="$focus_line\n$REFOCUS_ORIGINAL_PS1"
}
```

### Workflow Automation

#### Project-Specific Aliases
```bash
# Create aliases for common projects
alias fcode='focus on "coding"'
alias fmeet='focus on "meetings"'
alias fplan='focus on "planning"'
alias fdocs='focus on "documentation"'

# Quick status check
alias fs='focus status'
alias fl='focus past list 5'

# Quick session end with common notes
alias fcode-end='echo "Implemented features, fixed bugs" | focus off'
alias fmeet-end='echo "Attended team meeting" | focus off'
```

#### Directory-Based Auto-Focus
```bash
# Add to ~/.bashrc
auto_focus_on_cd() {
    local old_pwd="$OLDPWD"
    local new_pwd="$PWD"
    
    # Define project mappings
    case "$new_pwd" in
        */projects/webapp*)
            focus on "webapp-development" >/dev/null 2>&1
            ;;
        */projects/api*)
            focus on "api-development" >/dev/null 2>&1
            ;;
        */Documents/work*)
            focus on "documentation" >/dev/null 2>&1
            ;;
    esac
}

# Hook into cd command
cd() {
    builtin cd "$@"
    auto_focus_on_cd
}
```

#### Smart Session Management
```bash
# Intelligent session start/stop
smart_focus() {
    local action="$1"
    local project="$2"
    
    case "$action" in
        "start")
            # Auto-continue if recent session exists
            local last_project
            last_project=$(sqlite3 ~/.local/refocus/refocus.db \
                "SELECT project FROM sessions ORDER BY id DESC LIMIT 1;" 2>/dev/null)
            
            if [[ "$project" == "$last_project" ]]; then
                echo "🔄 Continuing work on $project"
                focus on "$project"
            else
                echo "🎯 Starting new focus session: $project"
                focus on "$project"
            fi
            ;;
        "break")
            # Pause with automatic notes
            echo "Taking a short break" | focus pause
            ;;
        "switch")
            # Switch projects with notes
            echo "Switching to $project" | focus off
            focus on "$project"
            ;;
    esac
}

alias fstart='smart_focus start'
alias fbreak='smart_focus break' 
alias fswitch='smart_focus switch'
```

## Integration with External Tools

### Git Integration

#### Automatic Git Commit Messages
```bash
# Enhanced git commit with focus context
git_with_focus() {
    local commit_msg="$1"
    local current_project
    current_project=$(sqlite3 ~/.local/refocus/refocus.db \
        "SELECT project FROM state WHERE active = 1;" 2>/dev/null)
    
    if [[ -n "$current_project" ]]; then
        git commit -m "[$current_project] $commit_msg"
    else
        git commit -m "$commit_msg"
    fi
}

alias gfc='git_with_focus'
```

#### Git Hook Integration
```bash
# .git/hooks/post-commit
#!/bin/bash
# Automatically add commit info to focus session notes

current_project=$(sqlite3 ~/.local/refocus/refocus.db \
    "SELECT project FROM state WHERE active = 1;" 2>/dev/null)

if [[ -n "$current_project" ]]; then
    commit_hash=$(git rev-parse --short HEAD)
    commit_msg=$(git log -1 --pretty=%B)
    
    # Add commit info to session notes
    echo "Git commit $commit_hash: $commit_msg" | focus notes add "$current_project"
fi
```

### IDE Integration

#### VS Code Integration
```bash
# Open VS Code with automatic focus
code_focus() {
    local project_dir="$1"
    local project_name=$(basename "$project_dir")
    
    focus on "$project_name"
    code "$project_dir"
}

# VS Code termination detection
track_vscode_session() {
    local project="$1"
    local vscode_pid
    
    focus on "$project"
    code . &
    vscode_pid=$!
    
    # Wait for VS Code to close
    wait $vscode_pid
    echo "VS Code session completed" | focus off
}
```

#### Vim Integration
```bash
# Add to ~/.vimrc
" Automatic focus integration for Vim
function! StartFocusSession()
    let project = input('Project name: ')
    if project != ''
        execute '!focus on "' . project . '"'
    endif
endfunction

function! EndFocusSession()
    let notes = input('Session notes: ')
    if notes != ''
        execute '!echo "' . notes . '" | focus off'
    else
        execute '!focus off'
    endif
endfunction

command! FocusStart call StartFocusSession()
command! FocusEnd call EndFocusSession()

" Auto-commands for long editing sessions
autocmd VimEnter * if argc() > 0 | call StartFocusSession() | endif
autocmd VimLeave * call EndFocusSession()
```

### Task Management Integration

#### Todoist Integration
```bash
# Todoist task to focus session
todoist_focus() {
    local task_id="$1"
    
    # Get task details (requires Todoist CLI)
    local task_info
    task_info=$(todoist show "$task_id")
    local task_name
    task_name=$(echo "$task_info" | grep "Content:" | cut -d' ' -f2-)
    
    focus on "$task_name"
    
    # Mark task as in progress
    todoist update "$task_id" --content "🎯 $task_name"
}

# Complete task and end focus
todoist_complete() {
    local task_id="$1"
    local notes="$2"
    
    echo "$notes" | focus off
    todoist close "$task_id"
}
```

#### GitHub Issues Integration
```bash
# Work on GitHub issue
gh_focus() {
    local issue_number="$1"
    local repo="$2"
    
    # Get issue title (requires GitHub CLI)
    local issue_title
    issue_title=$(gh issue view "$issue_number" --repo "$repo" --json title --jq '.title')
    
    focus on "issue-$issue_number-$(echo "$issue_title" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
}

# Close issue with focus session notes
gh_close_with_notes() {
    local issue_number="$1"
    local repo="$2"
    
    # Get current session notes
    local current_project
    current_project=$(sqlite3 ~/.local/refocus/refocus.db \
        "SELECT project FROM state WHERE active = 1;" 2>/dev/null)
    
    if [[ "$current_project" =~ issue-$issue_number ]]; then
        local notes
        notes=$(sqlite3 ~/.local/refocus/refocus.db \
            "SELECT notes FROM sessions WHERE project = '$current_project' ORDER BY id DESC LIMIT 1;" 2>/dev/null)
        
        if [[ -n "$notes" ]]; then
            gh issue close "$issue_number" --repo "$repo" --comment "Work completed: $notes"
        fi
        
        focus off
    fi
}
```

### Time Tracking Integration

#### Export to Other Formats
```bash
# Export to CSV for external time tracking tools
export_to_csv() {
    local start_date="$1"
    local end_date="$2"
    local output_file="$3"
    
    sqlite3 ~/.local/refocus/refocus.db -header -csv \
        "SELECT 
            project,
            start_time,
            end_time,
            duration_seconds/3600.0 as hours,
            notes
         FROM sessions 
         WHERE date(start_time) BETWEEN '$start_date' AND '$end_date'
         ORDER BY start_time;" > "$output_file"
    
    echo "✅ Exported to $output_file"
}

# Usage: export_to_csv "2025-09-01" "2025-09-30" "september_timesheet.csv"
```

#### Toggl Integration
```bash
# Convert refocus sessions to Toggl format
export_to_toggl() {
    local project_mapping="$1"  # File mapping refocus projects to Toggl projects
    
    sqlite3 ~/.local/refocus/refocus.db \
        "SELECT 
            project,
            datetime(start_time, 'utc') as start_utc,
            datetime(end_time, 'utc') as end_utc,
            notes
         FROM sessions 
         WHERE start_time IS NOT NULL AND end_time IS NOT NULL;" | \
    while IFS='|' read -r project start_utc end_utc notes; do
        # Map project name if mapping file exists
        if [[ -f "$project_mapping" ]]; then
            toggl_project=$(grep "^$project:" "$project_mapping" | cut -d':' -f2)
            project="${toggl_project:-$project}"
        fi
        
        # Create Toggl time entry (requires Toggl CLI)
        toggl create \
            --project "$project" \
            --start "$start_utc" \
            --stop "$end_utc" \
            --description "$notes"
    done
}
```

## Advanced Data Analysis

### Custom Reporting Scripts

#### Productivity Analytics
```bash
#!/bin/bash
# productivity_analysis.sh

analyze_productivity() {
    local db="$HOME/.local/refocus/refocus.db"
    local days="${1:-30}"
    
    echo "📊 Productivity Analysis (Last $days days)"
    echo "=" $(printf "%*s" ${#days} | tr ' ' '=')
    echo
    
    # Daily averages
    echo "📈 Daily Averages:"
    sqlite3 "$db" "
        SELECT 
            ROUND(AVG(daily_hours), 2) as avg_daily_hours,
            ROUND(AVG(daily_sessions), 1) as avg_daily_sessions
        FROM (
            SELECT 
                DATE(end_time) as day,
                SUM(duration_seconds)/3600.0 as daily_hours,
                COUNT(*) as daily_sessions
            FROM sessions 
            WHERE end_time >= date('now', '-$days days')
            GROUP BY DATE(end_time)
        );"
    
    # Most productive hours
    echo
    echo "⏰ Most Productive Hours:"
    sqlite3 "$db" "
        SELECT 
            strftime('%H', start_time) as hour,
            COUNT(*) as sessions,
            ROUND(SUM(duration_seconds)/3600.0, 2) as total_hours
        FROM sessions 
        WHERE start_time >= datetime('now', '-$days days')
        GROUP BY strftime('%H', start_time)
        ORDER BY total_hours DESC
        LIMIT 5;"
    
    # Project focus patterns
    echo
    echo "🎯 Focus Patterns by Project:"
    sqlite3 "$db" "
        SELECT 
            project,
            COUNT(*) as sessions,
            ROUND(AVG(duration_seconds)/60.0, 1) as avg_session_mins,
            ROUND(SUM(duration_seconds)/3600.0, 2) as total_hours
        FROM sessions 
        WHERE start_time >= datetime('now', '-$days days')
        GROUP BY project
        ORDER BY total_hours DESC;"
    
    # Session length distribution
    echo
    echo "📊 Session Length Distribution:"
    sqlite3 "$db" "
        SELECT 
            CASE 
                WHEN duration_seconds < 1800 THEN '< 30 min'
                WHEN duration_seconds < 3600 THEN '30-60 min'
                WHEN duration_seconds < 7200 THEN '1-2 hours'
                WHEN duration_seconds < 14400 THEN '2-4 hours'
                ELSE '> 4 hours'
            END as duration_range,
            COUNT(*) as session_count,
            ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sessions WHERE start_time >= datetime('now', '-$days days')), 1) as percentage
        FROM sessions 
        WHERE start_time >= datetime('now', '-$days days')
        GROUP BY duration_range
        ORDER BY 
            CASE duration_range
                WHEN '< 30 min' THEN 1
                WHEN '30-60 min' THEN 2
                WHEN '1-2 hours' THEN 3
                WHEN '2-4 hours' THEN 4
                ELSE 5
            END;"
}

# Usage: analyze_productivity 30
```

#### Focus Streak Tracking
```bash
#!/bin/bash
# focus_streaks.sh

calculate_streaks() {
    local db="$HOME/.local/refocus/refocus.db"
    
    echo "🔥 Focus Streak Analysis"
    echo "======================"
    echo
    
    # Current streak
    local current_streak
    current_streak=$(sqlite3 "$db" "
        WITH daily_focus AS (
            SELECT DISTINCT DATE(end_time) as focus_date
            FROM sessions 
            WHERE end_time IS NOT NULL
            ORDER BY focus_date DESC
        ),
        streak_calc AS (
            SELECT 
                focus_date,
                ROW_NUMBER() OVER (ORDER BY focus_date DESC) as row_num,
                DATE('now', '-' || (ROW_NUMBER() OVER (ORDER BY focus_date DESC) - 1) || ' days') as expected_date
            FROM daily_focus
        )
        SELECT COUNT(*) 
        FROM streak_calc 
        WHERE focus_date = expected_date;")
    
    echo "🎯 Current streak: $current_streak days"
    
    # Longest streak
    echo
    echo "📈 Streak History (Top 10):"
    sqlite3 "$db" "
        WITH daily_focus AS (
            SELECT DISTINCT DATE(end_time) as focus_date
            FROM sessions 
            WHERE end_time IS NOT NULL
            ORDER BY focus_date
        ),
        streak_groups AS (
            SELECT 
                focus_date,
                DATE(focus_date, '-' || (ROW_NUMBER() OVER (ORDER BY focus_date) - 1) || ' days') as streak_group
            FROM daily_focus
        ),
        streak_lengths AS (
            SELECT 
                streak_group,
                COUNT(*) as streak_length,
                MIN(focus_date) as streak_start,
                MAX(focus_date) as streak_end
            FROM streak_groups
            GROUP BY streak_group
        )
        SELECT 
            streak_length || ' days' as length,
            streak_start,
            streak_end
        FROM streak_lengths
        ORDER BY streak_length DESC
        LIMIT 10;"
}
```

### Performance Monitoring

#### System Resource Usage
```bash
# Monitor refocus shell performance
monitor_refocus_performance() {
    echo "🔍 Refocus Shell Performance Monitor"
    echo "==================================="
    echo
    
    # Database size
    local db_size
    db_size=$(du -h ~/.local/refocus/refocus.db | cut -f1)
    echo "📁 Database size: $db_size"
    
    # Session count
    local session_count
    session_count=$(sqlite3 ~/.local/refocus/refocus.db "SELECT COUNT(*) FROM sessions;")
    echo "📊 Total sessions: $session_count"
    
    # Command execution times
    echo
    echo "⏱️  Command Performance:"
    time focus status >/dev/null 2>&1
    time focus past list 10 >/dev/null 2>&1
    time focus report today >/dev/null 2>&1
    
    # Database integrity
    echo
    echo "🔍 Database Health:"
    local integrity_check
    integrity_check=$(sqlite3 ~/.local/refocus/refocus.db "PRAGMA integrity_check;")
    if [[ "$integrity_check" == "ok" ]]; then
        echo "✅ Database integrity: OK"
    else
        echo "❌ Database integrity: $integrity_check"
    fi
    
    # Disk usage breakdown
    echo
    echo "💾 Disk Usage:"
    du -sh ~/.local/refocus/* 2>/dev/null | sort -hr
}
```

## Advanced Session Techniques

### Session Templates

#### Creating Reusable Templates
```bash
# Session template system
create_session_template() {
    local template_name="$1"
    local project="$2"
    local duration="$3"
    local notes="$4"
    
    local template_file="$HOME/.local/refocus/templates/$template_name.template"
    mkdir -p "$(dirname "$template_file")"
    
    cat > "$template_file" << EOF
PROJECT="$project"
DURATION="$duration"
NOTES="$notes"
EOF
    
    echo "✅ Template '$template_name' created"
}

use_session_template() {
    local template_name="$1"
    local template_file="$HOME/.local/refocus/templates/$template_name.template"
    
    if [[ -f "$template_file" ]]; then
        source "$template_file"
        
        echo "🎯 Starting template session: $PROJECT"
        focus on "$PROJECT"
        
        # If duration specified, set a reminder
        if [[ -n "$DURATION" ]]; then
            local duration_seconds
            duration_seconds=$(echo "$DURATION" | sed 's/h/*3600+/g; s/m/*60+/g; s/+$//' | bc)
            
            # Set reminder (background process)
            (
                sleep "$duration_seconds"
                notify-send "Template Session" "Planned duration ($DURATION) reached for $PROJECT"
            ) &
        fi
        
        # Pre-fill notes if specified
        if [[ -n "$NOTES" ]]; then
            echo "📝 Template notes: $NOTES"
        fi
    else
        echo "❌ Template '$template_name' not found"
        list_session_templates
    fi
}

list_session_templates() {
    echo "📋 Available templates:"
    find "$HOME/.local/refocus/templates" -name "*.template" -exec basename {} .template \; 2>/dev/null | sort
}

# Usage:
# create_session_template "daily-standup" "meetings" "30m" "Daily team standup meeting"
# use_session_template "daily-standup"
```

### Batch Operations

#### Bulk Session Management
```bash
# Bulk import sessions from CSV
bulk_import_sessions() {
    local csv_file="$1"
    
    if [[ ! -f "$csv_file" ]]; then
        echo "❌ CSV file not found: $csv_file"
        return 1
    fi
    
    echo "📥 Importing sessions from $csv_file..."
    
    # Skip header row, process each line
    tail -n +2 "$csv_file" | while IFS=, read -r project start_time end_time notes; do
        # Remove quotes if present
        project=$(echo "$project" | sed 's/^"//; s/"$//')
        start_time=$(echo "$start_time" | sed 's/^"//; s/"$//')
        end_time=$(echo "$end_time" | sed 's/^"//; s/"$//')
        notes=$(echo "$notes" | sed 's/^"//; s/"$//')
        
        if [[ -n "$notes" ]]; then
            focus past add "$project" "$start_time" "$end_time" --notes "$notes"
        else
            focus past add "$project" "$start_time" "$end_time"
        fi
        
        echo "✅ Imported: $project ($start_time - $end_time)"
    done
    
    echo "📊 Import completed"
}

# Export sessions to CSV format
bulk_export_sessions() {
    local start_date="$1"
    local end_date="$2"
    local output_file="$3"
    
    echo "project,start_time,end_time,duration_minutes,notes" > "$output_file"
    
    sqlite3 ~/.local/refocus/refocus.db -separator ',' \
        "SELECT 
            '\"' || project || '\"',
            '\"' || COALESCE(start_time, '') || '\"',
            '\"' || COALESCE(end_time, '') || '\"',
            duration_seconds / 60,
            '\"' || COALESCE(notes, '') || '\"'
         FROM sessions 
         WHERE (start_time IS NULL OR DATE(start_time) BETWEEN '$start_date' AND '$end_date')
           AND (session_date IS NULL OR session_date BETWEEN '$start_date' AND '$end_date')
         ORDER BY COALESCE(start_time, session_date);" >> "$output_file"
    
    echo "✅ Exported to $output_file"
}
```

### Custom Notification Systems

#### Advanced Notification Handlers
```bash
# Custom notification system with multiple channels
send_advanced_notification() {
    local title="$1"
    local message="$2"
    local priority="${3:-normal}"  # low, normal, high, critical
    
    case "$priority" in
        "critical")
            # Multiple notification methods for critical alerts
            notify-send -u critical -t 0 "$title" "$message"
            echo -e "\a\a\a"  # System bell
            zenity --warning --text="$title: $message" &
            ;;
        "high")
            notify-send -u critical "$title" "$message"
            echo -e "\a"
            ;;
        "normal")
            notify-send "$title" "$message"
            ;;
        "low")
            notify-send -u low "$title" "$message"
            ;;
    esac
    
    # Log all notifications
    echo "$(date): [$priority] $title - $message" >> ~/.local/refocus/notifications.log
}

# Smart nudging based on activity patterns
smart_nudge_system() {
    local current_project
    current_project=$(sqlite3 ~/.local/refocus/refocus.db \
        "SELECT project FROM state WHERE active = 1;" 2>/dev/null)
    
    if [[ -n "$current_project" ]]; then
        # Calculate session length
        local start_time
        start_time=$(sqlite3 ~/.local/refocus/refocus.db \
            "SELECT start_time FROM state WHERE active = 1;" 2>/dev/null)
        
        local now=$(date +%s)
        local start_ts=$(date --date="$start_time" +%s 2>/dev/null)
        local elapsed_minutes=$(( (now - start_ts) / 60 ))
        
        # Adaptive nudging based on session length
        local priority="normal"
        local message="You're focusing on: $current_project (${elapsed_minutes}m elapsed)"
        
        if [[ $elapsed_minutes -gt 120 ]]; then
            priority="high"
            message="Long session detected! Consider taking a break. $message"
        elif [[ $elapsed_minutes -gt 240 ]]; then
            priority="critical"
            message="Very long session! Please take a break for your health. $message"
        fi
        
        send_advanced_notification "Focus Reminder" "$message" "$priority"
    fi
}
```

## System Administration

### Multi-User Environments

#### Shared System Configuration
```bash
# System-wide installation script
install_refocus_systemwide() {
    # Install to system directories
    sudo cp focus /usr/local/bin/
    sudo cp focus-nudge /usr/local/bin/
    sudo cp -r commands/ /usr/local/share/refocus/
    sudo cp -r lib/ /usr/local/share/refocus/
    
    # Create system configuration
    sudo mkdir -p /etc/refocus
    sudo cat > /etc/refocus/config.sh << 'EOF'
# System-wide Refocus Shell configuration
export REFOCUS_SYSTEM_INSTALL=true
export REFOCUS_LIB_DIR="/usr/local/share/refocus/lib"
export REFOCUS_COMMANDS_DIR="/usr/local/share/refocus/commands"
EOF
    
    echo "✅ System-wide installation completed"
    echo "Users can now add to their ~/.bashrc:"
    echo "source /usr/local/share/refocus/lib/focus-function.sh"
}
```

#### User Data Isolation
```bash
# Ensure user data isolation in shared environments
setup_user_isolation() {
    # Strict permissions on user data
    chmod 700 ~/.local/refocus
    chmod 600 ~/.local/refocus/refocus.db
    
    # User-specific configuration
    mkdir -p ~/.config/refocus-shell
    cat > ~/.config/refocus-shell/config.sh << EOF
# User-specific configuration
export REFOCUS_DB="$HOME/.local/refocus/refocus.db"
export REFOCUS_BACKUP_DIR="$HOME/.local/refocus/backups"
export REFOCUS_USER_CONFIG="$HOME/.config/refocus-shell"
EOF
    
    chmod 600 ~/.config/refocus-shell/config.sh
}
```

### Enterprise Integration

#### LDAP/AD Integration
```bash
# Enterprise user identification
get_enterprise_user() {
    # Try various methods to get enterprise username
    local enterprise_user
    
    # LDAP
    if command -v ldapwhoami >/dev/null; then
        enterprise_user=$(ldapwhoami | cut -d'=' -f2)
    # AD
    elif [[ -n "$USERDNSDOMAIN" ]]; then
        enterprise_user="$USERNAME@$USERDNSDOMAIN"
    # Kerberos
    elif command -v klist >/dev/null; then
        enterprise_user=$(klist | grep "Default principal:" | cut -d' ' -f3)
    else
        enterprise_user="$USER"
    fi
    
    echo "$enterprise_user"
}

# Corporate reporting
generate_corporate_report() {
    local period="$1"
    local user
    user=$(get_enterprise_user)
    
    # Generate sanitized report for corporate use
    focus report "$period" > "corporate-timesheet-$user-$(date +%Y%m%d).md"
    
    # Remove personal projects, keep work-related ones
    sed -i '/personal-/d; /hobby-/d' "corporate-timesheet-$user-$(date +%Y%m%d).md"
    
    echo "✅ Corporate timesheet generated: corporate-timesheet-$user-$(date +%Y%m%d).md"
}
```

---

*Next: [Installation Guide](installation.md)*
