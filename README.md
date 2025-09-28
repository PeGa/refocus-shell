# Refocus Shell

**Refocus Shell – a lightweight CLI for managing your focus sessions**

## TL;DR

```bash
# Install & start tracking
git clone https://github.com/PeGa/refocus-shell && cd refocus-shell && ./setup.sh install
focus on "my-project"    # Start focusing
focus status             # Check progress  
focus off                # Stop & add notes
focus report today       # See your day
```

**What it does:** Tracks your focus time, shows `⏳ [project]` in your terminal, sends gentle nudges every 10 minutes, exports your data as JSON/SQLite. All local, no cloud, no tracking.

> 🧠 **Built for neurodivergent devs, sysadmins, and anyone tired of forgetting where their time went (e.g. me).**  

**Refocus Shell is a terminal-first, privacy-conscious time tracker that nudges, reflects, and gets out of your way.**


[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.
org/licenses/gpl-3.0)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://www.
linux.org/)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/
software/bash/)
[![Database: SQLite](https://img.shields.io/badge/Database-SQLite-yellow.svg)](https://www.
sqlite.org/)
[![Privacy: Local-First](https://img.shields.io/badge/Privacy-Local--First-brightgreen.svg)]
(https://en.wikipedia.org/wiki/Local-first_software)

---

## 🎯 Quick Start

```bash
# Install Refocus Shell
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install

# Start your first focus session
focus on "my-project"
focus status    # See your progress
focus off       # End session (allows adding session notes)
```

**That's it!** Your focus sessions are now tracked, and you'll get gentle nudges every 10 minutes to stay on track.

---

## Live Prompt (no daemon)

Show live focus information in your terminal prompt without any daemons or background processes. The prompt updates right after any `focus` command and also on every Enter, without re-running the DB or spawning daemons.

### Bash
```bash
echo 'source /path/to/extras/prompt/refocus-prompt.bash' >>~/.bashrc
```

### Zsh
```bash
echo 'source /path/to/extras/prompt/refocus-prompt.zsh' >>~/.zshrc
# And ensure ${REFOCUS_PROMPT_SEG} is in PROMPT or RPROMPT.
```

---

## 🧠 Why Refocus?

- **🎯 Automatic Logging** - No manual timers, no complex interfaces. Just `focus on` and go.
- **📊 Smart Continuation** - `focus on` without a project name continues your last session seamlessly.
- **💾 Import/Export** - Your data stays yours. Export to JSON or SQLite, import anywhere.
- **⚡ Prompt Integration** - See `⏳ [project]` in every terminal. Start in one terminal, see it everywhere.
- **🔔 Gentle Nudges** - Real-time reminders during active sessions, plus idle notifications when you're not focusing. When you don't want to focus, refocus won't bother you. No spam, no overwhelm.
- **📝 Session Notes** - Capture what you accomplished. Perfect for neurodivergent minds who need context.

---

## 📋 Dependencies

Refocus Shell requires these system packages:

- **sqlite3** - Database for storing focus sessions
- **notify-send** - Desktop notifications (libnotify-bin on Debian/Ubuntu)
- **jq** - JSON processing for import/export features

The installer will automatically detect your distribution and install missing dependencies:

```bash
# Debian/Ubuntu
sudo apt-get install sqlite3 libnotify-bin jq

# Arch/Manjaro  
sudo pacman -S sqlite libnotify jq

# Fedora/RHEL
sudo dnf install sqlite libnotify jq

# openSUSE
sudo zypper install sqlite3 libnotify-tools jq
```

---

```bash
# Focus Management
focus on "project"     # Start focusing
focus off              # Stop and add notes
focus pause            # Pause (asks for context notes)
focus continue         # Resume paused session
focus status           # See current state

# Session History
focus past list        # View all sessions
focus past add "project" "14:00" "16:00"  # Add past session
focus report today     # Generate reports

# Data & Configuration
focus export           # Backup your data
focus import file.json # Restore from backup
focus config           # Manage settings
```

---

## 📚 Documentation

- **[Getting Started](docs/getting-started.md)** - First steps and basic workflow
- **[Session Management](docs/sessions.md)** - Advanced session techniques and workflows
- **[Data Management](docs/data.md)** - Import/export, backups, and migration
- **[Reports & Analytics](docs/reports.md)** - Generate insights from your focus data
- **[Configuration](docs/configuration.md)** - Customize settings and behavior
- **[Installation Guide](docs/installation.md)** - Detailed setup for all platforms
- **[Troubleshooting](docs/troubleshooting.md)** - Solve common issues
- **[Advanced Usage](docs/advanced.md)** - Power-user features and automation

---

## 🎨 Features in Action

### Smart Session Management
```bash
$ focus on "coding"
🎯 Started focusing on: coding

$ focus pause
⏸️  Pausing focus session on: coding
Focus paused. Please add notes for future recalling: debugging auth flow

$ focus continue
▶️  Resuming paused focus session on: coding
Include previous elapsed time? (y/N): y
```

### Rich Status Information
```bash
$ focus status
🎯 Currently focusing on: coding
⏱️  Session time: 25m
📝 Current session notes: debugging auth flow
📊 Total time on this project: 2h 15m
```

### Comprehensive Reporting
```bash
$ focus report today
📊 Today's Focus Report
═══════════════════════
Total focus time: 3h 45m
Active projects: 2
Sessions: 4

📋 Project Breakdown:
coding: 2h 30m (2 sessions)
planning: 1h 15m (2 sessions)
```

---

## 🛠️ Installation

```bash
# Quick install (recommended)
git clone https://github.com/PeGa/refocus-shell
cd refocus-shell
./setup.sh install

For detailed installation instructions, see [Advanced Usage](docs/usage.md#installation).

---

## 🔧 Configuration

Refocus Shell works out of the box, but you can customize it:

```bash
# Enable verbose output for debugging
focus config set VERBOSE true

# Customize nudge intervals
focus nudge enable    # Enable gentle reminders
focus nudge disable   # Disable if too distracting

# Manage project descriptions
focus description add coding "Main development project"
focus description show coding
```

---

## 🧩 Privacy & Philosophy

**Built for neurodivergent minds** - Refocus Shell understands that focus isn't linear. It's okay to pause, resume, and take breaks. The tool adapts to you, not the other way around.

**Privacy-first** - All data stays on your machine. No telemetry, no cloud sync, no data collection. Your focus patterns are yours alone.

**Gentle by design** - No aggressive notifications, no gamification pressure. Just gentle nudges when you're already working, silent when you're not.

---

## 🤝 Contributing

We welcome contributions! Whether it's bug fixes, new features, or documentation improvements, your help makes Refocus Shell better for everyone.

- **[Contributing Guide](docs/contributing.md)** - How to contribute
- **[Code of Conduct](CODE_OF_CONDUCT.md)** - Our community standards
- **[Issue Tracker](https://github.com/PeGa/refocus-shell/issues)** - Report bugs or request features

---

## 📄 License

Refocus Shell is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

Inspired by the need for focus tools that respect neurodivergent minds and prioritize privacy. Built with ❤️ for the terminal-first community.

---

*Made with ❤️ for neurodivergent minds who need gentle structure without the overwhelm.*