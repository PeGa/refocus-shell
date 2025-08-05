# Refocus Shell - Prompt Management Solutions

This document outlines the different approaches to managing the system prompt in the refocus shell, addressing the issues identified in the TODO.md file.

## Problems Identified

1. **Missing `update-prompt` function**: The function is created in `setup.sh` but only when shell integration is set up
2. **Shell integration dependency**: Current system relies on shell integration being properly set up
3. **Login shell issues**: New terminals (login shells) don't automatically source `.bashrc`
4. **Fallback mechanism**: Direct `export PS1` works but doesn't persist across new terminals

## Solutions Implemented

### 1. Enhanced Shell Integration (Current Default)

**File**: `setup.sh` → `setup_shell_integration()`

**How it works**:
- Creates `~/.local/refocus/shell-integration.sh` with `update-prompt` function
- Adds sourcing to `.bashrc`, `.bash_profile`, and `.profile`
- Auto-updates prompt on shell startup if focus is active
- Provides fallback to default prompt if database is unavailable

**Pros**:
- Works in all shell types (login, interactive, non-login)
- Automatic prompt restoration on shell startup
- Minimal overhead

**Cons**:
- Requires proper shell configuration
- May not work in all environments

**Usage**:
```bash
./setup.sh shell-setup
```

### 2. Work Function Approach (Recommended)

**File**: `lib/focus-function.sh`

**How it works**:
- Creates a `focus()` function that can be sourced directly
- Automatically updates prompt after `focus on` and `focus off` commands
- Stores original PS1 and provides restoration functions
- No dependency on external shell integration

**Pros**:
- Always works - no shell integration issues
- Automatic prompt updates
- Preserves original prompt
- Works in any shell environment

**Cons**:
- Requires sourcing the function file
- Slightly more complex setup

**Usage**:
```bash
# Install the focus function
./setup.sh function-setup

# Or manually source it
source ~/.local/refocus/lib/focus-function.sh

# Use it
focus on project
focus off
```

### 3. Safe Alias Approach (Alternative)

**File**: `lib/work-alias.sh`

**How it works**:
- Provides `work-safe()` function that avoids `-e` exit issues
- Temporarily disables `set -e` during execution
- Captures and returns proper exit codes
- Updates prompt automatically

**Pros**:
- Solves the `-e` exit problem from your idea #1
- Safe execution without breaking current shell
- Automatic prompt updates

**Cons**:
- More complex error handling
- Requires sourcing the function

**Usage**:
```bash
source ~/.local/work/lib/work-alias.sh
work-safe on project
work-safe off
```

### 4. Enhanced Fallback System

**File**: `lib/work-utils.sh` → `set_work_prompt()` and `restore_original_prompt()`

**How it works**:
- Tries multiple methods to update prompt:
  1. Call `update-prompt` function if available
  2. Source shell integration directly
  3. Direct `export PS1` as final fallback
- Provides detailed feedback about which method worked

**Pros**:
- Multiple fallback mechanisms
- Detailed error reporting
- Works even if shell integration is broken

**Cons**:
- More complex logic
- May not persist across new terminals

## Installation Options

### Option 1: Enhanced Shell Integration (Default)
```bash
./setup.sh install  # Includes shell integration
./setup.sh shell-setup  # Just shell integration
```

### Option 2: Work Function (Recommended)
```bash
./setup.sh function-setup
```

### Option 3: Manual Setup
```bash
# Copy work function to your shell
cp lib/work-function.sh ~/.local/work/lib/
echo "source ~/.local/work/lib/work-function.sh" >> ~/.bashrc
```

## Testing the Solutions

### Test Enhanced Shell Integration
```bash
# In a new terminal
focus on test
# Should show work prompt automatically
focus off
# Should restore original prompt automatically
```

### Test Work Function
```bash
source lib/work-function.sh
focus on test
# Should show work prompt immediately
focus off
# Should restore original prompt immediately
```

### Test Safe Alias
```bash
source lib/work-alias.sh
work-safe on test
# Should work without breaking shell
work-safe off
```

## Comparison with Your Original Ideas

### Your Idea #1: `alias work='. $(work)'`
**Problem**: Uncaught `-e` events kill current bash session
**Solution**: Safe alias approach with proper error handling

### Your Idea #2: Bash function launching subterminal
**Problem**: Flight-engineering-grade complexity
**Solution**: Work function approach - simpler and more reliable

### Your Idea #3: Alias without `-e` catches
**Problem**: Some control might be lost
**Solution**: Safe alias with proper exit code handling

### Your Idea #4: Moving to work function
**Problem**: Major reengineering
**Solution**: ✅ Implemented as the recommended approach

## Recommendations

1. **For new installations**: Use the work function approach (`./setup.sh function-setup`)
2. **For existing installations**: Enhanced shell integration should work with the improvements
3. **For troubleshooting**: Use the enhanced fallback system in `work-utils.sh`

## Migration Guide

### From Shell Integration to Work Function
```bash
# Remove old shell integration
./setup.sh uninstall

# Install work function
./setup.sh function-setup
```

### From Work Function to Shell Integration
```bash
# Remove work function
./setup.sh function-remove

# Install shell integration
./setup.sh shell-setup
```

## Troubleshooting

### `update-prompt: command not found`
- Install shell integration: `./setup.sh shell-setup`
- Or use work function: `./setup.sh function-setup`

### Prompt not updating in new terminals
- Check if `.bash_profile` sources `.bashrc`
- Or use work function approach

### Shell integration not working
- Use work function as alternative
- Or manually source: `source ~/.local/refocus/shell-integration.sh`

## Future Improvements

1. **Auto-detection**: Automatically choose best approach based on environment
2. **Hybrid approach**: Combine shell integration with work function for maximum compatibility
3. **Configuration**: Allow users to choose their preferred approach
4. **Testing**: Add comprehensive tests for all prompt management scenarios 