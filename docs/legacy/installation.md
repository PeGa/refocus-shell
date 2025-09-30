# Installation Guide

This comprehensive guide covers all installation methods, system requirements, and platform-specific instructions for Refocus Shell.

## System Requirements

### Supported Platforms
- **Linux distributions**: Ubuntu, Debian, Fedora, Arch, openSUSE, and derivatives
- **Shell**: Bash 4.0 or later (most modern Linux systems)
- **Architecture**: x86_64, ARM64 (Raspberry Pi, Apple Silicon via Rosetta)

### Required Dependencies

#### Core Dependencies
- **sqlite3** - Database engine for storing focus sessions
- **notify-send** - Desktop notifications (part of libnotify)
- **jq** - JSON processing for import/export features

#### Optional Dependencies
- **git** - For installation from source and version control integration
- **cron** - For automated nudge notifications (usually pre-installed)

### Package Names by Distribution

#### Debian/Ubuntu
```bash
sudo apt-get install sqlite3 libnotify-bin jq
```

#### Arch Linux/Manjaro
```bash
sudo pacman -S sqlite libnotify jq
```

#### Fedora/RHEL/CentOS
```bash
sudo dnf install sqlite libnotify jq
```

#### openSUSE
```bash
sudo zypper install sqlite3 libnotify-tools jq
```

#### Alpine Linux
```bash
sudo apk add sqlite libnotify jq
```

## Installation Methods

### Method 1: Interactive Installer (Recommended)

The interactive installer automatically handles dependencies, configuration, and shell integration.

#### Step 1: Download
```bash
# Clone the repository
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell

# Or download and extract release
wget https://github.com/PeGa/refocus-shell/archive/main.zip
unzip main.zip
cd refocus-shell-main
```

#### Step 2: Run Installer
```bash
# Interactive installation
./setup.sh install

# Silent installation (accepts all defaults)
./setup.sh install --silent

# Installation with custom database path
DB_PATH="$HOME/custom/refocus.db" ./setup.sh install
```

#### Step 3: Verify Installation
```bash
# Restart shell or reload configuration
source ~/.bashrc

# Verify installation
focus help
focus status
```

### Method 2: Manual Installation

For users who prefer manual control over the installation process.

#### Step 1: Install Dependencies
```bash
# Check for dependencies
command -v sqlite3 || echo "sqlite3 missing"
command -v notify-send || echo "notify-send missing"
command -v jq || echo "jq missing"

# Install missing dependencies (Ubuntu/Debian example)
sudo apt-get install sqlite3 libnotify-bin jq
```

#### Step 2: Create Directories
```bash
# Create installation directories
mkdir -p ~/.local/bin
mkdir -p ~/.local/refocus/{commands,lib}
```

#### Step 3: Copy Files
```bash
# Copy main executables
cp focus ~/.local/bin/
cp focus-nudge ~/.local/bin/
chmod +x ~/.local/bin/focus
chmod +x ~/.local/bin/focus-nudge

# Copy command modules
cp commands/* ~/.local/refocus/commands/
chmod +x ~/.local/refocus/commands/*

# Copy libraries
cp lib/* ~/.local/refocus/lib/
chmod +x ~/.local/refocus/lib/*

# Copy configuration
cp config.sh ~/.local/refocus/
```

#### Step 4: Shell Integration
```bash
# Add to PATH (if not already there)
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc

# Add function integration
echo 'source ~/.local/refocus/lib/focus-function.sh' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

#### Step 5: Initialize Database
```bash
# Initialize the database
focus init
```

### Method 3: System-Wide Installation

For shared systems or enterprise environments.

#### Step 1: Install to System Directories
```bash
# Install executables
sudo cp focus /usr/local/bin/
sudo cp focus-nudge /usr/local/bin/
sudo chmod +x /usr/local/bin/focus*

# Install support files
sudo mkdir -p /usr/local/share/refocus
sudo cp -r commands/ /usr/local/share/refocus/
sudo cp -r lib/ /usr/local/share/refocus/
sudo cp config.sh /usr/local/share/refocus/

# Set permissions
sudo chmod -R 755 /usr/local/share/refocus
```

#### Step 2: Create System Configuration
```bash
# System-wide configuration
sudo mkdir -p /etc/refocus
sudo cat > /etc/refocus/config.sh << 'EOF'
#!/bin/bash
# System-wide Refocus Shell configuration

# Installation paths
export REFOCUS_SYSTEM_INSTALL=true
export REFOCUS_LIB_DIR="/usr/local/share/refocus/lib"
export REFOCUS_COMMANDS_DIR="/usr/local/share/refocus/commands"

# Default settings
export REFOCUS_NUDGE_INTERVAL=10
export REFOCUS_VERBOSE=false
EOF

sudo chmod 644 /etc/refocus/config.sh
```

#### Step 3: User Setup
Users need to add shell integration:
```bash
# Each user adds to their ~/.bashrc
echo 'source /usr/local/share/refocus/lib/focus-function.sh' >> ~/.bashrc
source ~/.bashrc

# Initialize user database
focus init
```

## Platform-Specific Instructions

### Ubuntu/Debian

#### Standard Installation
```bash
# Update package list
sudo apt-get update

# Install dependencies
sudo apt-get install git sqlite3 libnotify-bin jq

# Install Refocus Shell
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
```

#### Snap Package (Future)
```bash
# Once available
sudo snap install refocus-shell
```

### Arch Linux/Manjaro

#### Using Package Manager
```bash
# Install dependencies
sudo pacman -S git sqlite libnotify jq

# Install Refocus Shell
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
```

#### AUR Package (Future)
```bash
# Using yay
yay -S refocus-shell

