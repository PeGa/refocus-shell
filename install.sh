#!/usr/bin/env bash

set -e

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
SCRIPT_NAME="work"
# Use the real user's home directory, not the effective user's
REAL_USER_HOME=$(eval echo ~$(logname 2>/dev/null || echo $SUDO_USER 2>/dev/null || echo $USER))
DB_DEFAULT="$REAL_USER_HOME/.local/work/timelog.db"
WORK_DATA_PATH="$REAL_USER_HOME/.local/work"

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
        read -p "Create directory '$path'? (y/N): " CREATE_DIR
        if [[ "$CREATE_DIR" =~ ^[Yy]$ ]]; then
            echo "[INFO] Creating directory: $path"
            mkdir -p "$path"
            if [[ $? -ne 0 ]]; then
                echo "[ERROR] Failed to create directory: $path"
                exit 1
            fi
            echo "[SUCCESS] Directory created successfully"
        else
            echo "Installation aborted."
            exit 0
        fi
    fi
}

# Interactive path setup for installation
setup_paths() {
    echo "Work Manager Installation"
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
    echo "Where should the work script be installed?"
    if [[ "$EUID" -eq 0 ]]; then
        echo "Note: Running with sudo - system-wide installation recommended"
    else
        echo "Note: /usr/local/bin requires sudo, ~/.local/bin is recommended for users"
    fi
    read -p "Installation directory (default: $INSTALL_DIR_DEFAULT): " INSTALL_DIR_INPUT
    INSTALL_DIR="${INSTALL_DIR_INPUT:-$INSTALL_DIR_DEFAULT}"
    
    # Validate installation directory
    validate_and_create_dir "$INSTALL_DIR" "installation directory"
    
    echo ""
    echo "Installation Summary:"
    echo "  Database: $DB_PATH"
    echo "  Script: $INSTALL_DIR/work"
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
        echo "Error: Work script is not installed at: $script_path"
        has_error=true
    fi
    
    # Check if database exists
    if [[ ! -f "$db_path" ]]; then
        echo "Error: Database file not found at: $db_path"
        has_error=true
    fi
    
    if [[ "$has_error" == "true" ]]; then
        echo ""
        echo "Work manager is not installed at the specified locations."
        echo "Please check the installation directory and database path."
        return 1
    fi
    
    return 0
}

