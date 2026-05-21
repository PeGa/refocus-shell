# Centralized Validation and Error Handling

This document describes the centralized validation, error handling, and output formatting patterns implemented in Refocus Shell to eliminate code duplication and improve maintainability.

## Overview

The centralized validation system provides:
- **Consistent validation logic** across all commands
- **Standardized error messages** with proper formatting
- **Unified output formatting** for success, error, warning, and info messages
- **Centralized database operations** with error handling
- **Reusable validation functions** for common patterns

## Core Files

### `lib/focus-validation-centralized.sh`
Contains all centralized validation, error handling, and output formatting functions.

## Validation Functions

### `validate_required_args(command_name, usage, examples, ...args)`
Validates that all required arguments are provided with standardized error messages.

```bash
# Example usage
if ! validate_required_args "focus past add" \
    "focus past add <project> <start_time> <end_time>" \
    "focus past add meeting 2025/07/30-14:15 2025/07/30-15:30" \
    "$project" "$start_time" "$end_time"; then
    exit 2
fi
```

### `validate_project_name_standardized(project, context)`
Validates and sanitizes project names with standardized error handling.

```bash
# Example usage
project=$(validate_project_name_standardized "$project" "Project")
if [[ $? -ne 0 ]]; then
    exit 2
fi
```

### `validate_numeric_input_standardized(value, field_name, min_value, max_value)`
Validates numeric input with range checking and standardized error messages.

```bash
# Example usage
if ! validate_numeric_input_standardized "$limit" "Limit" 1 1000; then
    exit 2
fi
```

### `validate_timestamp_standardized(timestamp, field_name)`
Validates timestamps with standardized error handling and conversion.

```bash
# Example usage
converted_time=$(validate_timestamp_standardized "$start_time" "Start time")
if [[ $? -ne 0 ]]; then
    echo "$converted_time"
    exit 2
fi
```

### `validate_duration_standardized(duration, field_name)`
Validates duration strings with standardized error handling and conversion.

```bash
# Example usage
duration_seconds=$(validate_duration_standardized "$duration" "Duration")
if [[ $? -ne 0 ]]; then
    exit 2
fi
```

### `validate_file_exists(file_path, file_type)`
Validates file existence with standardized error messages.

```bash
# Example usage
if ! validate_file_exists "$input_file" "Input file"; then
    exit 1
fi
```

### `validate_directory_exists(dir_path, dir_type)`
Validates directory existence with standardized error messages.

```bash
# Example usage
if ! validate_directory_exists "$backup_dir" "Backup directory"; then
    exit 1
fi
```

## Error Handling Functions

### `handle_state_error(error_type, context)`
Handles application state errors with standardized messages and exit codes.

```bash
# Example usage
if is_focus_disabled; then
    handle_state_error "disabled"
fi

if [[ "$paused" -eq 1 ]]; then
    handle_state_error "session_paused" "$current_project"
fi
```

**Supported error types:**
- `disabled` - Refocus shell is disabled
- `already_active` - Focus session already active
- `session_paused` - Session is paused
- `no_active_session` - No active session

### `handle_argument_error(error_type, usage, examples, notes)`
Handles argument validation errors with standardized messages and exit codes.

```bash
# Example usage
if [[ -z "$project" ]]; then
    handle_argument_error "missing_project" \
        "focus past add <project> <start_time> <end_time>" \
        "focus past add meeting 2025/07/30-14:15 2025/07/30-15:30" \
        "Project name is required"
fi
```

**Supported error types:**
- `missing_project` - Project name is required
- `missing_duration` - Duration is required
- `missing_date` - Date is required
- `missing_start_time` - Start time is required
- `missing_end_time` - End time is required
- `invalid_option` - Unknown option
- `missing_session_id` - Session ID is required

### `handle_database_error(error_type, context)`
Handles database errors with standardized messages and exit codes.

```bash
# Example usage
if [[ -z "$session_data" ]]; then
    handle_database_error "session_not_found"
fi
```

**Supported error types:**
- `session_not_found` - Session not found
- `project_not_found` - Project not found
- `database_error` - General database error

## Output Formatting Functions

### `format_success_message(message, details)`
Formats success messages consistently.

```bash
# Example usage
format_success_message "Added session: $project" \
    "Duration: $(format_duration "$duration_seconds")
Notes: ${notes:-'none'}"
```

### `format_error_message(message, details)`
Formats error messages consistently.

```bash
# Example usage
format_error_message "REFOCUS_DB_PATH is not set"
```

### `format_warning_message(message, details)`
Formats warning messages consistently.

```bash
# Example usage
format_warning_message "Database does not exist: $REFOCUS_DB_PATH"
```

### `format_info_message(message, details)`
Formats info messages consistently.

```bash
# Example usage
format_info_message "No focus sessions found."
```

### `format_duration(duration_seconds, format)`
Formats duration consistently.

