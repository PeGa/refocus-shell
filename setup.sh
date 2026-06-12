#!/usr/bin/env bash
# Refocus Shell - Setup
set -euo pipefail

INSTALL_DIR="$HOME/.local/refocus"
BIN_DIR="$HOME/.local/bin"
SRC_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
_info()  { echo "  $1"; }
_ok()    { echo "$1"; }
_warn()  { echo "  $1"; }
_die()   { echo "$1" >&2; exit 1; }

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
    local db_tmp="" env_tmp=""

    if [[ -d "$INSTALL_DIR" ]]; then
        echo -n "Existing installation found. Code will be updated; data and config preserved. Continue? (yes/N): "
        read -r ans
        [[ "$ans" == "yes" ]] || { echo "Aborted."; exit 0; }

        # Stash data before the code wipe
        if [[ -f "$INSTALL_DIR/refocus.db" ]]; then
            db_tmp=$(mktemp)
            cp "$INSTALL_DIR/refocus.db" "$db_tmp"
        fi
        if [[ -f "$INSTALL_DIR/.env" ]]; then
            env_tmp=$(mktemp)
            cp "$INSTALL_DIR/.env" "$env_tmp"
        fi
    fi

    # Strip any stale nudge cron entry before wiping (fixed-string — dots in path are literal)
    local tmp; tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -vF "$INSTALL_DIR/focus-nudge" > "$tmp" || true
    crontab "$tmp"
    rm -f "$tmp"

    # Wipe and rebuild
    rm -rf "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/services" "$INSTALL_DIR/lib" "$BIN_DIR"

    cp "$SRC_DIR/config.sh"      "$INSTALL_DIR/"
    cp "$SRC_DIR/focus"          "$INSTALL_DIR/"
    cp "$SRC_DIR/focus-nudge"    "$INSTALL_DIR/"
    cp "$SRC_DIR/services/"*.sh  "$INSTALL_DIR/services/"
    cp "$SRC_DIR/lib/"*.sh       "$INSTALL_DIR/lib/"
    [[ -d "$SRC_DIR/docs" ]]     && cp -r "$SRC_DIR/docs" "$INSTALL_DIR/docs"

    chmod +x "$INSTALL_DIR/focus"
    chmod +x "$INSTALL_DIR/focus-nudge"
    chmod +x "$INSTALL_DIR/lib/"*.sh
    chmod +x "$INSTALL_DIR/services/"*.sh

    # Restore stashed data
    [[ -n "$db_tmp"  ]] && { mv "$db_tmp"  "$INSTALL_DIR/refocus.db"; _ok "Database preserved."; }
    [[ -n "$env_tmp" ]] && { mv "$env_tmp" "$INSTALL_DIR/.env";       _ok "Config (.env) preserved."; }

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
        # Only init DB if it does not already exist (preserved from prior install)
        [[ -f "$INSTALL_DIR/refocus.db" ]] || init_db
        install_shell
        echo ""
        echo "Done. Open a new terminal or run: source ~/.bashrc"
        ;;
    uninstall)
        echo -n "Remove $INSTALL_DIR and shell integration? (yes/N): "
        read -r ans
        [[ "$ans" == "yes" ]] || { echo "Cancelled."; exit 0; }
        REFOCUS_ROOT="$INSTALL_DIR" source "$INSTALL_DIR/services/cron.sh" 2>/dev/null             && cron_remove 2>/dev/null || true
        rm -rf "$INSTALL_DIR"
        rm -f  "$BIN_DIR/focus"
        rc="$HOME/.bashrc"
        sed -i '/# Refocus Shell/d' "$rc"
        sed -i "|focus-function.sh|d" "$rc"
        _ok "Uninstalled."
        ;;
    *)
        echo "Usage: ./setup.sh [install|uninstall]" >&2; exit 2
        ;;
esac
