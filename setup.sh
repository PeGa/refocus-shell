#!/usr/bin/env bash
# Refocus Shell Setup - A privacy-first, FLOSS productivity tool
# Copyright (C) 2025 Pablo Gonzalez
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to set appropriate abort message
set_abort_message() {
    local command="$1"
    case "$command" in
        install)
            trap 'echo ""; echo "Installation aborted"; exit 1' INT
            ;;
        uninstall)
            trap 'echo ""; echo "Uninstallation aborted"; exit 1' INT
            ;;
        init)
            trap 'echo ""; echo "Database initialization aborted"; exit 1' INT
            ;;
        reset)
            trap 'echo ""; echo "Database reset aborted"; exit 1' INT
            ;;
        deps)
            trap 'echo ""; echo "Dependency installation aborted"; exit 1' INT
            ;;
        *)
            trap 'echo ""; echo "Operation aborted"; exit 1' INT
            ;;
    esac
}

# Default installation paths
SCRIPT_NAME="focus"
# Use the real user's home directory, not the effective user's
REAL_USER_HOME=$(eval echo ~$(logname 2>/dev/null || echo $SUDO_USER 2>/dev/null || echo $USER))
DB_DEFAULT="$REAL_USER_HOME/.local/refocus/refocus.db"
REFOCUS_DATA_PATH="$REAL_USER_HOME/.local/refocus"

# Detect if running with sudo and set appropriate default
if [[ "$EUID" -eq 0 ]]; then
    INSTALL_DIR_DEFAULT="/usr/local/bin"
else
    INSTALL_DIR_DEFAULT="$REAL_USER_HOME/.local/bin"
fi

# Function to validate and create directory if needed
validate_and_create_dir() {
    local path="$1"
    local description="$2"
    
    if [[ ! -d "$path" ]]; then
        echo ""
        echo "Directory does not exist: $path"
        read -p "Create directory '$path'? (Y/n): " CREATE_DIR
        if [[ ! "$CREATE_DIR" =~ ^[Nn]$ ]]; then
            print_verbose "Creating directory: $path"
            mkdir -p "$path"
            if [[ $? -ne 0 ]]; then
                print_error "Failed to create directory: $path"
                exit 1
            fi
            print_verbose_success "Directory created successfully"
        else
            echo "Installation aborted."
            exit 0
        fi
    fi
}

# Interactive path setup for installation
setup_paths() {
    echo "Refocus Shell Installation"
    echo "========================"
    echo ""
    
    # Database path
    echo "Where should the database be stored?"
    read -p "Database path (default: $DB_DEFAULT): " DB_INPUT
    DB_PATH="${DB_INPUT:-$DB_DEFAULT}"
    
    # Validate database directory
    local db_dir=$(dirname "$DB_PATH")
    validate_and_create_dir "$db_dir" "database directory"
    
    # Installation directory
    echo ""
    echo "Where should the focus script be installed?"
            print_verbose_note "/usr/local/bin requires sudo, ~/.local/bin is recommended for users"
    read -p "Installation directory (default: $INSTALL_DIR_DEFAULT): " INSTALL_INPUT
    INSTALL_DIR="${INSTALL_INPUT:-$INSTALL_DIR_DEFAULT}"
    
    # Installation method choice
    echo ""
    echo "Choose installation method:"
    echo "a) Function installation (recommended)"
    echo "   - Automatic prompt updates"
    echo "   - Works in all shell environments"
    echo "   - No manual update-prompt calls needed"
    echo ""
    echo "b) Script installation"
    echo "   - Traditional executable script"
    echo "   - Requires manual update-prompt calls"
    echo "   - May need PATH configuration"
    echo ""
    read -p "Installation method (a/b, default: a): " METHOD_INPUT
    INSTALL_METHOD="${METHOD_INPUT:-a}"
    
    # Validate installation directory
    validate_and_create_dir "$INSTALL_DIR" "installation directory"
    
    echo ""
    echo "Installation Summary:"
    echo "  Database: $DB_PATH"
    echo "  Script: $INSTALL_DIR/focus"
    if [[ "$INSTALL_METHOD" == "a" ]]; then
        echo "  Method: Function installation (automatic prompt updates)"
    else
        echo "  Method: Script installation (manual prompt updates)"
    fi
    echo ""
    
    # Check if we need sudo
    if [[ ! -w "$INSTALL_DIR" ]] && [[ "$EUID" -ne 0 ]]; then
        echo "Warning: No write permission to $INSTALL_DIR"
        echo "You may need to run with sudo or choose a different directory."
        echo ""
    elif [[ "$EUID" -eq 0 ]] && [[ "$INSTALL_DIR" == *"/usr/local"* ]]; then
        echo "Info: Installing system-wide to $INSTALL_DIR"
        echo ""
    fi
    
    read -p "Continue with installation? (Y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
}

# Function to validate paths exist
validate_paths_exist() {
    local script_path="$1"
    local db_path="$2"
    local has_error=false
    
    # Check if script exists
    if [[ ! -f "$script_path" ]]; then
        echo "Error: Focus script is not installed at: $script_path"
        has_error=true
    fi
    
    # Check if database exists
    if [[ ! -f "$db_path" ]]; then
        echo "Error: Database file not found at: $db_path"
        has_error=true
    fi
    
    if [[ "$has_error" == "true" ]]; then
        echo ""
        echo "Refocus shell is not installed at the specified locations."
        echo "Please check the installation directory and database path."
        return 1
    fi
    
    return 0
}

