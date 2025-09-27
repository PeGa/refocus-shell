# Function Naming Standards

This document defines the standardized naming conventions for functions in Refocus Shell to ensure consistency, clarity, and maintainability across the codebase.

## Core Naming Principles

### 1. Descriptive and Action-Oriented
- Function names should clearly describe what the function does
- Use action verbs to indicate the function's purpose
- Avoid generic names like `do_something` or `process_data`

### 2. Consistent Prefixes
- Use standardized prefixes to categorize functions by purpose
- Prefixes help identify function categories at a glance
- Maintain consistency across all modules

### 3. Snake Case Convention
- Use lowercase letters with underscores separating words
- Follows Bash scripting conventions
- Improves readability and consistency

## Function Categories and Prefixes

### 1. Validation Functions
**Prefix: `validate_`**
- Purpose: Input validation and format checking
- Return: 0 for valid, non-zero for invalid
- Examples:
  - `validate_project_name`
  - `validate_session_id`
  - `validate_timestamp`
  - `validate_duration`
  - `validate_numeric_input`

### 2. Sanitization Functions
**Prefix: `sanitize_`**
- Purpose: Clean and normalize input data
- Return: Sanitized data to stdout
- Examples:
  - `sanitize_project_name`
  - `sanitize_timestamp`
  - `sanitize_file_path`

### 3. Formatting Functions
**Prefix: `format_`**
- Purpose: Convert data to specific output formats
- Return: Formatted data to stdout
- Examples:
  - `format_duration`
  - `format_timestamp`
  - `format_table_header`
  - `format_success_message`
  - `format_error_message`

### 4. Database Functions
**Prefix: `get_`, `set_`, `insert_`, `update_`, `delete_`**
- Purpose: Database operations and data manipulation
- Return: 0 for success, non-zero for failure
- Examples:
  - `get_session_by_id`
  - `get_recent_sessions`
  - `insert_session`
  - `update_session`
  - `delete_session`

### 5. Utility Functions
**Prefix: `calculate_`, `parse_`, `convert_`**
- Purpose: General utility operations
- Return: Calculated/converted data to stdout
- Examples:
  - `calculate_duration`
  - `parse_duration`
  - `convert_timestamp`
  - `get_current_timestamp`

### 6. Error Handling Functions
**Prefix: `handle_`**
- Purpose: Centralized error handling and user feedback
- Return: Uses exit codes for termination
- Examples:
  - `handle_argument_error`
  - `handle_state_error`
  - `handle_database_error`

### 7. Command Functions
**Prefix: `focus_`**
- Purpose: Main command implementations
- Return: Uses standardized exit codes
- Examples:
  - `focus_on`
  - `focus_off`
  - `focus_past_add`
  - `focus_past_list`

### 8. Bootstrap Functions
**Prefix: `refocus_`**
- Purpose: Initialization and setup functions
- Return: 0 for success, non-zero for failure
- Examples:
  - `refocus_bootstrap`
  - `refocus_command_main`
  - `refocus_validate_dependencies`

## Naming Patterns

### 1. Validation Functions
```bash
validate_<data_type>[_<context>]
validate_project_name
validate_session_id
validate_timestamp_standardized
validate_numeric_input_standardized
```

### 2. Database Functions
```bash
<operation>_<entity>[_<qualifier>]
get_session_by_id
get_recent_sessions
insert_session
update_session_notes
delete_session_by_id
```

### 3. Formatting Functions
```bash
format_<data_type>[_<format_type>]
format_duration
format_timestamp
format_table_header
format_success_message
format_error_message
```

### 4. Utility Functions
```bash
<operation>_<data_type>
calculate_duration
parse_duration
get_current_timestamp
convert_timestamp
```

### 5. Error Handling Functions
```bash
handle_<error_type>_error
handle_argument_error
handle_state_error
handle_database_error
```

## Parameter Naming Conventions

### 1. Descriptive Names
- Use clear, descriptive parameter names
- Include type information when helpful
- Use consistent terminology

### 2. Common Parameter Names
```bash
# Standard parameter names
project_name     # Project name string
session_id       # Session ID (numeric)
timestamp        # ISO timestamp string
duration         # Duration in seconds
start_time       # Start timestamp
end_time         # End timestamp
context          # Error context string
usage            # Usage syntax string
examples         # Examples string
```

### 3. Variable Naming
```bash
# Local variables
local project="$1"
local session_id="$2"
local converted_timestamp
local duration_seconds
local error_message
```

## Return Value Conventions

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
# Validation functions
validate_function() {
    if [[ valid ]]; then
        echo "$sanitized_data"  # Return data to stdout
        return 0
    else
        echo "Error message" >&2  # Error to stderr
        return 1
    fi
}

# Database functions
database_function() {
    if [[ success ]]; then
        echo "$result_data"  # Return data to stdout
        return 0
    else
        log_error "Error message" "context"
        return 1
    fi
}
```

## Examples of Well-Named Functions

### 1. Validation Functions
```bash
# Function: validate_project_name
# Description: Validates project name format and constraints
validate_project_name() {
    local project="$1"
    # Implementation...
}

# Function: validate_numeric_input_standardized
# Description: Validates numeric input with range checking
validate_numeric_input_standardized() {
    local value="$1"
    local field_name="$2"
    local min_val="$3"
    local max_val="$4"
    # Implementation...
}
```

### 2. Database Functions
```bash
# Function: get_session_by_id
# Description: Retrieves session data by ID with error handling
get_session_by_id() {
    local session_id="$1"
    # Implementation...
}

# Function: insert_duration_only_session
# Description: Inserts a duration-only session record
insert_duration_only_session() {
    local project="$1"
    local duration="$2"
    local date="$3"
    local notes="$4"
    # Implementation...
}
```

### 3. Formatting Functions
```bash
# Function: format_duration
# Description: Formats duration in human-readable format
format_duration() {
    local total_seconds="$1"
    local format_type="$2"
    # Implementation...
}

# Function: format_timestamp
# Description: Formats ISO timestamp to readable format
format_timestamp() {
    local iso_timestamp="$1"
    # Implementation...
}
```

### 4. Error Handling Functions
```bash
# Function: handle_argument_error
# Description: Handles argument validation errors with usage info
handle_argument_error() {
    local error_type="$1"
    local usage_syntax="$2"
    local examples="$3"
    # Implementation...
}
```

## Migration Guidelines

### 1. Existing Functions
- Review existing function names against standards
- Rename functions that don't follow conventions
- Update all references to renamed functions
- Maintain backward compatibility during transition

### 2. New Functions
- Follow naming standards from the start
- Use appropriate prefixes for function category
- Include comprehensive documentation
- Test naming consistency

### 3. Documentation Updates
- Update function documentation to reflect naming standards
- Include naming rationale in documentation
- Provide examples of proper naming

## Quality Checklist

Before considering a function properly named, verify:

- [ ] Function name follows appropriate prefix convention
- [ ] Name clearly describes the function's purpose
- [ ] Parameters use descriptive, consistent names
- [ ] Return values follow standard conventions
- [ ] Function category is clear from name
- [ ] Name is consistent with similar functions
- [ ] Documentation reflects naming standards
- [ ] All references use correct names

## Tools and Automation

### 1. Naming Validation
- Create scripts to validate function naming
- Check for consistent prefix usage
- Verify parameter naming conventions

### 2. Documentation Generation
- Generate function lists by category
- Create naming convention reports
- Validate documentation completeness

This standard ensures that all functions in Refocus Shell follow consistent, clear naming conventions that improve code readability, maintainability, and developer experience.