# Using paru
paru -S refocus-shell
```

### Fedora/RHEL/CentOS

#### Standard Installation
```bash
# Install dependencies
sudo dnf install git sqlite libnotify jq

# Install Refocus Shell
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
```

#### RPM Package (Future)
```bash
# Once available
sudo dnf install refocus-shell
```

### openSUSE

#### Standard Installation
```bash
# Install dependencies
sudo zypper install git sqlite3 libnotify-tools jq

# Install Refocus Shell
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
```

### Raspberry Pi (ARM)

#### Raspberry Pi OS
```bash
# Update system
sudo apt update && sudo apt upgrade

# Install dependencies
sudo apt install git sqlite3 libnotify-bin jq

# Install Refocus Shell
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
```

#### Performance Notes
- Raspberry Pi 3+ recommended for optimal performance
- Database operations may be slower on older models
- Consider using external storage for large datasets

### WSL (Windows Subsystem for Linux)

#### Prerequisites
```bash
# Ensure WSL2 is being used
wsl --status

# Update WSL
sudo apt update && sudo apt upgrade
```

#### Installation
```bash
# Install dependencies
sudo apt install git sqlite3 libnotify-bin jq

# Install Refocus Shell
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install
```

#### WSL-Specific Considerations
- Desktop notifications may not work (depends on WSL configuration)
- Use `focus nudge disable` if notifications are problematic
- Consider using `focus status` regularly instead of nudges

## Installation Options

### Custom Installation Paths

#### Custom Database Location
```bash
# Install with custom database path
export REFOCUS_DB="/path/to/custom/refocus.db"
./setup.sh install

# Or set permanently
echo 'export REFOCUS_DB="/path/to/custom/refocus.db"' >> ~/.bashrc
```

#### Custom Installation Directory
```bash
# Install to custom directory
export REFOCUS_INSTALL_DIR="$HOME/tools/refocus"
./setup.sh install
```

#### Portable Installation
```bash
# Portable installation (for USB drives, etc.)
export REFOCUS_DATA_DIR="/portable/path/refocus"
export REFOCUS_DB="/portable/path/refocus/refocus.db"
./setup.sh install
```

### Development Installation

#### Development Mode
```bash
# Clone for development
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell

# Install in development mode (uses source directory)
./setup.sh install --dev

# This creates symlinks instead of copying files
# Changes to source files are immediately active
```

#### Contributing Setup
```bash
# Fork and clone your fork
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell

# Add upstream remote
git remote add upstream https://github.com/PeGa/refocus-shell

# Install in development mode
./setup.sh install --dev

# Set up git hooks
cp .githooks/* .git/hooks/
chmod +x .git/hooks/*
```

## Verification and Testing

### Installation Verification

#### Basic Functionality Test
```bash
# Test basic commands
focus help
focus init
focus config show

# Test session management
focus on "test-session"
focus status
focus off

# Test history
focus past list 5

# Test exports
focus export test-backup
ls test-backup.*
```

#### Notification Test
```bash
# Test notification system
focus nudge test

# Enable nudges and test
focus nudge enable
focus on "nudge-test"
# Wait for nudge notification
focus off
```

#### Shell Integration Test
```bash
# Test prompt integration
focus on "prompt-test"
echo $PS1  # Should show focus indicator
focus off
echo $PS1  # Should return to normal
```

### Troubleshooting Installation

#### Common Issues

**Command not found after installation:**
```bash
# Check if PATH includes installation directory
echo $PATH | grep -o '\.local/bin'

# Reload shell configuration
source ~/.bashrc

# Or restart terminal
```

**Database initialization fails:**
```bash
# Check permissions
ls -la ~/.local/refocus/

# Fix permissions
chmod 755 ~/.local/refocus
touch ~/.local/refocus/refocus.db
chmod 644 ~/.local/refocus/refocus.db

# Reinitialize
focus init
```

**Notifications not working:**
```bash
# Test system notifications
notify-send "Test" "This is a test"

# Check desktop environment
echo $XDG_CURRENT_DESKTOP

# Install desktop-specific packages if needed
```

## Upgrading

### Upgrading from Git
```bash
cd refocus-shell
git pull origin main
./setup.sh install  # Overwrites existing installation
```

### Backup Before Upgrade
```bash
# Always backup before upgrading
focus export upgrade-backup-$(date +%Y%m%d)

# Upgrade
cd refocus-shell
git pull
./setup.sh install

# Verify upgrade
focus status
```

### Migration Between Versions
```bash
# Export from old version
focus export migration-backup

# Install new version
# ... installation steps ...

# Import data
focus import migration-backup.json
```

## Uninstallation

### Complete Removal
```bash
# Uninstall Refocus Shell
cd refocus-shell
./setup.sh uninstall

# Remove all data (optional)
rm -rf ~/.local/refocus
rm -rf ~/.config/refocus-shell

# Clean shell configuration
grep -v "refocus" ~/.bashrc > ~/.bashrc.new
mv ~/.bashrc.new ~/.bashrc
```

### Partial Removal (Keep Data)
```bash
# Uninstall but keep data
./setup.sh uninstall --keep-data

# Data remains in ~/.local/refocus for future use
```

## Security Considerations

### File Permissions
```bash
# Secure installation
chmod 700 ~/.local/refocus           # Directory access
chmod 600 ~/.local/refocus/refocus.db # Database file
chmod 755 ~/.local/bin/focus*        # Executables
```

### Network Security
- Refocus Shell makes no network connections
- All data stored locally
- No telemetry or data collection
- Safe for secure/isolated environments

### Multi-User Systems
- Each user has isolated data
- No shared state between users
- User-specific configuration
- No privilege escalation required

---

*For more information, see [Getting Started](getting-started.md) or [Troubleshooting](troubleshooting.md).*
