# Parameter Validation Standards

This document defines the standardized parameter validation patterns for functions in Refocus Shell to ensure consistent input validation, error handling, and user experience across the codebase.

## Core Validation Principles

### 1. Fail Fast
- Validate parameters as early as possible
- Provide immediate feedback on invalid input
- Prevent invalid data from propagating through the system

### 2. Consistent Error Messages
- Use standardized error message formats
- Include helpful context and examples
- Provide clear guidance on correct usage

### 3. Comprehensive Validation
- Check all required parameters
- Validate parameter types and formats
- Enforce business rules and constraints

## Validation Patterns

### 1. Required Parameter Validation
```bash
# Pattern: Check for empty or undefined parameters
if [[ -z "$parameter" ]]; then
    echo "❌ Parameter name is required" >&2
    return 1
fi
```

### 2. Type Validation
```bash
# Pattern: Validate parameter types
# Numeric validation
if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "❌ Parameter must be a positive integer" >&2
    return 1
fi

# String validation
if [[ "$string" =~ [[:cntrl:]] ]]; then
    echo "❌ Parameter contains invalid characters" >&2
    return 1
fi
```

### 3. Range Validation
```bash
# Pattern: Validate parameter ranges
if [[ "$value" -lt "$min_value" ]]; then
    echo "❌ Parameter must be at least $min_value" >&2
    return 1
fi

if [[ "$value" -gt "$max_value" ]]; then
    echo "❌ Parameter cannot exceed $max_value" >&2
    return 1
fi
```

### 4. Format Validation
```bash
# Pattern: Validate parameter formats
if ! [[ "$date" =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}$ ]]; then
    echo "❌ Invalid date format: $date" >&2
    echo "   Use format: YYYY/MM/DD" >&2
    return 1
fi
```

## Standardized Validation Functions

### 1. Required Arguments Validation
```bash
# Function: validate_required_args
# Description: Validates that all required arguments are provided
# Usage: validate_required_args <command_name> <usage> [examples] <arg1> <arg2> ...
validate_required_args() {
    local args=("$@")
    local command_name="${args[0]}"
    local usage="${args[1]}"
    local examples="${args[2]:-}"
    
    shift 3
    local missing_args=()
    
    for arg in "$@"; do
        if [[ -z "$arg" ]]; then
            missing_args+=("$arg")
        fi
    done
    
    if [[ ${#missing_args[@]} -gt 0 ]]; then
        echo "❌ Missing required arguments." >&2
        echo "Usage: $usage" >&2
        if [[ -n "$examples" ]]; then
            echo "" >&2
            echo "Examples:" >&2
            echo "$examples" >&2
        fi
        return 1
    fi
    
    return 0
}
```

### 2. Project Name Validation
```bash
# Function: validate_project_name_standardized
# Description: Validates and sanitizes project names
# Usage: validate_project_name_standardized <project_name> [context]
validate_project_name_standardized() {
    local project="$1"
    local context="${2:-project}"
    
    if [[ -z "$project" ]]; then
        echo "❌ $context name is required." >&2
        return 1
    fi
    
    # Sanitize project name
    project=$(sanitize_project_name "$project")
    
    # Validate project name
    if ! validate_project_name "$project"; then
        return 1
    fi
    
    echo "$project"
    return 0
}
```

### 3. Numeric Input Validation
```bash
# Function: validate_numeric_input_standardized
# Description: Validates numeric input with range checking
# Usage: validate_numeric_input_standardized <value> <field_name> [min_value] [max_value]
validate_numeric_input_standardized() {
    local value="$1"
    local field_name="${2:-Value}"
    local min_value="${3:-0}"
    local max_value="${4:-999999}"
    
    if [[ -z "$value" ]]; then
        echo "❌ $field_name is required." >&2
        return 1
    fi
    
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "❌ $field_name must be a positive integer." >&2
        return 1
    fi
    
    if [[ "$value" -lt "$min_value" ]]; then
        echo "❌ $field_name must be at least $min_value." >&2
        return 1
    fi
    
    if [[ "$value" -gt "$max_value" ]]; then
        echo "❌ $field_name must be no more than $max_value." >&2
        return 1
    fi
    
    return 0
}
```

### 4. Timestamp Validation
```bash
# Function: validate_timestamp_standardized
# Description: Validates timestamp format and converts to ISO format
# Usage: validate_timestamp_standardized <timestamp> [field_name]
validate_timestamp_standardized() {
    local timestamp="$1"
    local field_name="${2:-Timestamp}"
    
    if [[ -z "$timestamp" ]]; then
        echo "❌ $field_name is required." >&2
        return 1
    fi
    
    # Convert timestamp to ISO format
    local converted_timestamp
    converted_timestamp=$(validate_timestamp "$timestamp")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Invalid $field_name: $timestamp" >&2
        echo "$converted_timestamp" >&2
        return 1
    fi
    
    echo "$converted_timestamp"
    return 0
}
```

