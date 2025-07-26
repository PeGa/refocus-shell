# Automatic Idle Detection - Immediate Roadmap

## Overview
Implement automatic idle detection to stop work tracking when the user's device is idle (no keyboard/mouse activity). This feature will be privacy-safe, cross-distro compatible, and opt-in.

## Core Logic

### **1. Detection Flow**
```bash
1. Check idle status 1 minute after each nudge
2. If idle for threshold → issue "work off" + notification
3. If not idle → continue normal nudging cycle
4. No auto-resume (intentional linearity)
```

### **2. Detection Methods (Priority Order)**
```bash
1. KDE/Plasma (Wayland/X11) → DBus:
   org.freedesktop.ScreenSaver.GetSessionIdleTime
   - Works on Plasma 6/Wayland and Plasma/X11
   - Uses qdbus or gdbus

2. GNOME (Wayland/X11) → DBus:
   org.gnome.Mutter.IdleMonitor.GetIdletime
   - Uses gdbus for GNOME Mutter
   - Covers GNOME on both Wayland and X11

3. systemd-logind (any DE/WM) → loginctl:
   Use IdleHint=yes + IdleSinceHint (µs since epoch)
   - Reliable on modern distros regardless of DE/WM
   - Universal fallback

4. X11 (XFCE, LXQt on X11, i3, Openbox, etc.) → xprintidle:
   - Traditional X11 utility
   - Covers X11-based window managers
   - No ambiguities for X11 environments

5. disabled: if none available
   - Graceful degradation
   - No crashes or erratic behavior
```

### **3. Configuration**
```bash
WORK_IDLE_DETECTION_ENABLED=false  # Default: disabled
WORK_IDLE_THRESHOLD=21             # (10*2 + 1) minutes
WORK_IDLE_DETECTION_METHOD=auto    # auto-detect environment
```

## Cross-Distro Strategy

#### **Priority Order:**
1. **KDE/Plasma** → DBus (Plasma 6/Wayland and Plasma/X11)
2. **GNOME** → DBus (GNOME Mutter on Wayland/X11)
3. **systemd-logind** → Universal fallback (any DE/WM)
4. **X11** → xprintidle (XFCE, LXQt on X11, i3, Openbox, etc.)
5. **Feature disabled** → Everything else

#### **Environment Detection:**
- **KDE/Plasma**: Use `qdbus` or `gdbus` for ScreenSaver DBus
- **GNOME**: Use `gdbus` for Mutter IdleMonitor
- **X11**: Use `xprintidle` (no ambiguities)
- **Other Wayland**: Fall back to systemd-logind
- **Unsupported**: Feature disabled

#### **Graceful Degradation:**
- Auto-detect environment and use appropriate method
- Cache detection method after first successful use
- If detection fails → feature disabled
- If environment not supported → feature disabled

## User Experience

### **UX Guarantees:**
- **Auto-off after threshold** → notify "Work tracking stopped due to inactivity"
- **No auto-resume** (intentional, per linearity principle)
- **If detection unavailable** → feature silently disabled
- **Opt-in by default** → user must enable feature

### **CLI Commands:**
```bash
work idle-enable    # Enable idle detection
work idle-disable   # Disable idle detection
work idle-status    # Show detection method + status
```

## Technical Requirements

#### **Dependencies:**
- **Always**: `notify-send`, `sqlite3`
- **KDE/Plasma**: `qdbus` or `gdbus` (DBus tools)
- **GNOME**: `gdbus` (DBus tools)
- **X11 WMs**: `xprintidle` (X11 utility)
- **systemd**: `loginctl` (usually pre-installed)

#### **Implementation Strategy:**

**1. Environment Detection:**
```bash
# Auto-detect DE/WM and use appropriate method
- KDE/Plasma → DBus (qdbus/gdbus)
- GNOME → DBus (gdbus for Mutter)
- X11 → xprintidle (no ambiguities)
- Other Wayland → systemd-logind fallback
- Unsupported → feature disabled
```

**2. Method Caching:**
```bash
# Cache detection method after first successful use
# Store in database or config file
# Avoid repeated environment detection
```

**3. Timer Strategy:**
```bash
# Prefer systemd user timers over cron
# Cron fallback for pure X11 setups
# Maintain session environment for DBus calls
```

**4. Normalization:**
```bash
# All methods return seconds
# Handle KDE milliseconds quirk
# Consistent output across environments
```

#### **Database Updates:**
- Add `idle_detection_enabled` column to `state` table
- Add `idle_detection_method` column to `state` table
- Add `idle_threshold` column to `state` table

#### **Script Updates:**
- Enhance `work-nudge` script with idle detection
- Add `work idle-enable/disable/status` commands
- Update `setup.sh` to handle new dependencies
- Implement `get_idle_seconds()` function with comprehensive detection
- Add environment detection and method caching
- Prefer systemd user timers over cron (with cron fallback)

## Privacy & Security

### **Privacy Guarantees:**
- **No keylogging** → only detect "activity happened", not "what activity"
- **No telemetry** → 100% local processing
- **No data collection** → all data stays on user's machine
- **Opt-in** → feature disabled by default

### **Security Considerations:**
- **DBus calls** → use session bus only
- **X11 tools** → standard utilities, no custom monitoring
- **systemd** → use existing session management
- **Graceful failure** → no crashes or erratic behavior

## Testing Strategy

#### **Functional Testing:**
1. Test idle detection on each supported environment
2. Test threshold behavior (21 minutes)
3. Test notification delivery
4. Test auto-off functionality
5. Test graceful degradation

#### **Cross-Distro Testing:**
1. Test on KDE/Plasma (Wayland and X11)
2. Test on GNOME (Wayland and X11)
3. Test on X11 WMs (XFCE, i3, Openbox)
4. Test on systemd-based distros (Ubuntu, Fedora, etc.)
5. Test on minimal distros (feature should be disabled)
6. Test on unsupported Wayland compositors (feature should be disabled)

#### **Edge Cases:**
1. No display server (headless)
2. Multiple displays
3. Remote desktop sessions
4. Virtual machines
5. Containerized environments

## Future Considerations

#### **Potential Enhancements:**
- Configurable idle thresholds
- Different thresholds for different projects
- Idle detection method selection
- Performance optimization (caching detection method)
- Environment-specific configuration

#### **Roadmap Integration:**
- This feature enables mobile sync (consistent idle detection)
- Foundation for advanced analytics
- Preparation for multi-device scenarios

## Implementation Timeline

### **Phase 1: Core Detection**
1. Implement `get_idle_seconds()` function
2. Add environment detection logic
3. Update database schema
4. Add CLI commands

### **Phase 2: Integration**
1. Enhance `work-nudge` script
2. Update `setup.sh` for dependencies
3. Implement systemd user timers
4. Add configuration options

### **Phase 3: Testing & Polish**
1. Cross-distro testing
2. Edge case handling
3. Documentation updates
4. Performance optimization

---

**Note**: This feature is designed to be **privacy-first**, **cross-distro compatible**, and **opt-in**. It provides automatic idle detection without compromising user privacy or requiring complex setup. 