# Interactive path setup for uninstallation
setup_uninstall_paths() {
    echo "Refocus Shell Uninstallation"
    echo "=========================="
    echo ""
    
    while true; do
        # Installation directory
        echo "Where is the focus script installed?"
        if [[ "$EUID" -eq 0 ]]; then
            print_verbose_note "Running with sudo - checking system-wide installation"
        else
            print_verbose_note "Common locations: ~/.local/bin, /usr/local/bin, /usr/bin"
        fi
        read -p "Installation directory (default: $INSTALL_DIR_DEFAULT): " INSTALL_DIR_INPUT
        INSTALL_DIR="${INSTALL_DIR_INPUT:-$INSTALL_DIR_DEFAULT}"
        
        # Database path
        echo ""
        echo "Where is the database located?"
        read -p "Database path (default: $DB_DEFAULT): " DB_INPUT
        DB_PATH="${DB_INPUT:-$DB_DEFAULT}"
        
        echo ""
        echo "Uninstallation Summary:"
        echo "  Script: $INSTALL_DIR/focus"
        echo "  Database: $DB_PATH"
        echo ""
        
        # Validate paths exist
        if validate_paths_exist "$INSTALL_DIR/focus" "$DB_PATH"; then
            break
        else
            echo ""
            read -p "Press Enter to try again or Ctrl+C to abort..."
            echo ""
        fi
    done
    
    read -p "Continue with uninstallation? (Y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to print colored status messages (verbose only)
print_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

print_verbose_success() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

print_verbose_note() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Note: $1"
    fi
}

