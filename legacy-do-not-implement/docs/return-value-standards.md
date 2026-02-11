# Return Value Standards

This document defines the standardized return value patterns for functions in Refocus Shell to ensure consistent error handling, data flow, and user experience across the codebase.

## Core Return Value Principles

### 1. Consistent Exit Codes
- Use standardized numerical exit codes across all functions
- Provide clear meaning for each exit code
- Enable proper error handling and debugging

### 2. Clear Data Flow
- Return data to stdout on success
- Return error messages to stderr on failure
- Use return codes to indicate success/failure status

### 3. Predictable Behavior
- Functions should behave consistently across the codebase
- Return values should be predictable and well-documented
- Error conditions should be clearly defined

## Standardized Exit Codes

### 1. Success Codes
- **0**: Success - Operation completed successfully

### 2. Error Codes
- **1**: General error - Unspecified error occurred
- **2**: Invalid arguments - Parameter validation failed
- **3**: State error - Application state is invalid
- **4**: Database error - Database operation failed
- **5**: File system error - Disk space, I/O, or file system issues
- **6**: Permission error - Access denied or permission issues
- **7**: Configuration error - Configuration is invalid or missing

### 3. Specialized Error Codes
- **8**: Network error - Network-related issues (if applicable)
- **9**: Timeout error - Operation timed out
- **10**: Resource error - Resource unavailable or exhausted

## Return Value Patterns

### 1. Validation Functions
```bash
# Pattern: Return 0 for valid, 1 for invalid
function validate_input() {
    local input="$1"
    
    if [[ -z "$input" ]]; then
        echo "❌ Input is required" >&2
        return 1
    fi
    
    # Additional validation...
    
    return 0
}
```

### 2. Data Retrieval Functions
```bash
# Pattern: Return data to stdout, use return codes for status
function get_data() {
    local id="$1"
    
    # Validate input
    if ! validate_numeric_input "$id"; then
        return 1
    fi
    
    # Get data
    local result
    result=$(execute_sqlite "SELECT * FROM table WHERE id = $id;" "get_data")
    
    if [[ $? -eq 0 ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}
```

### 3. Data Modification Functions
```bash
# Pattern: Return 0 for success, specific codes for different errors
function modify_data() {
    local id="$1"
    local data="$2"
    
    # Validate input
    if ! validate_numeric_input "$id"; then
        return 2  # Invalid arguments
    fi
    
    if ! validate_data_format "$data"; then
        return 2  # Invalid arguments
    fi
    
    # Modify data
    execute_sqlite "UPDATE table SET data = '$data' WHERE id = $id;" "modify_data"
    
    if [[ $? -eq 0 ]]; then
        return 0  # Success
    else
        return 4  # Database error
    fi
}
```

### 4. Command Functions
```bash
# Pattern: Use exit codes for command termination
function focus_command() {
    local param="$1"
    
    # Validate parameters
    if [[ -z "$param" ]]; then
        handle_argument_error "missing_param" \
            "focus command <param>" \
            "focus command value"
        exit 2  # Invalid arguments
    fi
    
    # Check application state
    if ! is_focus_enabled; then
        handle_state_error "disabled"
        exit 7  # State error
    fi
    
    # Execute command logic
    if execute_command_logic "$param"; then
        echo "✅ Command completed successfully"
        exit 0  # Success
    else
        echo "❌ Command failed" >&2
        exit 1  # General error
    fi
}
```

## Data Return Patterns

### 1. Single Value Return
```bash
# Pattern: Return single value to stdout
function get_single_value() {
    local id="$1"
    
    # Validation and logic...
    
    echo "$value"
    return 0
}

# Usage:
value=$(get_single_value "123")
if [[ $? -eq 0 ]]; then
    echo "Got value: $value"
fi
```

### 2. Multiple Value Return
```bash
# Pattern: Return multiple values in structured format
function get_multiple_values() {
    local id="$1"
    
    # Validation and logic...
    
    echo "$value1|$value2|$value3"
    return 0
}

# Usage:
result=$(get_multiple_values "123")
if [[ $? -eq 0 ]]; then
    IFS='|' read -r val1 val2 val3 <<< "$result"
    echo "Values: $val1, $val2, $val3"
fi
```

### 3. Structured Data Return
```bash
# Pattern: Return structured data (JSON-like format)
function get_structured_data() {
    local id="$1"
    
    # Validation and logic...
    
    echo "id:$id|name:$name|status:$status"
    return 0
}

# Usage:
data=$(get_structured_data "123")
if [[ $? -eq 0 ]]; then
    # Parse structured data
    local id name status
    IFS='|' read -r id_part name_part status_part <<< "$data"
    id="${id_part#id:}"
    name="${name_part#name:}"
    status="${status_part#status:}"
fi
```

## Error Handling Patterns

### 1. Validation Errors
```bash
# Pattern: Return 1 for validation failures
function validate_parameter() {
    local param="$1"
    
    if [[ -z "$param" ]]; then
        echo "❌ Parameter is required" >&2
        return 1
    fi
    
    if ! [[ "$param" =~ ^[0-9]+$ ]]; then
        echo "❌ Parameter must be numeric" >&2
        return 1
    fi
    
    return 0
}
```

### 2. Database Errors
```bash
# Pattern: Return specific codes for different database errors
function database_operation() {
    local sql="$1"
    
    # Execute SQL
    local result
    result=$(execute_sqlite "$sql" "database_operation")
    local exit_code=$?
    
    case $exit_code in
        0)
            echo "$result"
            return 0
            ;;
        1)
            echo "❌ Database error occurred" >&2
            return 4
            ;;
        2)
            echo "❌ Invalid SQL syntax" >&2
            return 2
            ;;
        5)
            echo "❌ Disk space error" >&2
            return 5
            ;;
        6)
            echo "❌ Permission denied" >&2
            return 6
            ;;
        *)
            echo "❌ Unknown database error" >&2
            return 1
            ;;
    esac
}
```

### 3. State Errors
```bash
# Pattern: Use exit codes for state errors
function check_application_state() {
    if ! is_focus_enabled; then
        handle_state_error "disabled"
        exit 7
    fi
    
    if is_focus_active; then
        handle_state_error "already_active"
        exit 7
    fi
    
    return 0
}
```

## Function-Specific Return Patterns

### 1. Validation Functions
```bash
# Pattern: Return 0 for valid, 1 for invalid
validate_project_name() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required" >&2
        return 1
    fi
    
    # Additional validation...
    
    return 0
}
```

### 2. Sanitization Functions
```bash
# Pattern: Return sanitized data to stdout
sanitize_project_name() {
    local project="$1"
    
    # Sanitize input
    project=$(echo "$project" | tr -d '\r\n\t')
    project=$(echo "$project" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    echo "$project"
    return 0
}
```

### 3. Database Functions
```bash
# Pattern: Return data to stdout, use return codes for status
get_session_by_id() {
    local session_id="$1"
    
    # Validate input
    if ! validate_numeric_input "$session_id" "Session ID" 1; then
        return 1
    fi
    
    # Get session data
    local result
    result=$(execute_sqlite "SELECT * FROM sessions WHERE rowid = $session_id;" "get_session_by_id")
    
    if [[ $? -eq 0 ]]; then
        echo "$result"
        return 0
    else
        return 1
    fi
}
```

### 4. Utility Functions
```bash
# Pattern: Return calculated data to stdout
calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    # Validate inputs
    if [[ -z "$start_time" ]] || [[ -z "$end_time" ]]; then
        echo "❌ Both start and end times are required" >&2
        return 1
    fi
    
    # Calculate duration
    local start_ts end_ts duration
    start_ts=$(date --date="$start_time" +%s)
    end_ts=$(date --date="$end_time" +%s)
    duration=$((end_ts - start_ts))
    
    echo "$duration"
    return 0
}
```

## Error Message Standards

### 1. Error Message Format
```bash
# Standard format: ❌ <context> <issue> [details]
echo "❌ Project name is required" >&2
echo "❌ Invalid session ID: $session_id (must be numeric)" >&2
echo "❌ Database connection failed: $error_details" >&2
```

### 2. Context Information
```bash
# Include context when helpful
echo "❌ Invalid $field_name: $value" >&2
echo "❌ $context name is required" >&2
echo "❌ $description path is required" >&2
```

### 3. Helpful Details
```bash
# Provide helpful details and examples
echo "❌ Invalid date format: $date" >&2
echo "   Use format: YYYY/MM/DD-HH:MM" >&2
echo "   Examples: 2025/01/15-14:30, 14:30, today" >&2
```

## Implementation Guidelines

### 1. Return Value Documentation
- Document all possible return values
- Explain what each return code means
- Provide examples of usage

### 2. Error Handling
- Use standardized error messages
- Include helpful context and details
- Redirect error messages to stderr

### 3. Data Flow
- Return data to stdout on success
- Use return codes to indicate status
- Maintain consistent patterns across functions

## Quality Checklist

Before considering return value handling complete, verify:

- [ ] All return codes are documented
- [ ] Error messages are standardized
- [ ] Data is returned to appropriate streams
- [ ] Return codes are consistent across similar functions
- [ ] Error handling is comprehensive
- [ ] Examples are provided
- [ ] Documentation is complete

## Tools and Automation

### 1. Return Value Testing
- Create test cases for all return scenarios
- Test error conditions and edge cases
- Verify return code consistency

### 2. Documentation Generation
- Generate return value documentation
- Create return pattern examples
- Validate documentation completeness

This standard ensures that all functions in Refocus Shell have consistent, predictable return value patterns that enable proper error handling and data flow throughout the application.
