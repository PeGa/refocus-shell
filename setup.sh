#!/usr/bin/env bash
# Refocus Shell - Setup
set -euo pipefail

INSTALL_DIR="$HOME/.local/refocus"
BIN_DIR="$HOME/.local/bin"
SRC_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

_info()  { echo "  $1"; }
_ok()    { echo "✅ $1"; }
_warn()  { echo "⚠  $1"; }
_die()   { echo "❌ $1" >&2; exit 1; }

install_deps() {
    local missing=()
    command -v sqlite3      &>/dev/null || missing+=(sqlite3)
    command -v notify-send  &>/dev/null || missing+=(libnotify-bin)
    command -v crontab      &>/dev/null || missing+=(cron)

    [[ ${#missing[@]} -eq 0 ]] && { _ok "Dependencies present."; return; }

    _info "Installing: ${missing[*]}"
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "${missing[@]}"
    elif command -v pacman &>/dev/null; then
        # map names
        local pkgs=()
        for p in "${missing[@]}"; do
            case $p in
                libnotify-bin) pkgs+=(libnotify);;
                cron)          pkgs+=(cronie);;
                *)             pkgs+=("$p");;
            esac
        done
        sudo pacman -S --noconfirm "${pkgs[@]}"
    elif command -v dnf &>/dev/null; then
        local pkgs=()
        for p in "${missing[@]}"; do
            case $p in
                libnotify-bin) pkgs+=(libnotify);;
                cron)          pkgs+=(cronie);;
                *)             pkgs+=("$p");;
            esac
        done
        sudo dnf install -y "${pkgs[@]}"
    else
        _warn "Unknown package manager. Install manually: ${missing[*]}"
    fi
}

install_files() {
    # Confirm before wiping an existing installation
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -n "⚠  Existing installation found. This will wipe all data and config. Continue? (yes/N): "
        read -r ans
        [[ "$ans" == "yes" ]] || { echo "Aborted."; exit 0; }
    fi

    # Strip any stale nudge cron entry before wiping
    local tmp
    tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$INSTALL_DIR/focus-nudge" > "$tmp" || true
    crontab "$tmp"
    rm -f "$tmp"

    # Clean slate
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/services" "$INSTALL_DIR/lib" "$BIN_DIR"

    cp "$SRC_DIR/config.sh"      "$INSTALL_DIR/"
    cp "$SRC_DIR/focus"          "$INSTALL_DIR/"
    cp "$SRC_DIR/focus-nudge"    "$INSTALL_DIR/"
    cp "$SRC_DIR/services/"*.sh  "$INSTALL_DIR/services/"
    cp "$SRC_DIR/lib/"*.sh       "$INSTALL_DIR/lib/"

    chmod +x "$INSTALL_DIR/focus"
    chmod +x "$INSTALL_DIR/focus-nudge"
    chmod +x "$INSTALL_DIR/lib/"*.sh
    chmod +x "$INSTALL_DIR/services/"*.sh

    ln -sf "$INSTALL_DIR/focus" "$BIN_DIR/focus"

    _ok "Files installed to $INSTALL_DIR"
}

install_shell() {
    local rc="$HOME/.bashrc"
    local line="source $INSTALL_DIR/services/focus-function.sh"

    if grep -qF "$line" "$rc" 2>/dev/null; then
        _ok "Shell integration already in $rc"
    else
        echo "" >> "$rc"
        echo "# Refocus Shell" >> "$rc"
        echo "$line" >> "$rc"
        _ok "Shell integration added to $rc"
        _warn "Run: source ~/.bashrc"
    fi
}

init_db() {
    REFOCUS_ROOT="$INSTALL_DIR" source "$INSTALL_DIR/config.sh"
    REFOCUS_ROOT="$INSTALL_DIR" source "$INSTALL_DIR/services/database.sh"
    db_init
    _ok "Database initialised at $DB_PATH"
}

case "${1:-install}" in
    install)
        echo "Installing Refocus Shell..."
        install_deps
        install_files
        init_db
        install_shell
        echo ""
        echo "Done. Open a new terminal or run: source ~/.bashrc"
        ;;
    uninstall)
        echo -n "Remove $INSTALL_DIR and shell integration? (yes/N): "
        read -r ans
        [[ "$ans" == "yes" ]] || { echo "Cancelled."; exit 0; }
        # Remove cron first
        REFOCUS_ROOT="$INSTALL_DIR" source "$INSTALL_DIR/services/cron.sh" 2>/dev/null && cron_remove 2>/dev/null || true
        rm -rf "$INSTALL_DIR"
        rm -f  "$BIN_DIR/focus"
        # Remove bashrc line
        rc="$HOME/.bashrc"
        sed -i '/# Refocus Shell/d' "$rc"
        sed -i "\|focus-function.sh|d" "$rc"
        _ok "Uninstalled."
        ;;
    *)
        echo "Usage: ./setup.sh [install|uninstall]" >&2; exit 2
        ;;
esac
