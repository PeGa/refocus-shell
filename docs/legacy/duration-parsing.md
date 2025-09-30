# Duration Parsing Error Handling

This document describes the standardized approach to duration parsing and error handling in Refocus Shell.

## Overview

Duration parsing in Refocus Shell uses a single, centralized function `parse_duration()` located in `lib/focus-utils.sh`. This function handles parsing duration strings into seconds with consistent error handling.

## Function: `parse_duration()`

### Location
- **File**: `lib/focus-utils.sh`
- **Lines**: 100-138

### Purpose
Converts human-readable duration strings into seconds for database storage and calculations.

### Supported Formats

| Format | Example | Description |
|--------|---------|-------------|
| `Nh` | `2h` | Hours only |
| `Nm` | `45m` | Minutes only |
| `NhMm` | `1h30m` | Hours and minutes |
| `N.Nh` | `1.5h` | Decimal hours |
| `N.Nh` | `0.5h` | Fractional hours |

### Examples

```bash
parse_duration "1h30m"    # Returns: 5400 (seconds)
parse_duration "2h"       # Returns: 7200 (seconds)
parse_duration "45m"      # Returns: 2700 (seconds)
parse_duration "1.5h"     # Returns: 5400 (seconds)
parse_duration "0.5h"     # Returns: 1800 (seconds)
```

### Error Handling

#### Input Validation
- **Empty input**: Returns exit code 1, prints "❌ Duration is required"
- **Invalid format**: Returns exit code 1, prints format error with examples

#### Error Messages
```bash
# Empty input
❌ Duration is required

# Invalid format
❌ Invalid duration format: invalid
   Supported formats: 1h30m, 2h, 45m, 1.5h, 0.5h
```

#### Exit Codes
- **0**: Success - valid duration parsed
- **1**: Error - invalid input or format

## Usage Pattern

### In Commands
```bash
# Parse duration and handle errors
duration_seconds=$(parse_duration "$duration")
if [[ $? -ne 0 ]]; then
    exit 2  # Invalid arguments
fi
```

### Error Handling Strategy
1. **Function Level**: `parse_duration()` provides detailed error messages
2. **Command Level**: Commands check exit code and use standardized exit codes
3. **User Level**: Clear, actionable error messages with format examples

## Implementation Details

### Input Processing
1. **Whitespace Removal**: Strips all spaces from input
2. **Format Detection**: Uses regex patterns to identify format type
3. **Conversion**: Converts to seconds using appropriate calculation

### Regex Patterns
```bash
# Decimal hours: 1.5h, 0.5h
^([0-9]+\.?[0-9]*)h$

# Hours + minutes: 1h30m, 2h45m
^([0-9]+)h([0-9]+)m$

# Hours only: 2h, 1h
^([0-9]+)h$

# Minutes only: 45m, 90m
^([0-9]+)m$
```

### Calculations
- **Hours**: `hours * 3600`
- **Minutes**: `minutes * 60`
- **Decimal hours**: Uses `bc` for precise calculation
- **Combined**: `hours * 3600 + minutes * 60`

## Edge Cases Handled

### Valid Edge Cases
- `0h`, `0m` → 0 seconds
- `1h60m` → 7200 seconds (2 hours)
- `24h` → 86400 seconds (1 day)
- `999h` → 3596400 seconds (very long sessions)

### Invalid Cases
- Empty string: `""`
- Invalid units: `2d`, `30s`
- Malformed: `1h30`, `h30m`
- Non-numeric: `abc`, `invalid`

## Integration Points

### Commands Using Duration Parsing
- **`focus past add`**: Duration-only sessions with `--duration` flag

### Database Storage
- Duration stored as `duration_seconds` (INTEGER)
- Used for calculations and reporting

### Display Functions
- `format_duration_minutes()`: Converts seconds to minutes
- `format_duration_hours_minutes()`: Converts to "Nh Mm" format

## Migration Notes

### Removed Functions
- **`validate_duration()`**: Removed from `lib/focus-validation.sh` (was unused)
- **Dead code elimination**: Cleaned up unused validation function

### Error Message Standardization
- **Before**: Inconsistent error messages across functions
- **After**: Standardized ❌ emoji and format examples
- **Consistency**: All duration errors now follow same pattern

## Testing

### Test Cases
```bash
# Valid formats
parse_duration "1h30m"    # Should return 5400
parse_duration "2h"       # Should return 7200
parse_duration "45m"      # Should return 2700
parse_duration "1.5h"     # Should return 5400
parse_duration "0.5h"     # Should return 1800

# Invalid formats
parse_duration "invalid"  # Should return exit code 1
parse_duration ""         # Should return exit code 1
parse_duration "2d"      # Should return exit code 1
parse_duration "1h30"    # Should return exit code 1
```

### Command Integration Tests
```bash
# Valid command usage
focus past add test --duration "1h30m" --date "today"

# Invalid duration
focus past add test --duration "invalid" --date "today"
# Should show error and exit with code 2
```

## Best Practices

### For Developers
1. **Use `parse_duration()`**: Don't implement custom duration parsing
2. **Check exit codes**: Always verify function success before using result
3. **Handle errors gracefully**: Use standardized exit codes in commands
4. **Test edge cases**: Verify behavior with boundary values

### For Users
1. **Use supported formats**: Stick to documented format patterns
2. **Check error messages**: Read format examples when errors occur
3. **Use reasonable values**: Avoid extremely large durations

## Future Considerations

### Potential Enhancements
- **Day support**: Add `Nd` format for multi-day sessions
- **Second precision**: Add `Ns` format for precise timing
- **Range validation**: Add maximum duration limits
- **Localization**: Support different time unit languages

### Backward Compatibility
- **Format stability**: Existing formats will continue to work
- **Error message consistency**: Maintain current error message format
- **Function signature**: Keep same function interface