# Interactive path setup for uninstallation
setup_uninstall_paths() {
    echo "Work Manager Uninstallation"
    echo "=========================="
    echo ""
    
    while true; do
        # Installation directory
        echo "Where is the work script installed?"
        if [[ "$EUID" -eq 0 ]]; then
            echo "Note: Running with sudo - checking system-wide installation"
        else
            echo "Note: Common locations: ~/.local/bin, /usr/local/bin, /usr/bin"
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
        echo "  Script: $INSTALL_DIR/work"
        echo "  Database: $DB_PATH"
        echo ""
        
        # Validate paths exist
        if validate_paths_exist "$INSTALL_DIR/work" "$DB_PATH"; then
            break
        else
            echo ""
            read -p "Press Enter to try again or Ctrl+C to abort..."
            echo ""
        fi
    done
    
    read -p "Continue with uninstallation? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
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
    
    # If no missing dependencies, we're done
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        print_status "All dependencies are already available"
        return 0
    fi
    
    print_status "Installing missing dependencies: ${missing_deps[*]}"
    
    # Detect distribution and install appropriate packages
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        print_status "Detected Debian/Ubuntu. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite3")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify-bin")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo apt-get update && sudo apt-get install -y "${packages[@]}"
        fi
    elif command -v pacman >/dev/null 2>&1; then
        # Arch/Manjaro
        print_status "Detected Arch/Manjaro. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo pacman -S --noconfirm "${packages[@]}"
        fi
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL
        print_status "Detected Fedora/RHEL. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo dnf install -y "${packages[@]}"
        fi
    elif command -v zypper >/dev/null 2>&1; then
        # openSUSE
        print_status "Detected openSUSE. Installing packages..."
        local packages=()
        [[ " ${missing_deps[*]} " =~ " sqlite3 " ]] && packages+=("sqlite3")
        [[ " ${missing_deps[*]} " =~ " notify-send " ]] && packages+=("libnotify-tools")
        
        if [[ ${#packages[@]} -gt 0 ]]; then
            sudo zypper install -y "${packages[@]}"
        fi
    else
        print_warning "Could not detect package manager. Please install dependencies manually."
        echo "Required packages:"
        echo "  - sqlite3 (for database operations)"
        echo "  - notify-send (for desktop notifications)"
        echo ""
        echo "Common package names by distribution:"
        echo "  Ubuntu/Debian: sqlite3, libnotify-bin"
        echo "  Arch/Manjaro: sqlite, libnotify"
        echo "  Fedora/RHEL: sqlite, libnotify"
        echo "  openSUSE: sqlite3, libnotify-tools"
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
    
    print_status "Initializing database at: $db_path"
    
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
            prompt_file TEXT,
            nudging_enabled BOOLEAN DEFAULT 1,
            work_disabled BOOLEAN DEFAULT 0
        );
        
        CREATE TABLE IF NOT EXISTS sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL
        );
        
        INSERT OR IGNORE INTO state (id, active, project, start_time, prompt_file, nudging_enabled, work_disabled) 
        VALUES (1, 0, NULL, NULL, NULL, 1, 0);
    "
    
    # Fix ownership if running with sudo
    if [[ "$EUID" -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
        print_status "Fixing database ownership for user: $SUDO_USER"
        chown "$SUDO_USER:$SUDO_USER" "$db_path"
        chown -R "$SUDO_USER:$SUDO_USER" "$db_dir"
    fi
    
    print_success "Database initialized successfully"
}

# Function to reset database
reset_database() {
    local db_path="$1"
    
    print_status "Resetting database at: $db_path"
    
    # Remove the database file
    rm -f "$db_path"
    print_status "Database deleted."
    
    # Reinitialize the database
    init_database "$db_path"
    print_success "Database reset complete."
}

# Function to install the work script
install_script() {
    local target_path="$INSTALL_DIR/$SCRIPT_NAME"
    local work_script=""
    
    # Find the work script
    if [[ -f "./work" ]]; then
        work_script="./work"
    elif [[ -f "$(dirname "$0")/work" ]]; then
        work_script="$(dirname "$0")/work"
    else
        print_error "Could not find work script"
        exit 1
    fi
    
    local work_script_path="$(readlink -f "$work_script")"
    
    # Check if already installed and up to date
    if [[ -f "$target_path" ]]; then
        local installed_hash=$(sha256sum "$target_path" 2>/dev/null | cut -d' ' -f1)
        local current_hash=$(sha256sum "$work_script_path" 2>/dev/null | cut -d' ' -f1)
        
        if [[ "$installed_hash" == "$current_hash" ]]; then
            print_status "Work script already installed and up to date at $target_path"
            return 0
        else
            print_status "Updating existing installation at $target_path"
        fi
    fi
    
    print_status "Installing work script to: $target_path"
    
    # Check if we have write permissions
    if [[ ! -w "$INSTALL_DIR" ]] && [[ "$EUID" -ne 0 ]]; then
        print_error "No write permission to $INSTALL_DIR. Run with sudo or set INSTALL_DIR to a writable location."
        exit 1
    fi
    
    # Copy the work script
    cp "$work_script_path" "$target_path"
    chmod +x "$target_path"
    
    print_success "Work script installed successfully to $target_path"
    print_status "You can now use 'work' command from anywhere"
}

# Function to uninstall the work script
uninstall_script() {
    local target_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    print_status "Uninstalling work script from: $target_path"
    
    if [[ ! -f "$target_path" ]]; then
        print_warning "Work script not found at $target_path"
        return 0
    fi
    
    # Check if we have write permissions
    if [[ ! -w "$INSTALL_DIR" ]] && [[ "$EUID" -ne 0 ]]; then
        print_error "No write permission to $INSTALL_DIR. Run with sudo or set INSTALL_DIR to a writable location."
        exit 1
    fi
    
    # Remove the script
    rm -f "$target_path"
    print_success "Work script uninstalled from $target_path"
}

# Function to install work-nudge script
install_nudge_script() {
    local nudge_script=""
    local target_path="$WORK_DATA_PATH/work-nudge"
    
    # Find the work-nudge script
    if [[ -f "./work-nudge" ]]; then
        nudge_script="./work-nudge"
    elif [[ -f "$(dirname "$0")/work-nudge" ]]; then
        nudge_script="$(dirname "$0")/work-nudge"
    else
        print_error "Could not find work-nudge script"
        return 1
    fi
    
    local nudge_script_path="$(readlink -f "$nudge_script")"
    
    # Create work data directory if it doesn't exist
    mkdir -p "$WORK_DATA_PATH"
    
    print_status "Installing work-nudge script to: $target_path"
    
    # Copy the work-nudge script
    cp "$nudge_script_path" "$target_path"
    chmod +x "$target_path"
    
    # Fix ownership if running with sudo
    if [[ "$EUID" -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$target_path"
    fi
    
    print_success "Work-nudge script installed successfully to $target_path"
}

# Function to uninstall work-nudge script
uninstall_nudge_script() {
    local target_path="$WORK_DATA_PATH/work-nudge"
    
    print_status "Uninstalling work-nudge script from: $target_path"
    
    if [[ ! -f "$target_path" ]]; then
        print_warning "Work-nudge script not found at $target_path"
        return 0
    fi
    
    # Remove the script
    rm -f "$target_path"
    print_success "Work-nudge script uninstalled from $target_path"
}

# Function to setup cron job for nudging
setup_cron_job() {
    local nudge_script="$WORK_DATA_PATH/work-nudge"
    local cron_entry="*/10 * * * * $nudge_script"
    local temp_cron_file="/tmp/work_cron_$$"
    
    print_status "Setting up cron job for nudging..."
    
    # Check if work-nudge script exists
    if [[ ! -f "$nudge_script" ]]; then
        print_error "Work-nudge script not found. Cannot setup cron job."
        return 1
    fi
    
    # Get current crontab
    crontab -l 2>/dev/null > "$temp_cron_file" || true
    
    # Check if cron job already exists
    if grep -q "$nudge_script" "$temp_cron_file" 2>/dev/null; then
        print_status "Cron job already exists"
        rm -f "$temp_cron_file"
        return 0
    fi
    
    # Add the cron job
    echo "$cron_entry" >> "$temp_cron_file"
    
    # Install the new crontab
    if crontab "$temp_cron_file"; then
        print_success "Cron job installed successfully"
        print_status "Nudging will occur every 10 minutes"
    else
        print_error "Failed to install cron job"
        rm -f "$temp_cron_file"
        return 1
    fi
    
    rm -f "$temp_cron_file"
}

# Function to remove cron job for nudging
remove_cron_job() {
    local nudge_script="$WORK_DATA_PATH/work-nudge"
    local temp_cron_file="/tmp/work_cron_$$"
    
    print_status "Removing cron job for nudging..."
    
    # Get current crontab
    crontab -l 2>/dev/null > "$temp_cron_file" || true
    
    # Remove the cron job if it exists
    if grep -q "$nudge_script" "$temp_cron_file" 2>/dev/null; then
        # Remove lines containing the nudge script
        sed -i "\|$nudge_script|d" "$temp_cron_file"
        
        # Install the updated crontab
        if crontab "$temp_cron_file"; then
            print_success "Cron job removed successfully"
        else
            print_error "Failed to remove cron job"
            rm -f "$temp_cron_file"
            return 1
        fi
    else
        print_status "No cron job found to remove"
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
    
    # Create bash functions file
    local functions_file="$REAL_USER_HOME/.bash_functions"
    
    # Create the functions file if it doesn't exist
    if [[ ! -f "$functions_file" ]]; then
        touch "$functions_file"
        echo "Created bash functions file: $functions_file"
    fi
    
    # Add work manager functions to bash_functions
    if ! grep -q "update-prompt" "$functions_file" 2>/dev/null; then
        echo "" >> "$functions_file"
        echo "# Work manager functions" >> "$functions_file"
        cat >> "$functions_file" << 'EOF'
function update-prompt(){
    # Work manager shell integration
    # This function is automatically managed by work manager

    # Get the database path
    WORK_DB="$HOME/.local/work/timelog.db"

    # Check if database exists and get current prompt file
    if [[ -f "$WORK_DB" ]]; then
        # Get the prompt file from database
        PROMPT_FILE=$(sqlite3 "$WORK_DB" "SELECT prompt_file FROM state WHERE id = 1;" 2>/dev/null)
        
        if [[ -n "$PROMPT_FILE" ]] && [[ -f "$PROMPT_FILE" ]]; then
            # Source the prompt file to set PS1
            source "$PROMPT_FILE"
        fi
    fi
}
EOF
        echo "Added update-prompt function to $functions_file"
    else
        echo "update-prompt function already exists in $functions_file"
    fi
    
    # Check if bash_functions is sourced in bashrc
    if ! grep -q "source.*bash_functions" "$rc_file" 2>/dev/null; then
        echo "" >> "$rc_file"
        echo "# Source bash functions" >> "$rc_file"
        echo "source $functions_file" >> "$rc_file"
        echo "Added bash_functions source to $rc_file"
    else
        echo "bash_functions already sourced in $rc_file"
    fi
    
    echo "Shell integration configured successfully"
    echo "Note: You may need to restart your terminal or run 'source $rc_file' for changes to take effect"
}

# Function to remove shell integration
remove_shell_integration() {
    local shell_info
    shell_info=$(detect_shell)
    local shell_name=$(echo "$shell_info" | cut -d'|' -f1)
    local rc_file=$(echo "$shell_info" | cut -d'|' -f2)
    
    echo "Detected shell: $shell_name"
    echo "RC file: $rc_file"
    
    # Remove work manager functions from bash_functions
    local functions_file="$REAL_USER_HOME/.bash_functions"
    if [[ -f "$functions_file" ]]; then
        # Create backup
        cp "$functions_file" "${functions_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Remove work manager functions
        sed -i '/# Work manager functions/,/^}$/d' "$functions_file"
        
        echo "Work manager functions removed from $functions_file"
        echo "Backup created at ${functions_file}.backup.$(date +%Y%m%d_%H%M%S)"
    else
        echo "bash_functions file not found"
    fi
    
    # Note: We don't remove the bash_functions source from bashrc
    # as it might contain other user functions
    echo "Note: bash_functions source line left in $rc_file (may contain other functions)"
}

# Parse command line arguments
COMMAND="install"
DB_PATH="$DB_DEFAULT"
INSTALL_DIR="$INSTALL_DIR_DEFAULT"
INTERACTIVE=true

# Function to show usage (defined after variables are set)
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install     Install work script to system (interactive)"
    echo "  uninstall   Uninstall work script and database (interactive)"
    echo "  init        Initialize database only"
    echo "  reset       Reset database (delete all data)"
    echo "  deps        Install dependencies only"
    echo "  shell-setup Install shell integration (adds prompt.sh and shell_integration.sh)"
    echo ""
    echo "Options:"
    echo "  --install-dir DIR    Set installation directory (default: $INSTALL_DIR_DEFAULT)"
    echo "  --db-path PATH       Set database path (default: $DB_DEFAULT)"
    echo "  -h, --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 install                    # Interactive installation"
    echo "  $0 uninstall                  # Interactive uninstallation"
    echo "  $0 --install-dir ~/.local/bin install  # Install to custom location"
    echo "  $0 init                       # Initialize database only"
    echo "  $0 reset                      # Reset database"
    echo "  $0 shell-setup                # Install shell integration"
    echo ""
    echo "Note: The install command will prompt for paths interactively unless"
    echo "      --install-dir and --db-path options are provided."
}

while [[ $# -gt 0 ]]; do
    case $1 in
        install|uninstall|init|reset|deps|shell-setup)
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
        fi
        print_status "Installing work manager..."
        install_dependencies
        init_database "$DB_PATH"
        install_script
        install_nudge_script
        setup_shell_integration
        setup_cron_job
        print_success "Installation complete!"
        ;;
    uninstall)
        set_abort_message "uninstall"
        # Interactive setup for uninstallation (only if no options provided)
        if [[ "$INTERACTIVE" == "true" ]]; then
            # No options provided, use interactive setup
            setup_uninstall_paths
        fi
        print_status "Uninstalling work manager..."
        uninstall_script
        uninstall_nudge_script
        remove_cron_job
        if [[ -f "$DB_PATH" ]]; then
            print_status "Removing database: $DB_PATH"
            rm -f "$DB_PATH"
            print_success "Database removed"
        else
            print_warning "Database not found at: $DB_PATH"
        fi
        remove_shell_integration
        print_success "Uninstallation complete!"
        ;;
    init)
        set_abort_message "init"
        print_status "Initializing database..."
        init_database "$DB_PATH"
        ;;
    reset)
        set_abort_message "reset"
        print_status "Resetting database..."
        reset_database "$DB_PATH"
        ;;
    deps)
        set_abort_message "deps"
        print_status "Installing dependencies..."
        install_dependencies
        ;;
    shell-setup)
        set_abort_message "shell-setup"
        print_status "Setting up shell integration..."
        setup_shell_integration
        print_success "Shell integration setup complete!"
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac 