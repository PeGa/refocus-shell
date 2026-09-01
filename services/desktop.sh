#!/usr/bin/env bash
# Refocus Shell - Desktop session adapter (secondary adapter)
#
# cron runs the payloads with an environment stripped of everything that
# points at the user's graphical session. A dialog tool doesn't degrade
# gracefully when it can't find one: Qt calls qFatal() inside
# createEventDispatcher and kdialog dies on SIGABRT, so every check-in fire
# left a coredump behind and never showed a popup [#35].
#
# This file owns the two questions that answers — what the session
# environment looks like, and whether there is one at all. Sourced by
# focus-checkin (before it launches anything) and by lib/checkin.sh (to
# report honestly); never routable.

desktop_session_env() {
    # Best-effort reconstruction of the pieces cron drops, exporting only what
    # can be corroborated on disk. An unset variable is strictly better than
    # one pointing nowhere: an empty DISPLAY sends Qt looking for a display
    # server named "" instead of falling through to the next option, so the
    # empty values a cron entry carries are cleared before anything else.
    [[ -n "${DISPLAY:-}" ]]                 || unset DISPLAY
    [[ -n "${WAYLAND_DISPLAY:-}" ]]         || unset WAYLAND_DISPLAY
    [[ -n "${XDG_RUNTIME_DIR:-}" ]]         || unset XDG_RUNTIME_DIR
    [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || unset DBUS_SESSION_BUS_ADDRESS

    # XDG_RUNTIME_DIR is the one that matters most and the one most likely to
    # be missing: WAYLAND_DISPLAY is a socket NAME, not a path, and it is
    # resolved against this directory. A cron entry carrying
    # "WAYLAND_DISPLAY=wayland-0" without it is exactly the crash in #35 —
    # the compositor is right there, and Qt has no idea where to look.
    if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        local run; run="/run/user/$(id -u)"
        [[ -d "$run" ]] && export XDG_RUNTIME_DIR="$run"
    fi
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" && -S "${XDG_RUNTIME_DIR:-}/bus" ]]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    fi
    if [[ -z "${WAYLAND_DISPLAY:-}" && -S "${XDG_RUNTIME_DIR:-}/wayland-0" ]]; then
        export WAYLAND_DISPLAY="wayland-0"
    fi
    if [[ -z "${DISPLAY:-}" && -S "/tmp/.X11-unix/X0" ]]; then
        export DISPLAY=":0"
    fi
    return 0
}

has_desktop_display() {
    # 0 iff a GUI tool has somewhere to draw. Asked BEFORE spawning one,
    # because the failure mode is a coredump, not a non-zero exit — there is
    # no "try it and see" here.
    #
    # XDG_RUNTIME_DIR first, and independently of any display: Qt refuses to
    # start without a usable one and says so through qFatal() — "XDG_RUNTIME_DIR
    # is invalid or not set in the environment" — even with a perfectly good
    # DISPLAY. Only demanded where the platform has the concept at all; macOS
    # has no /run/user and its GUI tools don't want one.
    if [[ -d /run/user && ! -d "${XDG_RUNTIME_DIR:-}" ]]; then
        return 1
    fi

    local wd="${WAYLAND_DISPLAY:-}"
    if [[ -n "$wd" ]]; then
        case "$wd" in
            /*) [[ -S "$wd" ]] && return 0 ;;
            *)  [[ -S "${XDG_RUNTIME_DIR:-}/$wd" ]] && return 0 ;;
        esac
    fi
    local d="${DISPLAY:-}"
    if [[ -n "$d" ]]; then
        # ":1" / ":1.0" name a local X server, so its socket must be there.
        # A host-qualified DISPLAY ("box:0") is someone else's X server over
        # the network — nothing local to check, so take it at its word.
        if [[ "$d" =~ ^:([0-9]+) ]]; then
            [[ -S "/tmp/.X11-unix/X${BASH_REMATCH[1]}" ]] && return 0
            return 1
        fi
        return 0
    fi
    return 1
}
