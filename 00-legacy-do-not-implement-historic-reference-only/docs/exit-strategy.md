# Refocus Shell - Exit Strategy Documentation

## Overview
This document clarifies the proper usage of `exit` vs `return` statements in the Refocus Shell codebase, ensuring consistent behavior and preventing script termination issues.

## Current Architecture

### Command Execution Flow
```
Command Script (focus-on.sh)
    ↓
refocus_script_main focus_on "$@"
    ↓
refocus_command_main focus_on "$@"
    ↓
focus_on "$@" (command function)
    ↓
Library functions (validate_project_name, etc.)
```

## Exit Strategy Rules

### 1. **Command Functions** (in `/commands/`)
**Use `exit` to terminate the entire script**

- **Purpose**: Command functions are the main entry points called by `refocus_script_main`
- **Behavior**: `exit` terminates the entire script process
- **Examples**: `focus_on()`, `focus_off()`, `focus_past_add()`

```bash
# ✅ CORRECT - Command function
function focus_on() {
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required."
        exit 2  # Terminates entire script
    fi
}
```

### 2. **Library Functions** (in `/lib/`)
**Use `return` to return to calling function**

- **Purpose**: Library functions are called by command functions or other library functions
- **Behavior**: `return` returns control to the caller without terminating the script
- **Examples**: `validate_project_name()`, `execute_sqlite()`, `sanitize_project_name()`

```bash
# ✅ CORRECT - Library function
function validate_project_name() {
    if [[ -z "$project" ]]; then
        echo "❌ Project name is required"
        return 1  # Returns to caller
    fi
    return 0
}
```

### 3. **Bootstrap Functions** (in `/lib/focus-bootstrap.sh`)
**Use `return` for function returns, `exit` for script termination**

- **Purpose**: Bootstrap functions handle script initialization and command execution
- **Behavior**: Mixed usage based on context
- **Examples**: `refocus_validate_dependencies()`, `refocus_confirm()`

```bash
# ✅ CORRECT - Bootstrap function
function refocus_validate_dependencies() {
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "❌ Missing required dependencies: ${missing_deps[*]}"
        return 1  # Returns to caller
    fi
    return 0
}
```

## Current Implementation Status

### ✅ **Already Correctly Implemented**

The codebase already follows the proper exit strategy:

1. **Command Functions**: Use `exit` appropriately
   - `focus-on.sh`: Uses `exit 2` for invalid args, `exit 7` for state errors
   - `focus-off.sh`: Uses `exit 7` for state errors
   - `focus-past.sh`: Uses `exit 2` for invalid args, `exit 1` for general errors

2. **Library Functions**: Use `return` appropriately
   - `focus-validation.sh`: All functions use `return 0`/`return 1`
   - `focus-utils.sh`: All functions use `return 0`/`return 1`
   - `focus-db.sh`: All functions use `return 0`/`return 1`

3. **Bootstrap Functions**: Mixed usage as appropriate
   - `refocus_validate_dependencies()`: Uses `return`
   - `refocus_confirm()`: Uses `return`

## Why This Pattern Works

### 1. **Script Termination Control**
- Command functions control when the entire script terminates
- Library functions don't accidentally terminate the script
- Bootstrap system maintains control over execution flow

### 2. **Error Propagation**
- Library functions return error codes to their callers
- Command functions can handle errors and decide whether to terminate
- Consistent error handling throughout the call stack

### 3. **Installation Safety**
- The installation system (`setup.sh`) relies on proper exit behavior
- Library functions can be called during installation without terminating
- Command functions properly terminate installation scripts when needed

## Guidelines for Future Development

### When Adding New Command Functions
```bash
function focus_new_command() {
    # Validate arguments
    if [[ -z "$arg" ]]; then
        echo "❌ Argument required"
        exit 2  # Terminate script
    fi
    
    # Call library functions
    if ! validate_something "$arg"; then
        exit 1  # Terminate script
    fi
    
    # Success - script continues
}
```

### When Adding New Library Functions
```bash
function validate_something() {
    local input="$1"
    
    if [[ -z "$input" ]]; then
        echo "❌ Input required"
        return 1  # Return to caller
    fi
    
    return 0  # Success
}
```

### When Adding New Bootstrap Functions
```bash
function refocus_new_bootstrap() {
    # Function logic here
    
    if [[ $error_condition ]]; then
        return 1  # Return error to caller
    fi
    
    return 0  # Success
}
```

## Testing the Exit Strategy

### Test Command Functions
```bash
# Should terminate with exit code 2
focus on
echo "This should not print"

# Should terminate with exit code 7
focus off
echo "This should not print"
```

### Test Library Functions
```bash
# Should return error but continue execution
if validate_project_name ""; then
    echo "Validation passed"
else
    echo "Validation failed, but script continues"
fi
echo "This should print"
```

## Migration Notes

### ✅ **No Migration Needed**
The current implementation is already correct and follows best practices. No changes are required.

### **What NOT to Change**
- **DO NOT** change `return` statements in library functions to `exit`
- **DO NOT** change `exit` statements in command functions to `return`
- **DO NOT** modify bootstrap function patterns

### **What to Maintain**
- Continue using `exit` in command functions for script termination
- Continue using `return` in library functions for error propagation
- Maintain the current bootstrap system architecture

## Conclusion

The Refocus Shell codebase already implements a proper and safe exit strategy that:
- Prevents accidental script termination
- Maintains proper error propagation
- Ensures installation system stability
- Follows bash scripting best practices

No changes are required to the exit strategy implementation.