### 5. Duration Validation
```bash
# Function: validate_duration_standardized
# Description: Validates duration format and converts to seconds
# Usage: validate_duration_standardized <duration> [field_name]
validate_duration_standardized() {
    local duration="$1"
    local field_name="${2:-Duration}"
    
    if [[ -z "$duration" ]]; then
        echo "❌ $field_name is required." >&2
        return 1
    fi
    
    # Parse duration to seconds
    local duration_seconds
    duration_seconds=$(parse_duration "$duration")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        return 1
    fi
    
    echo "$duration_seconds"
    return 0
}
```

## Error Message Standards

### 1. Error Message Format
```bash
# Standard format: ❌ <context> <issue> [details]
echo "❌ Project name is required" >&2
echo "❌ Invalid session ID: $session_id (must be numeric)" >&2
echo "❌ Duration must be at least 1 minute" >&2
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

### 4. Usage Information
```bash
# Include usage syntax when appropriate
echo "❌ Missing required arguments." >&2
echo "Usage: $usage" >&2
echo "" >&2
echo "Examples:" >&2
echo "$examples" >&2
```

## Validation Patterns by Function Type

### 1. Command Functions
```bash
# Pattern: Validate all required parameters first
function focus_command() {
    local param1="$1"
    local param2="$2"
    local param3="$3"
    
    # Validate required parameters
    if [[ -z "$param1" ]]; then
        handle_argument_error "missing_param1" \
            "focus command <param1> <param2> [param3]" \
            "focus command value1 value2" \
            "param1 is required"
    fi
    
    if [[ -z "$param2" ]]; then
        handle_argument_error "missing_param2" \
            "focus command <param1> <param2> [param3]" \
            "focus command value1 value2" \
            "param2 is required"
    fi
    
    # Validate parameter types and formats
    param1=$(validate_project_name_standardized "$param1" "Parameter 1")
    if [[ $? -ne 0 ]]; then
        exit 2
    fi
    
    if ! validate_numeric_input_standardized "$param2" "Parameter 2" 1 1000; then
        exit 2
    fi
    
    # Optional parameter validation
    if [[ -n "$param3" ]]; then
        param3=$(validate_timestamp_standardized "$param3" "Parameter 3")
        if [[ $? -ne 0 ]]; then
            exit 2
        fi
    fi
    
    # Function implementation...
}
```

### 2. Database Functions
```bash
# Pattern: Validate parameters before database operations
function database_operation() {
    local session_id="$1"
    local project="$2"
    
    # Validate session ID
    if ! validate_numeric_input_standardized "$session_id" "Session ID" 1; then
        return 1
    fi
    
    # Validate project name
    project=$(validate_project_name_standardized "$project" "Project")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Database operation...
}
```

### 3. Utility Functions
```bash
# Pattern: Validate parameters and return appropriate values
function utility_function() {
    local input="$1"
    local format="$2"
    
    # Validate required parameters
    if [[ -z "$input" ]]; then
        echo "❌ Input is required" >&2
        return 1
    fi
    
    # Validate format parameter
    if [[ -n "$format" ]] && [[ "$format" != "short" ]] && [[ "$format" != "long" ]]; then
        echo "❌ Invalid format: $format (must be 'short' or 'long')" >&2
        return 1
    fi
    
    # Function implementation...
}
```

## Return Value Standards

### 1. Success/Failure Codes
- **0**: Success
- **1**: General error
- **2**: Invalid arguments
- **3**: State error
- **4**: Database error
- **5**: File system error
- **6**: Permission error
- **7**: Configuration error

### 2. Data Return Patterns
```bash
# Pattern: Return data to stdout on success
function get_data() {
    local id="$1"
    
    if ! validate_numeric_input_standardized "$id" "ID" 1; then
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

## Implementation Guidelines

### 1. Validation Order
1. Check for required parameters
2. Validate parameter types
3. Validate parameter formats
4. Validate business rules
5. Sanitize input data

### 2. Error Handling
- Use standardized error messages
- Include helpful context and examples
- Redirect error messages to stderr
- Use appropriate return codes

### 3. Documentation
- Document all validation requirements
- Include parameter constraints
- Provide usage examples
- Explain error conditions

## Quality Checklist

Before considering parameter validation complete, verify:

- [ ] All required parameters are validated
- [ ] Parameter types are checked
- [ ] Parameter formats are validated
- [ ] Business rules are enforced
- [ ] Error messages are standardized
- [ ] Return codes are consistent
- [ ] Documentation is complete
- [ ] Examples are provided

## Tools and Automation

### 1. Validation Testing
- Create test cases for all validation functions
- Test edge cases and error conditions
- Verify error message consistency

### 2. Documentation Generation
- Generate parameter validation documentation
- Create validation pattern examples
- Validate documentation completeness

This standard ensures that all functions in Refocus Shell have consistent, comprehensive parameter validation that provides clear feedback and prevents invalid data from causing issues.