```bash
# Example usage
local duration_formatted
duration_formatted=$(format_duration "$duration_seconds" "short")
# Output: "2h 30m" or "45m"

duration_formatted=$(format_duration "$duration_seconds" "minutes_only")
# Output: "150m"
```

**Supported formats:**
- `short` - "2h 30m" or "45m"
- `long` - "2 hours 30 minutes"
- `minutes_only` - "150m"

### `format_timestamp(timestamp, format)`
Formats timestamps consistently.

```bash
# Example usage
local formatted_time
formatted_time=$(format_timestamp "$timestamp" "default")
# Output: "2025-09-27 14:30"

formatted_time=$(format_timestamp "$timestamp" "date_only")
# Output: "2025-09-27"
```

**Supported formats:**
- `default` - "2025-09-27 14:30"
- `date_only` - "2025-09-27"
- `time_only` - "14:30"
- `iso` - "2025-09-27T14:30:00"

### `format_table_header(headers...)`
Formats table headers consistently.

```bash
# Example usage
format_table_header "ID" "Project" "Start" "End" "Duration" "Type"
```

## Database Operation Functions

### `get_session_by_id(session_id)`
Gets session data by ID with standardized error handling.

```bash
# Example usage
local session_data
session_data=$(get_session_by_id "$session_id")
if [[ $? -ne 0 ]]; then
    handle_database_error "session_not_found"
fi
```

### `get_project_sessions(project, limit)`
Gets sessions for a specific project with standardized error handling.

```bash
# Example usage
local sessions
sessions=$(get_project_sessions "$project" 20)
```

### `get_recent_sessions(limit)`
Gets recent sessions with standardized error handling.

```bash
# Example usage
local sessions
sessions=$(get_recent_sessions 20)
```

### `get_session_count(project)`
Gets session count with standardized error handling.

```bash
# Example usage
local count
count=$(get_session_count "$project")
```

### `get_total_project_time(project)`
Gets total time for a project with standardized error handling.

```bash
# Example usage
local total_time
total_time=$(get_total_project_time "$project")
```

## Usage and Help Functions

### `generate_usage_message(command, usage, examples, notes)`
Generates standardized usage messages.

```bash
# Example usage
generate_usage_message "focus past add" \
    "focus past add <project> <start_time> <end_time>" \
    "focus past add meeting 2025/07/30-14:15 2025/07/30-15:30" \
    "Project name is required"
```

### `generate_help_section(title, commands)`
Generates standardized help sections.

```bash
# Example usage
generate_help_section "Session Commands" \
    "  focus on <project>     - Start focus session
  focus off              - Stop focus session
  focus pause            - Pause focus session"
```

## Integration Guidelines

### 1. Source the Centralized Functions
Add this to the top of your command file:

```bash
# Source centralized validation functions
source "$SCRIPT_DIR/../lib/focus-validation-centralized.sh"
```

### 2. Replace Manual Validation
Replace manual validation with centralized functions:

```bash
# Old way
if [[ -z "$project" ]]; then
    echo "❌ Project name is required."
    echo "Usage: focus past add <project> <start_time> <end_time>"
    exit 2
fi

# New way
if [[ -z "$project" ]]; then
    handle_argument_error "missing_project" \
        "focus past add <project> <start_time> <end_time>" \
        "focus past add meeting 2025/07/30-14:15 2025/07/30-15:30"
fi
```

### 3. Use Centralized Output Formatting
Replace manual output formatting with centralized functions:

```bash
# Old way
echo "✅ Added session: $project"
echo "   Duration: $((duration / 60)) minutes"

# New way
format_success_message "Added session: $project" \
    "Duration: $(format_duration "$duration")"
```

### 4. Use Centralized Database Operations
Replace manual database queries with centralized functions:

```bash
# Old way
local sessions
sessions=$(execute_sqlite "SELECT rowid, project, start_time, end_time, duration_seconds, notes FROM $SESSIONS_TABLE WHERE project != '[idle]' ORDER BY rowid DESC LIMIT $limit;" "focus_past_list")

# New way
local sessions
sessions=$(get_recent_sessions "$limit")
```

## Benefits

1. **Consistency**: All commands use the same validation and error handling patterns
2. **Maintainability**: Changes to validation logic only need to be made in one place
3. **Reduced Duplication**: Eliminates repetitive validation code across commands
4. **Standardized Output**: Consistent formatting and messaging across all commands
5. **Error Handling**: Centralized error handling with proper exit codes
6. **Documentation**: Self-documenting code with clear function names and purposes

## Testing

All centralized functions have been tested with:
- Valid input scenarios
- Invalid input scenarios
- Edge cases and boundary conditions
- Error handling and recovery
- Output formatting consistency

## Future Enhancements

- Additional validation functions for specific data types
- More sophisticated error recovery mechanisms
- Enhanced output formatting options
- Performance optimizations for database operations
- Additional database operation functions as needed
