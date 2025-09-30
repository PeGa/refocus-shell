# Function Documentation Standards

This document defines the standards for documenting functions in Refocus Shell to ensure consistency, maintainability, and clarity across the codebase.

## Documentation Format

Every function should follow this standardized documentation format:

```bash
# Function: function_name
# Description: Brief description of what the function does
# Usage: function_name <param1> <param2> [optional_param]
# Parameters:
#   $1 - param1: Description of the first parameter
#   $2 - param2: Description of the second parameter
#   $3 - optional_param: Description of optional parameter (default: value)
# Returns:
#   0 - Success: Description of success condition
#   1 - Error: Description of error condition
#   2 - Invalid arguments: Description of argument validation failure
# Side Effects:
#   - Lists any side effects (file creation, database changes, etc.)
# Dependencies:
#   - Lists any external dependencies (commands, files, etc.)
# Examples:
#   function_name "example1" "example2"
#   function_name "example" "with" "optional" "param"
# Notes:
#   - Additional notes about usage, limitations, or important details
function_name() {
    # Implementation
}
```

## Parameter Documentation

### Required Parameters
- Always document required parameters with `$1`, `$2`, etc.
- Include parameter name, type, and description
- Specify validation requirements

### Optional Parameters
- Mark optional parameters with `[optional_param]`
- Include default values when applicable
- Document what happens when parameter is omitted

### Return Values
- Document all possible return codes
- Explain what each return code means
- Include success and error conditions

## Function Categories

### 1. Validation Functions
- Purpose: Input validation and sanitization
- Return: 0 for valid, non-zero for invalid
- Error handling: Print error messages to stderr

### 2. Database Functions
- Purpose: Database operations and queries
- Return: 0 for success, non-zero for failure
- Error handling: Log errors and return appropriate codes

### 3. Utility Functions
- Purpose: General utility operations
- Return: 0 for success, non-zero for failure
- Error handling: Consistent with function category

### 4. Command Functions
- Purpose: Main command implementations
- Return: Use standardized exit codes
- Error handling: Use centralized error handling

## Naming Conventions

### Function Names
- Use descriptive, action-oriented names
- Use snake_case for consistency
- Prefix with category when appropriate:
  - `validate_*` for validation functions
  - `format_*` for formatting functions
  - `get_*` for retrieval functions
  - `set_*` for setting functions
  - `handle_*` for error handling functions

### Parameter Names
- Use descriptive names in documentation
- Include type information when helpful
- Use consistent terminology across functions

### Variable Names
- Use descriptive names
- Follow snake_case convention
- Include type hints when helpful

## Examples

### Well-Documented Function
```bash
# Function: validate_project_name
# Description: Validates and sanitizes a project name for use in focus sessions
# Usage: validate_project_name <project_name>
# Parameters:
#   $1 - project_name: The project name to validate (string)
# Returns:
#   0 - Success: Project name is valid and sanitized
#   1 - Error: Project name is invalid (empty, too long, or contains invalid characters)
# Side Effects:
#   - Prints error messages to stderr on validation failure
# Dependencies:
#   - None
# Examples:
#   validate_project_name "my-project"
#   validate_project_name "web-development"
# Notes:
#   - Project names are limited to 100 characters
#   - Invalid characters include control characters
#   - Empty or whitespace-only names are rejected
validate_project_name() {
    local project="$1"
    
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required" >&2
        return 1
    fi
    
    # Additional validation logic...
}
```

### Database Function Example
```bash
# Function: get_session_by_id
# Description: Retrieves session data by session ID with error handling
# Usage: get_session_by_id <session_id>
# Parameters:
#   $1 - session_id: The numeric ID of the session to retrieve
# Returns:
#   0 - Success: Session data retrieved and printed to stdout
#   1 - Error: Session not found or database error
# Side Effects:
#   - Queries the database
#   - Prints error messages to stderr on failure
# Dependencies:
#   - execute_sqlite function
#   - Database connection
# Examples:
#   get_session_by_id 123
#   local session_data=$(get_session_by_id 456)
# Notes:
#   - Session ID must be a positive integer
#   - Returns session data in pipe-delimited format
#   - Use handle_database_error for consistent error handling
get_session_by_id() {
    local session_id="$1"
    
    # Implementation...
}
```

## Implementation Guidelines

### 1. Consistency
- Use the same documentation format for all functions
- Maintain consistent parameter naming
- Use standardized return codes

### 2. Completeness
- Document all parameters, even if obvious
- Include all possible return values
- Document side effects and dependencies

### 3. Clarity
- Use clear, concise descriptions
- Provide practical examples
- Include important notes and limitations

### 4. Maintenance
- Update documentation when functions change
- Keep examples current and relevant
- Review documentation during code reviews

## Quality Checklist

Before considering a function fully documented, verify:

- [ ] Function has complete header documentation
- [ ] All parameters are documented with types and descriptions
- [ ] All return values are documented with conditions
- [ ] Side effects are clearly documented
- [ ] Dependencies are listed
- [ ] Practical examples are provided
- [ ] Important notes and limitations are included
- [ ] Function name follows naming conventions
- [ ] Parameter names are descriptive
- [ ] Return codes follow standards

## Tools and Automation

### Documentation Validation
- Use grep to find functions without documentation
- Create scripts to validate documentation completeness
- Include documentation checks in CI/CD pipeline

### Documentation Generation
- Consider tools for automatic documentation generation
- Maintain documentation templates
- Use consistent formatting tools

This standard ensures that all functions in Refocus Shell are well-documented, maintainable, and consistent with the project's quality standards.