# Function to install dependencies
install_dependencies() {
    local missing_deps=()
    
    # Check sqlite3
    if ! command -v sqlite3 >/dev/null 2>&1; then
        missing_deps+=("sqlite3")
    fi
    
    # Check notify-send
    if ! command -v notify-send >/dev/null 2>&1; then
        missing_deps+=("notify-send")
    fi
    
    # Check jq
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
        # If no missing dependencies, we're done
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        print_verbose "All dependencies are already available"
        return 0
    fi

    print_verbose "Installing missing dependencies: ${missing_deps[*]}"
    
    # Detect distribution and install appropriate packages
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        print_verbose "Detected Debian/Ubuntu. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite3")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify-bin")
        [[ " ${missing_deps[*]} " =~ " jq " ]] && packages+=("jq")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo apt-get update && sudo apt-get install -y "${packages[@]}"
        fi
    elif command -v pacman >/dev/null 2>&1; then
        # Arch/Manjaro
        print_verbose "Detected Arch/Manjaro. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify")
        [[ " ${missing_deps[*]} " =~ " jq " ]] && packages+=("jq")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo pacman -S --noconfirm "${packages[@]}"
        fi
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL
        print_verbose "Detected Fedora/RHEL. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify")
        [[ " ${missing_deps[*]} " =~ " jq " ]] && packages+=("jq")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo dnf install -y "${packages[@]}"
        fi
    elif command -v zypper >/dev/null 2>&1; then
        # openSUSE
        print_verbose "Detected openSUSE. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite3")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify-tools")
        [[ " ${missing_deps[*]} " =~ " jq " ]] && packages+=("jq")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo zypper install -y "${packages[@]}"
        fi
    else
        print_warning "Could not detect package manager. Please install dependencies manually."
        echo "Required packages:"
        echo "  - sqlite3 (for database operations)"
        echo "  - notify-send (for desktop notifications)"
        echo "  - jq (for JSON processing - optional)"
        echo ""
        echo "Common package names by distribution:"
        echo "  Ubuntu/Debian: sqlite3, libnotify-bin, jq"
        echo "  Arch/Manjaro: sqlite, libnotify, jq"
        echo "  Fedora/RHEL: sqlite, libnotify, jq"
        echo "  openSUSE: sqlite3, libnotify-tools, jq"
        return 1
    fi
    
    # Verify installations
    local failed_deps=()
    for dep in "${missing_deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            failed_deps+=("$dep")
        fi
    done
    
    if [[ ${#failed_deps[@]} -gt 0 ]]; then
        print_error "Failed to install: ${failed_deps[*]}"
        return 1
    else
        print_success "All dependencies installed successfully."
        return 0
    fi
}

# Function to initialize database
init_database() {
    local db_path="$1"
    
    print_verbose "Initializing database at: $db_path"
    
    # Create directory if it doesn't exist
    local db_dir=$(dirname "$db_path")
    mkdir -p "$db_dir"
    
    # Create database and tables
    sqlite3 "$db_path" "
        CREATE TABLE IF NOT EXISTS state (
            id INTEGER PRIMARY KEY,
            active INTEGER DEFAULT 0,
            project TEXT,
            start_time TEXT,
            prompt_content TEXT,
            prompt_type TEXT DEFAULT 'default',
            nudging_enabled BOOLEAN DEFAULT 1,
            focus_disabled BOOLEAN DEFAULT 0,
            last_focus_off_time TEXT,
            paused INTEGER DEFAULT 0,
            pause_notes TEXT,
            pause_start_time TEXT,
            previous_elapsed INTEGER DEFAULT 0
        );
        
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            notes TEXT
        );
        
        -- Insert initial state
        INSERT OR IGNORE INTO state (id, active, project, start_time, prompt_content, prompt_type, nudging_enabled, focus_disabled, last_focus_off_time, paused, pause_notes, pause_start_time, previous_elapsed)
        VALUES (1, 0, NULL, NULL, NULL, 'default', 1, 0, NULL, 0, NULL, NULL, 0);
        
        -- Create projects table for storing project descriptions
        CREATE TABLE IF NOT EXISTS projects (
            project TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
    "
    
    # Fix ownership if running with sudo
    if [[ "$EUID" -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
        print_verbose "Fixing database ownership for user: $SUDO_USER"
        chown "$SUDO_USER:$SUDO_USER" "$db_path"
        chown -R "$SUDO_USER:$SUDO_USER" "$db_dir"
    fi
    
    print_verbose "Database initialized successfully"
}

# Function to reset database
reset_database() {
    local db_path="$1"
    
    print_verbose "Resetting database at: $db_path"
    
    # Remove the database file
    rm -f "$db_path"
    print_verbose "Database deleted."
    
    # Reinitialize the database
    init_database "$db_path"
    print_success "Database reset complete."
}

# Function to install the focus script
install_script() {
    # Always install to PATH first
    local target_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    local focus_script=""
    
    # Find the focus script
    if [[ -f "./focus" ]]; then
        focus_script="./focus"
    elif [[ -f "$(dirname "$0")/focus" ]]; then
        focus_script="$(dirname "$0")/focus"
    else
        print_error "Could not find focus script"
        exit 1
    fi
    
    local focus_script_path="$(readlink -f "$focus_script")"
    
    # Check if already installed and up to date
    if [[ -f "$target_path" ]]; then
        local installed_hash=$(sha256sum "$target_path" 2>/dev/null | cut -d' ' -f1)
        local current_hash=$(sha256sum "$focus_script_path" 2>/dev/null | cut -d' ' -f1)
        
        if [[ "$installed_hash" == "$current_hash" ]]; then
            print_verbose "Focus script already installed and up to date at $target_path"
        else
            print_verbose "Updating existing installation at $target_path"
        fi
    fi
    
    print_verbose "Installing focus script to: $target_path"
    
    # Check if we have write permissions
    local install_dir=$(dirname "$target_path")
    if [[ ! -w "$install_dir" ]] && [[ "$EUID" -ne 0 ]]; then
        print_error "No write permission to $install_dir. Run with sudo or set INSTALL_DIR to a writable location."
        exit 1
    fi
    
    # Copy the focus script
    cp "$focus_script_path" "$target_path"
    chmod +x "$target_path"
    
    print_success "Focus script installed successfully to $target_path"
    if [[ "$INSTALL_METHOD" != "a" ]]; then
        print_verbose "You can now use 'focus' command from anywhere"
    fi
    
    # Install libraries
    install_libraries
}

# Function to install libraries
install_libraries() {
    local lib_dir="$REFOCUS_DATA_PATH/lib"
    
    # Create lib directory if it doesn't exist
    mkdir -p "$lib_dir"
    
    # Find and copy library files
    local source_lib_dir=""
    if [[ -d "./lib" ]]; then
        source_lib_dir="./lib"
    elif [[ -d "$(dirname "$0")/lib" ]]; then
        source_lib_dir="$(dirname "$0")/lib"
    else
        print_warning "Could not find lib directory, skipping library installation"
        return 0
    fi
    
    print_verbose "Installing libraries to: $lib_dir"
    
    # Copy all .sh files from lib directory
    if [[ -f "$source_lib_dir/focus-db.sh" ]]; then
        cp "$source_lib_dir/focus-db.sh" "$lib_dir/"
        chmod +x "$lib_dir/focus-db.sh"
    fi
    
    if [[ -f "$source_lib_dir/focus-utils.sh" ]]; then
        cp "$source_lib_dir/focus-utils.sh" "$lib_dir/"
        chmod +x "$lib_dir/focus-utils.sh"
    fi
    
    if [[ -f "$source_lib_dir/focus-bootstrap.sh" ]]; then
        cp "$source_lib_dir/focus-bootstrap.sh" "$lib_dir/"
        chmod +x "$lib_dir/focus-bootstrap.sh"
    fi
    
    if [[ -f "$source_lib_dir/focus-validation.sh" ]]; then
        cp "$source_lib_dir/focus-validation.sh" "$lib_dir/"
        chmod +x "$lib_dir/focus-validation.sh"
    fi
    
    if [[ -f "$source_lib_dir/focus-output.sh" ]]; then
        cp "$source_lib_dir/focus-output.sh" "$lib_dir/"
        chmod +x "$lib_dir/focus-output.sh"
    fi
    
    print_verbose "Libraries installed successfully to $lib_dir"
}

# Function to install commands
install_commands() {
    local commands_dir="$REFOCUS_DATA_PATH/commands"
    
    # Create commands directory if it doesn't exist
    mkdir -p "$commands_dir"
    
    # Find and copy command files
    local source_commands_dir=""
    if [[ -d "./commands" ]]; then
        source_commands_dir="./commands"
    elif [[ -d "$(dirname "$0")/commands" ]]; then
        source_commands_dir="$(dirname "$0")/commands"
    else
        print_warning "Could not find commands directory, skipping command installation"
        return 0
    fi
    
    print_verbose "Installing commands to: $commands_dir"
    
    # Copy all .sh files from commands directory
    for cmd_file in "$source_commands_dir"/*.sh; do
        if [[ -f "$cmd_file" ]]; then
            local filename=$(basename "$cmd_file")
            cp "$cmd_file" "$commands_dir/"
            chmod +x "$commands_dir/$filename"
        fi
    done
    
    print_verbose "Commands installed successfully to $commands_dir"
}

# Function to uninstall the focus script
uninstall_script() {
    local target_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    print_verbose "Uninstalling focus script from: $target_path"
    
    if [[ ! -f "$target_path" ]]; then
        print_warning "Focus script not found at $target_path"
        return 0
    fi
    
    # Check if we have write permissions
    if [[ ! -w "$INSTALL_DIR" ]] && [[ "$EUID" -ne 0 ]]; then
        print_error "No write permission to $INSTALL_DIR. Run with sudo or set INSTALL_DIR to a writable location."
        exit 1
    fi
    
    # Remove the script
    rm -f "$target_path"
    print_success "Focus script uninstalled from $target_path"
}

# Function to install focus-nudge script
install_nudge_script() {
    local nudge_script=""
    local target_path="$REFOCUS_DATA_PATH/focus-nudge"
    
    # Find the focus-nudge script
    if [[ -f "./focus-nudge" ]]; then
        nudge_script="./focus-nudge"
    elif [[ -f "$(dirname "$0")/focus-nudge" ]]; then
        nudge_script="$(dirname "$0")/focus-nudge"
    else
        print_error "Could not find focus-nudge script"
        return 1
    fi
    
    local nudge_script_path="$(readlink -f "$nudge_script")"
    
    # Create refocus data directory if it doesn't exist
    mkdir -p "$REFOCUS_DATA_PATH"
    
    print_verbose "Installing focus-nudge script to: $target_path"
    
    # Copy the focus-nudge script
    cp "$nudge_script_path" "$target_path"
    chmod +x "$target_path"
    
    # Fix ownership if running with sudo
    if [[ "$EUID" -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$target_path"
    fi
    
    print_verbose "Focus-nudge script installed successfully to $target_path"
}

# Function to uninstall focus-nudge script
uninstall_nudge_script() {
    local target_path="$REFOCUS_DATA_PATH/focus-nudge"
    
    print_verbose "Uninstalling focus-nudge script from: $target_path"
    
    if [[ ! -f "$target_path" ]]; then
        print_warning "Focus-nudge script not found at $target_path"
        return 0
    fi
    
    # Remove the script
    rm -f "$target_path"
    print_success "Focus-nudge script uninstalled from $target_path"
}

# Function to setup cron job for nudging
setup_cron_job() {
    local nudge_script="$REFOCUS_DATA_PATH/focus-nudge"
    
    print_verbose "Setting up focus-nudge script for dynamic cron management..."
    
    # Check if focus-nudge script exists
    if [[ ! -f "$nudge_script" ]]; then
        print_error "Focus-nudge script not found. Cannot setup dynamic nudging."
        return 1
    fi
    
    # Make the script executable
    chmod +x "$nudge_script"
    
    print_verbose "Focus-nudge script ready for dynamic cron management"
    print_verbose "Cron jobs will be installed/removed automatically when starting/stopping focus sessions"
    print_verbose "No static cron job needed - nudging is now real-time and session-based"
}

# Function to remove cron job for nudging
remove_cron_job() {
    local nudge_script="$REFOCUS_DATA_PATH/focus-nudge"
    
    print_verbose "Removing any active focus cron jobs..."
    
    # Remove any existing focus-nudge cron jobs
    local temp_cron_file="/tmp/focus_cron_$$"
    crontab -l 2>/dev/null > "$temp_cron_file" || true
    
    if grep -q "$nudge_script" "$temp_cron_file" 2>/dev/null; then
        sed -i "\|$nudge_script|d" "$temp_cron_file"
        
        if crontab "$temp_cron_file"; then
            print_success "Active focus cron jobs removed successfully"
        else
            print_error "Failed to remove cron jobs"
            rm -f "$temp_cron_file"
            return 1
        fi
    else
        print_verbose "No active focus cron jobs found"
    fi
    
    rm -f "$temp_cron_file"
}

# Function to detect current shell
detect_shell() {
    local shell_name=""
    local rc_file=""
    
    # Get the real user's home directory (works with sudo)
    local real_home="$REAL_USER_HOME"
    
    # Get the current shell for the real user
    if [[ -n "$SUDO_USER" ]]; then
        # Running with sudo - get the real user's shell
        shell_name=$(basename "$(sudo -u "$SUDO_USER" echo "$SHELL")")
    else
        # Not running with sudo - use current shell
        if [[ -n "$SHELL" ]]; then
            shell_name=$(basename "$SHELL")
        else
            shell_name=$(basename "$(ps -p $$ -o comm=)")
        fi
    fi
    
    case "$shell_name" in
        bash)
            rc_file="$real_home/.bashrc"
            ;;
        zsh)
            rc_file="$real_home/.zshrc"
            ;;
        fish)
            rc_file="$real_home/.config/fish/config.fish"
            ;;
        *)
            echo "Warning: Unsupported shell '$shell_name'. Defaulting to bash."
            shell_name="bash"
            rc_file="$real_home/.bashrc"
            ;;
    esac
    
    echo "$shell_name|$rc_file"
}

# Function to setup shell integration
setup_shell_integration() {
    local shell_info
    shell_info=$(detect_shell)
    local shell_name=$(echo "$shell_info" | cut -d'|' -f1)
    local rc_file=$(echo "$shell_info" | cut -d'|' -f2)
    
    echo "Detected shell: $shell_name"
    echo "RC file: $rc_file"
    
    # Ensure ~/.local/bin is in PATH
    if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]] && ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo "Adding ~/.local/bin to PATH..."
        if ! grep -q "\.local/bin" "$rc_file" 2>/dev/null; then
            echo "" >> "$rc_file"
            echo "# Add ~/.local/bin to PATH" >> "$rc_file"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc_file"
            echo "Added ~/.local/bin to PATH in $rc_file"
        else
            echo "~/.local/bin already in PATH"
        fi
    fi
    
    # Create refocus shell shell integration file
    local focus_shell_file="$REAL_USER_HOME/.local/refocus/shell-integration.sh"
    local focus_dir=$(dirname "$focus_shell_file")
    
    # Create focus directory if it doesn't exist
    if [[ ! -d "$focus_dir" ]]; then
        mkdir -p "$focus_dir"
    fi
    
    # Create refocus shell shell integration file with improved error handling
    cat > "$focus_shell_file" << 'EOF'
#!/usr/bin/env bash
# Refocus Shell Shell Integration
# This file is automatically managed by refocus shell

function update-prompt(){
    # Refocus shell shell integration
    # This function is automatically managed by refocus shell

    # Get the database path
    REFOCUS_DB="$HOME/.local/refocus/refocus.db"

    # Check if database exists and get current prompt content
    if [[ -f "$REFOCUS_DB" ]]; then
        # Get the prompt content from database with better error handling
        PROMPT_CONTENT=$(sqlite3 "$REFOCUS_DB" "SELECT prompt_content FROM state WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$PROMPT_CONTENT" ]]; then
            # Set PS1 directly from database content
            export PS1="$PROMPT_CONTENT"
            return 0
        fi
    fi
    
    # If no prompt found in database, use default
    export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01:34m\]\w\[\033[00m\]\$ '
    return 0
}

# Auto-update prompt on shell startup if focus is active
if [[ -f "$HOME/.local/refocus/refocus.db" ]]; then
    # Check if focus is currently active
    ACTIVE_STATE=$(sqlite3 "$HOME/.local/refocus/refocus.db" "SELECT active FROM state WHERE id = 1;" 2>/dev/null)
    if [[ "$ACTIVE_STATE" == "1" ]]; then
        update-prompt
    fi
fi
EOF
    
    # Make the file executable
    chmod +x "$focus_shell_file"
    echo "Created refocus shell shell integration: $focus_shell_file"
    
    # Add shell integration to bashrc
    if ! grep -q "source.*focus/shell-integration.sh" "$rc_file" 2>/dev/null; then
        echo "" >> "$rc_file"
        echo "# Refocus shell shell integration" >> "$rc_file"
        echo "source $focus_shell_file" >> "$rc_file"
        echo "Added refocus shell shell integration to $rc_file"
    else
        echo "Refocus shell shell integration already sourced in $rc_file"
    fi
    
    # Also add to .bash_profile for login shells if it doesn't exist or doesn't source bashrc
    local bash_profile="$REAL_USER_HOME/.bash_profile"
    if [[ ! -f "$bash_profile" ]]; then
        cat > "$bash_profile" << 'EOF'
# ~/.bash_profile: executed by bash(1) for login shells.
# see /usr/share/doc/bash/examples/startup-files for examples.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
EOF
        echo "Created .bash_profile to ensure shell integration works in login shells"
    elif ! grep -q "\.bashrc" "$bash_profile" 2>/dev/null; then
        # Add bashrc sourcing to existing bash_profile
        echo "" >> "$bash_profile"
        echo "# include .bashrc if it exists" >> "$bash_profile"
        echo "if [ -f \"\$HOME/.bashrc\" ]; then" >> "$bash_profile"
        echo "    . \"\$HOME/.bashrc\"" >> "$bash_profile"
        echo "fi" >> "$bash_profile"
        echo "Added .bashrc sourcing to existing .bash_profile"
    fi
    
    # Also add to .profile for systems that use it
    local profile_file="$REAL_USER_HOME/.profile"
    if [[ -f "$profile_file" ]] && ! grep -q "\.bashrc" "$profile_file" 2>/dev/null; then
        echo "" >> "$profile_file"
        echo "# include .bashrc if it exists" >> "$profile_file"
        echo "if [ -f \"\$HOME/.bashrc\" ]; then" >> "$profile_file"
        echo "    . \"\$HOME/.bashrc\"" >> "$profile_file"
        echo "fi" >> "$profile_file"
        echo "Added .bashrc sourcing to .profile"
    fi
    
    echo "Shell integration configured successfully"
    print_verbose_note "You may need to restart your terminal or run 'source $rc_file' for changes to take effect"
}

# Function to clean up old bashrc backups
cleanup_old_bashrc_backups() {
    local bashrc_file="$REAL_USER_HOME/.bashrc"
    local backup_dir=$(dirname "$bashrc_file")
    local backup_pattern="${bashrc_file}.backup.*"
    
    # Keep only the 3 most recent backups
    local backup_count
    backup_count=$(find "$backup_dir" -name "$(basename "$backup_pattern")" 2>/dev/null | wc -l)
    
    if [[ $backup_count -gt 3 ]]; then
        print_status "Cleaning up old bashrc backups (keeping 3 most recent)..."
        find "$backup_dir" -name "$(basename "$backup_pattern")" -printf '%T@ %p\n' | sort -n | head -n -3 | cut -d' ' -f2- | xargs rm -f 2>/dev/null || true
        print_success "Old bashrc backups cleaned up"
    fi
}

# Function to remove shell integration
remove_shell_integration() {
    local shell_info
    shell_info=$(detect_shell)
    local shell_name=$(echo "$shell_info" | cut -d'|' -f1)
    local rc_file=$(echo "$shell_info" | cut -d'|' -f2)
    
    echo "Detected shell: $shell_name"
    echo "RC file: $rc_file"
    
    # Remove refocus shell shell integration from bashrc
    if grep -q "source.*focus/shell-integration.sh" "$rc_file" 2>/dev/null; then
        # Create backup of bashrc before modifying
        local backup_file="${rc_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$rc_file" "$backup_file"
        
        # Remove refocus shell shell integration lines
        sed -i '/# Refocus shell shell integration/,/source.*focus\/shell-integration.sh/d' "$rc_file"
        
        echo "Refocus shell shell integration removed from $rc_file"
        echo "Backup created at $backup_file"
        
        # Clean up old bashrc backups
        cleanup_old_bashrc_backups
    else
        echo "No refocus shell shell integration found in $rc_file"
    fi
    
    # Remove the shell integration file
    local focus_shell_file="$REAL_USER_HOME/.local/refocus/shell-integration.sh"
    if [[ -f "$focus_shell_file" ]]; then
        rm -f "$focus_shell_file"
        echo "Removed refocus shell shell integration file: $focus_shell_file"
    fi
}

# Function to setup focus function (alternative to shell integration)
setup_focus_function() {
    local shell_info
    shell_info=$(detect_shell)
    local shell_name=$(echo "$shell_info" | cut -d'|' -f1)
    local rc_file=$(echo "$shell_info" | cut -d'|' -f2)
    
    print_verbose "Detected shell: $shell_name"
    print_verbose "RC file: $rc_file"
    
    # Check if focus script is installed
    local focus_script_installed=false
    if [[ -f "$HOME/.local/bin/focus" ]]; then
        focus_script_installed=true
    elif [[ -f "/usr/local/bin/focus" ]]; then
        focus_script_installed=true
    elif [[ -f "/usr/bin/focus" ]]; then
        focus_script_installed=true
    fi
    
    if [[ "$focus_script_installed" == "false" ]]; then
        echo "❌ Focus script is not installed. Please install it first:"
        echo "   ./setup.sh install"
        echo ""
        echo "The focus function requires the focus script to be installed."
        return 1
    fi
    
    # Copy focus function to installed location
    local focus_function_file="$REAL_USER_HOME/.local/refocus/lib/focus-function.sh"
    local focus_dir=$(dirname "$focus_function_file")
    
    # Create focus directory if it doesn't exist
    if [[ ! -d "$focus_dir" ]]; then
        mkdir -p "$focus_dir"
    fi
    
    # Copy the focus function file
    if [[ -f "$SCRIPT_DIR/lib/focus-function.sh" ]]; then
        cp "$SCRIPT_DIR/lib/focus-function.sh" "$focus_function_file"
        chmod +x "$focus_function_file"
        print_verbose "Installed focus function: $focus_function_file"
    else
        echo "❌ Focus function file not found: $SCRIPT_DIR/lib/focus-function.sh"
        return 1
    fi
    
    # Add focus function sourcing to bashrc
    if ! grep -q "source.*focus/lib/focus-function.sh" "$rc_file" 2>/dev/null; then
        echo "" >> "$rc_file"
        echo "# Refocus shell function (alternative to shell integration)" >> "$rc_file"
        echo "source $focus_function_file" >> "$rc_file"
        print_verbose "Added focus function to $rc_file"
    else
        print_verbose "Focus function already sourced in $rc_file"
    fi
    
    # Also add to .bash_profile for login shells
    local bash_profile="$REAL_USER_HOME/.bash_profile"
    if [[ ! -f "$bash_profile" ]]; then
        cat > "$bash_profile" << 'EOF'
# ~/.bash_profile: executed by bash(1) for login shells.
# see /usr/share/doc/bash/examples/startup-files for examples.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
EOF
        echo "Created .bash_profile to ensure focus function works in login shells"
    elif ! grep -q "\.bashrc" "$bash_profile" 2>/dev/null; then
        # Add bashrc sourcing to existing bash_profile
        echo "" >> "$bash_profile"
        echo "# include .bashrc if it exists" >> "$bash_profile"
        echo "if [ -f \"\$HOME/.bashrc\" ]; then" >> "$bash_profile"
        echo "    . \"\$HOME/.bashrc\"" >> "$bash_profile"
        echo "fi" >> "$bash_profile"
        echo "Added .bashrc sourcing to existing .bash_profile"
    fi
    
    # Also add to .profile for systems that use it
    local profile_file="$REAL_USER_HOME/.profile"
    if [[ -f "$profile_file" ]] && ! grep -q "\.bashrc" "$profile_file" 2>/dev/null; then
        echo "" >> "$profile_file"
        echo "# include .bashrc if it exists" >> "$profile_file"
        echo "if [ -f \"\$HOME/.bashrc\" ]; then" >> "$profile_file"
        echo "    . \"\$HOME/.bashrc\"" >> "$profile_file"
        echo "fi" >> "$profile_file"
        echo "Added .bashrc sourcing to .profile"
    fi
    
    # Create update-prompt function directly in .bashrc
    if ! grep -q "function update-prompt" "$rc_file" 2>/dev/null; then
        echo "" >> "$rc_file"
        echo "# Refocus shell functions" >> "$rc_file"
        cat >> "$rc_file" << 'EOF'
function update-prompt(){
    # Refocus shell shell integration
    # This function is automatically managed by refocus shell

    # Get the database path
    REFOCUS_DB="$HOME/.local/refocus/refocus.db"

    # Check if database exists and get current prompt file
    if [[ -f "$REFOCUS_DB" ]]; then
        # Get the prompt file from database
        PROMPT_FILE=$(sqlite3 "$REFOCUS_DB" "SELECT prompt_file FROM state WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$PROMPT_FILE" ]] && [[ -f "$PROMPT_FILE" ]]; then
            # Source the prompt file to set PS1
            source "$PROMPT_FILE"
        fi
    fi
}
EOF
        print_verbose "Added update-prompt function to $rc_file"
    else
        print_verbose "update-prompt function already exists in $rc_file"
    fi
    
    echo ""
    print_success "Focus function configured successfully"
    print_verbose_note "Run 'source ~/.bashrc' or restart your terminal to use the 'focus' function immediately."
    print_verbose_note "The focus function will be available in new terminals automatically."
}

# Function to remove focus function
remove_focus_function() {
    local shell_info
    shell_info=$(detect_shell)
    local shell_name=$(echo "$shell_info" | cut -d'|' -f1)
    local rc_file=$(echo "$shell_info" | cut -d'|' -f2)
    
    echo "Detected shell: $shell_name"
    echo "RC file: $rc_file"
    
    # Remove focus function from bashrc
    if grep -q "source.*focus/lib/focus-function.sh" "$rc_file" 2>/dev/null; then
        # Create backup of bashrc before modifying
        local backup_file="${rc_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$rc_file" "$backup_file"
        
        # Remove focus function lines
        sed -i '/# Refocus shell function (alternative to shell integration)/,/source.*focus\/lib\/focus-function.sh/d' "$rc_file"
        
        echo "Focus function removed from $rc_file"
        echo "Backup created at $backup_file"
        
        # Clean up old bashrc backups
        cleanup_old_bashrc_backups
    else
        echo "Focus function not found in $rc_file"
    fi
    
    # Remove focus function file
    local focus_function_file="$REAL_USER_HOME/.local/refocus/lib/focus-function.sh"
    if [[ -f "$focus_function_file" ]]; then
        rm "$focus_function_file"
        echo "Removed focus function file: $focus_function_file"
    fi
    
    echo "Focus function removed successfully"
    
    # Remove update-prompt function from .bashrc if it exists
    if grep -q "function update-prompt" "$rc_file" 2>/dev/null; then
        # Create backup of bashrc before modifying
        local backup_file="${rc_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$rc_file" "$backup_file"
        
        # Remove the update-prompt function and its comment block
        sed -i '/# Refocus shell functions/,/^}$/d' "$rc_file"
        
        echo "update-prompt function removed from $rc_file"
        echo "Backup created at $backup_file"
    fi
    
    # Unset focus-related functions from current shell session if they exist
    local focus_functions=("focus" "update-prompt" "focus-update-prompt" "focus-restore-prompt")
    for func in "${focus_functions[@]}"; do
        if type "$func" >/dev/null 2>&1; then
            unset -f "$func"
            echo "Function '$func' unset from current shell session"
        fi
    done
}

# Parse command line arguments
COMMAND="install"
DB_PATH="$DB_DEFAULT"
INSTALL_DIR="$INSTALL_DIR_DEFAULT"
INTERACTIVE=true
VERBOSE=false

# Function to show usage (defined after variables are set)
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install     Install refocus shell (interactive)"
    echo "  uninstall   Uninstall focus script and database (interactive)"
    echo "  deps        Install dependencies only"
    echo "  shell-setup Install shell integration (adds prompt.sh and shell_integration.sh)"
    echo "  function-setup Install focus function (alternative to shell integration)"
    echo "  function-remove Remove focus function"
    echo ""
    echo "Options:"
    echo "  --install-dir DIR    Set installation directory (default: $INSTALL_DIR_DEFAULT)"
    echo "  --db-path PATH       Set database path (default: $DB_DEFAULT)"
    echo "  --auto               Non-interactive mode (uses defaults)"
    echo "  --verbose            Show detailed installation information"
    echo "  -h, --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 install                    # Interactive installation with method choice"
    echo "  $0 uninstall                  # Interactive uninstallation"
    echo "  $0 --install-dir ~/.local/bin install  # Install to custom location"
    echo "  $0 --auto install             # Non-interactive installation"
    echo "  $0 shell-setup                # Install shell integration"
    echo "  $0 function-setup             # Install focus function"
    echo "  $0 function-remove            # Remove focus function"
    echo ""
    echo "Installation Methods:"
    echo "  Function (default): Automatic prompt updates, works in all shells"
    echo "  Script: Traditional executable, requires manual update-prompt calls"
    echo ""
    print_verbose_note "The install command will prompt for paths and method interactively unless"
    print_verbose_note "--install-dir and --db-path options are provided."
}

while [[ $# -gt 0 ]]; do
    case $1 in
        install|uninstall|deps|shell-setup|function-setup|function-remove)
            COMMAND="$1"
            shift
            ;;
        --install-dir)
            INSTALL_DIR="$2"
            INTERACTIVE=false
            shift 2
            ;;
        --db-path)
            DB_PATH="$2"
            INTERACTIVE=false
            shift 2
            ;;
        --auto)
            INTERACTIVE=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
case "$COMMAND" in
    install)
        set_abort_message "install"
        # Interactive setup for installation (only if no options provided)
        if [[ "$INTERACTIVE" == "true" ]]; then
            # No options provided, use interactive setup
            setup_paths
        else
            # Non-interactive mode - use defaults or provided options
            INSTALL_METHOD="a"  # Default to function installation for auto mode
            echo "Non-interactive installation:"
            echo "  Database: $DB_PATH"
            echo "  Script: $INSTALL_DIR/focus"
            echo "  Method: Function installation (automatic prompt updates)"
            echo ""
            echo "----"
            echo ""
        fi
        print_verbose "Installing refocus shell..."
        install_dependencies
        init_database "$DB_PATH"
        install_script
        install_commands
        install_nudge_script
        
        # Install based on chosen method
        setup_focus_function
        
        # For function mode, remove focus script from PATH after function is set up
        if [[ "$INSTALL_METHOD" == "a" ]]; then
            print_verbose "Removing focus script from PATH for function mode"
            rm -f "$INSTALL_DIR/$SCRIPT_NAME"
        fi
        
        setup_cron_job
        print_success "Cron job installed successfully"
        echo "Usage: crontab -l to see current values. Refer to documentation for details."
        
        echo ""
        echo "----"
        echo ""
        echo "✅ Installation complete!"
        echo "🔄 Run 'source ~/.bashrc' or open a new terminal to be able to access refocus shell."
        ;;
    uninstall)
        set_abort_message "uninstall"
        print_status "Uninstalling refocus shell..."
        
        # Check if database exists
        if [[ -f "$DB_PATH" ]]; then
            print_status "Found database at: $DB_PATH"
        else
            print_warning "Database not found at: $DB_PATH"
        fi
        remove_shell_integration
        remove_focus_function
        
        # Check if focus directory exists and ask user about cleanup
        focus_dir=$(dirname "$DB_PATH")
        if [[ -d "$focus_dir" ]]; then
            echo ""
            echo "Focus directory found: $focus_dir"
            echo "This directory may contain additional files (libraries, commands, etc.)."
            read -p "Remove entire focus directory? (Y/n): " REMOVE_DIR
            REMOVE_DIR="${REMOVE_DIR:-Y}"
            
            if [[ "$REMOVE_DIR" =~ ^[Yy]$ ]]; then
                print_status "Removing focus directory: $focus_dir"
                rm -rf "$focus_dir"
                print_success "Focus directory removed"
            else
                echo "Focus directory left intact at: $focus_dir"
            fi
        fi
        
        # Remove focus script (check both possible locations)
if [[ -f "$INSTALL_DIR/focus" ]]; then
    print_status "Uninstalling focus script from: $INSTALL_DIR/focus"
    rm -f "$INSTALL_DIR/focus"
    print_success "Focus script uninstalled from $INSTALL_DIR/focus"
fi

if [[ -f "$REAL_USER_HOME/.local/refocus/focus" ]]; then
    print_status "Uninstalling focus script from: $REAL_USER_HOME/.local/refocus/focus"
    rm -f "$REAL_USER_HOME/.local/refocus/focus"
    print_success "Focus script uninstalled from $REAL_USER_HOME/.local/refocus/focus"
fi
        
        # Remove focus-nudge script
        if [[ -f "$REAL_USER_HOME/.local/refocus/focus-nudge" ]]; then
            print_status "Uninstalling focus-nudge script from: $REAL_USER_HOME/.local/refocus/focus-nudge"
            rm -f "$REAL_USER_HOME/.local/refocus/focus-nudge"
            print_success "Focus-nudge script uninstalled from $REAL_USER_HOME/.local/refocus/focus-nudge"
        fi
        
        # Remove cron job
        print_status "Removing cron job for nudging..."
        (crontab -l 2>/dev/null | grep -v "focus-nudge" || true) | crontab -
        print_success "Cron job removed successfully"
        
        print_success "Uninstallation complete!"
        ;;
    deps)
        set_abort_message "deps"
        print_status "Installing dependencies..."
        install_dependencies
        print_success "Dependencies installation complete!"
        ;;
    shell-setup)
        set_abort_message "shell-setup"
        print_status "Setting up shell integration..."
        setup_shell_integration
        print_success "Shell integration setup complete!"
        ;;
    function-setup)
        set_abort_message "function-setup"
        print_status "Setting up focus function..."
        setup_focus_function
        print_success "Focus function setup complete!"
        echo ""
        print_verbose_note "Run 'source ~/.bashrc' or restart your terminal to use the 'focus' function immediately."
        print_verbose_note "The focus function will be available in new terminals automatically."
        ;;
    function-remove)
        set_abort_message "function-remove"
        print_status "Removing focus function..."
        remove_focus_function
        print_success "Focus function removed!"
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

# Only refresh shell environment for install operations
if [[ "$COMMAND" == "install" ]] || [[ "$COMMAND" == "function-setup" ]] || [[ "$COMMAND" == "shell-setup" ]]; then
    echo ""
    echo "🔄 Refreshing shell environment..."
    source ~/.bashrc
    exec "$SHELL" -l
fi
