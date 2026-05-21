# Refocus Shell - Timestamp Validation Approaches

## Overview
This document outlines the different timestamp validation approaches used throughout the Refocus Shell codebase, explaining when each approach should be used and their specific use cases.

## Timestamp Validation Approaches

### 1. **`validate_timestamp()` Function** (Primary Approach)
**Location**: `lib/focus-utils.sh`
**Purpose**: Comprehensive user input validation and conversion

#### **Use Cases:**
- **User input validation** in commands that accept timestamps
- **Format conversion** from various input formats to ISO format
- **Input sanitization** and error reporting

#### **Supported Formats:**
1. **YYYY/MM/DD-HH:MM** (recommended format)
   - Example: `2025/09/27-14:30`
   - Validates components individually
   - Converts to ISO format

2. **HH:MM** (today's date)
   - Example: `14:30`
   - Assumes current date
   - Converts to ISO format

3. **ISO formats**
   - `YYYY-MM-DDTHH:MM:SS±HH:MM`
   - `YYYY-MM-DDTHH:MM`
   - Validates and returns as-is

4. **Relative times** (hour-based only)
   - `7h` (7 hours ago)
   - `30m` (30 minutes ago)
   - Converts to absolute ISO timestamp

5. **Natural language**
   - `now`, `yesterday`, `2 hours ago`
   - Uses `date --date` for parsing

#### **Validation Rules:**
- **Year**: 1900-2100
- **Month**: 1-12
- **Day**: 1-31
- **Hour**: 0-23
- **Minute**: 0-59
- **Relative hours**: 1-24
- **Relative minutes**: 1-59
- **Rejects**: Days, weeks, months, years (2d, 3w, etc.)

#### **Usage Pattern:**
```bash
# In command functions
converted_time=$(validate_timestamp "$user_input" "Start time")
if [[ $? -ne 0 ]]; then
    echo "$converted_time"  # Error message
    exit 2  # Invalid arguments
fi
# Use $converted_time (ISO format)
```

### 2. **`validate_time_range()` Function** (Range Validation)
**Location**: `lib/focus-validation.sh`
**Purpose**: Validates start/end time relationships

#### **Use Cases:**
- **Session duration validation** (start < end)
- **Duration limits** (max 24 hours)
- **Time range consistency** checks

#### **Validation Rules:**
- Start time must be before end time
- Maximum session duration: 24 hours
- Both times must be valid timestamps

#### **Usage Pattern:**
```bash
# After validating individual timestamps
if ! validate_time_range "$start_time" "$end_time"; then
    exit 2  # Invalid arguments
fi
```

### 3. **Direct `date --date` Usage** (Internal Operations)
**Purpose**: Internal timestamp operations and conversions

#### **Use Cases:**
- **Timestamp arithmetic** (calculating durations)
- **Format conversion** for display
- **Internal calculations** (pause durations, etc.)

#### **Patterns:**
```bash
# Convert to Unix timestamp for calculations
start_ts=$(date --date="$start_time" +%s 2>/dev/null)

# Convert to display format
display_time=$(date --date="$timestamp" +"%Y-%m-%d %H:%M")

# Convert to ISO format
iso_time=$(date --date="$timestamp" -Iseconds 2>/dev/null)
```

### 4. **`get_current_timestamp()` Function** (Current Time)
**Location**: `lib/focus-utils.sh`
**Purpose**: Get current timestamp in ISO format

#### **Use Cases:**
- **Session start/end times**
- **Current time references**
- **Timestamp generation**

#### **Usage Pattern:**
```bash
# Get current time
now=$(get_current_timestamp)
# Returns: 2025-09-27T14:30:00-03:00
```

### 5. **`calculate_duration()` Function** (Duration Calculation)
**Location**: `lib/focus-utils.sh`
**Purpose**: Calculate duration between two timestamps

#### **Use Cases:**
- **Session duration calculation**
- **Elapsed time computation**
- **Duration display**

#### **Usage Pattern:**
```bash
# Calculate duration in seconds
duration=$(calculate_duration "$start_time" "$end_time")
# Convert to minutes: $((duration / 60))
```

## When to Use Each Approach

### **For User Input Validation**
```bash
# ✅ Use validate_timestamp()
user_time=$(validate_timestamp "$user_input" "Start time")
if [[ $? -ne 0 ]]; then
    echo "$user_time"  # Error message
    exit 2
fi
```

### **For Time Range Validation**
```bash
# ✅ Use validate_time_range()
if ! validate_time_range "$start_time" "$end_time"; then
    exit 2
fi
```

### **For Internal Calculations**
```bash
# ✅ Use direct date --date
start_ts=$(date --date="$start_time" +%s 2>/dev/null)
end_ts=$(date --date="$end_time" +%s 2>/dev/null)
duration=$((end_ts - start_ts))
```

### **For Current Time**
```bash
# ✅ Use get_current_timestamp()
now=$(get_current_timestamp)
```

### **For Duration Display**
```bash
# ✅ Use calculate_duration()
duration=$(calculate_duration "$start_time" "$end_time")
echo "Duration: $((duration / 60)) minutes"
```

## Error Handling Patterns

### **User Input Errors**
```bash
# validate_timestamp returns error message on stdout
converted_time=$(validate_timestamp "$input" "Time")
if [[ $? -ne 0 ]]; then
    echo "$converted_time"  # Display error message
    exit 2
fi
```

### **Internal Operation Errors**
```bash
# Direct date operations with error suppression
timestamp=$(date --date="$input" -Iseconds 2>/dev/null)
if [[ $? -ne 0 ]]; then
    echo "❌ Invalid timestamp format"
    exit 2
fi
```

### **Range Validation Errors**
```bash
# validate_time_range returns error message on stdout
if ! validate_time_range "$start" "$end"; then
    exit 2
fi
```

## Format Conversion Flow

### **Input → Validation → Storage**
```
User Input: "2025/09/27-14:30"
    ↓
validate_timestamp() → "2025-09-27T14:30:00-03:00"
    ↓
Store in database (ISO format)
```

### **Storage → Display**
```
Database: "2025-09-27T14:30:00-03:00"
    ↓
date --date="$timestamp" +"%Y-%m-%d %H:%M"
    ↓
Display: "2025-09-27 14:30"
```

## Best Practices

### **1. Always Validate User Input**
```bash
# ✅ Good
converted_time=$(validate_timestamp "$user_input" "Time")
if [[ $? -ne 0 ]]; then
    echo "$converted_time"
    exit 2
fi

# ❌ Bad - no validation
timestamp="$user_input"
```

### **2. Use Appropriate Error Codes**
```bash
# ✅ Good - timestamp validation errors
exit 2  # Invalid arguments

# ✅ Good - range validation errors  
exit 2  # Invalid arguments

# ✅ Good - internal calculation errors
exit 1  # General error
```

### **3. Consistent Format Storage**
```bash
# ✅ Good - store in ISO format
execute_sqlite "INSERT INTO sessions (start_time) VALUES ('$iso_timestamp')"

# ❌ Bad - store in user format
execute_sqlite "INSERT INTO sessions (start_time) VALUES ('$user_input')"
```

### **4. Handle Timezone Consistently**
```bash
# ✅ Good - use ISO format with timezone
timestamp="2025-09-27T14:30:00-03:00"

# ❌ Bad - ambiguous timezone
timestamp="2025-09-27 14:30"
```

## Common Patterns by Command

### **focus past add**
```bash
# Validate start time
converted_start=$(validate_timestamp "$start_time" "Start time")
if [[ $? -ne 0 ]]; then
    echo "$converted_start"
    exit 2
fi

# Validate end time
converted_end=$(validate_timestamp "$end_time" "End time")
if [[ $? -ne 0 ]]; then
    echo "$converted_end"
    exit 2
fi

# Validate range
if ! validate_time_range "$converted_start" "$converted_end"; then
    exit 2
fi
```

### **focus on/off**
```bash
# Get current time
now=$(get_current_timestamp)

# Calculate duration
duration=$(calculate_duration "$start_time" "$now")
```

### **focus status**
```bash
# Calculate elapsed time
elapsed=$(calculate_duration "$start_time" "$now")

# Convert to display format
start_display=$(date --date="$start_time" +"%Y-%m-%d %H:%M")
```

## Migration Notes

### **Current Implementation Status**
- ✅ **validate_timestamp()**: Comprehensive and well-implemented
- ✅ **validate_time_range()**: Proper range validation
- ✅ **Direct date usage**: Appropriate for internal operations
- ✅ **Error handling**: Consistent patterns across commands

### **No Changes Required**
The current timestamp validation approaches are well-designed and consistently implemented. Each approach serves its specific purpose appropriately.

### **Future Considerations**
- Consider adding timezone validation
- Consider adding more granular duration limits
- Consider adding business hours validation for work sessions
