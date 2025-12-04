# Hotkey Configuration & Multi-Monitor Support - Implementation Plan

## 1. Dynamic Configurable Hotkey System

### Current State
- **Hardcoded**: `Ctrl+Shift+O` registered via `pynput.keyboard.GlobalHotKeys`
- **UI Mismatch**: Displays `⌘+Shift+I` (wrong symbol and wrong key)
- **Library**: Uses `pynput` (cross-platform Python library)
- **Registration**: Application-level, not OS-level

### OS-Level Hotkey Investigation

#### Linux Desktop Environments
| DE | Hotkey System | Compatibility Issues |
|---|---|---|
| **GNOME** | gsettings/dconf | Requires DBus, complex setup |
| **KDE Plasma** | kglobalaccel | KDE-specific API |
| **Xfce** | xfconf | Different config system |
| **i3/Sway** | Config file | Manual file editing |

**Verdict**: ❌ **DO NOT use OS-level hotkey settings**
- Too fragmented across distros/DEs
- Would limit portability significantly
- Requires extensive per-DE code
- Users expect app-specific settings anyway

#### Recommended Approach: Application-Level with pynput
✅ **Keep using pynput** - it's:
- Cross-platform (Linux, Windows, macOS)
- Distro-agnostic
- Works on X11 and Wayland (with limitations)
- Simple API
- Already working

**Limitations**:
- Wayland: Some compositors block global hotkeys (security feature)
- Fallback: Provide "Capture" window button

### Implementation Plan

#### Phase 1: Fix Current Hotkey Display (5 min)
- [ ] Update QML text to show correct hotkey: `Ctrl+Shift+O`
- [ ] Use `Ctrl` symbol instead of `⌘` (macOS-specific)

#### Phase 2: Make Hotkey Dynamic (20 min)
- [ ] Add `hotkey` property to `Controller` class
- [ ] Expose hotkey string to QML
- [ ] Update UI to display live hotkey value
- [ ] Store default in `Controller.__init__`

#### Phase 3: Persist Settings (15 min)
- [ ] Create `src/core/config.py` for configuration management
- [ ] Use `QSettings` to store user preferences
  - Key: `hotkey` 
  - Default: `<ctrl>+<shift>+o`
- [ ] Load hotkey on startup
- [ ] Save when changed

#### Phase 4: Hotkey Configuration UI (30 min)
- [ ] Add hotkey input field to `Settings.qml`
- [ ] Implement key capture widget (user presses desired combo)
- [ ] Validate hotkey (no conflicts, valid modifiers)
- [ ] Update `main.py` to restart listener with new hotkey
- [ ] Show user-friendly hotkey format (e.g., "Ctrl + Shift + C")

#### Phase 5: Hotkey Re-registration (15 min)
- [ ] Add `updateHotkey(new_combo)` method in `main.py`
- [ ] Stop old listener
- [ ] Start new listener with updated combo
- [ ] Expose via controller to QML

---

## 2. Multi-Monitor Support

### Current State Investigation

**Screen Detection**:
```python
mss.mss().monitors
# Monitor 0: {'left': 0, 'top': 0, 'width': 3840, 'height': 1080}  # All monitors combined
# Monitor 1: {'left': 0, 'top': 0, 'width': 1920, 'height': 1080}   # Left monitor
# Monitor 2: {'left': 1920, 'top': 0, 'width': 1920, 'height': 1080} # Right monitor
```

**Current Capture**: ✅ Already works! 
- `mss` uses absolute coordinates across all monitors
- If you select x=2000, it correctly captures from the right monitor

**Current Overlay**: ❌ **ONLY covers primary monitor**
- `overlay.qml` sets `width: Screen.width, height: Screen.height`
- `Screen` in QML = primary screen only
- **Problem**: Can't select regions on secondary monitors

### Multi-Monitor Edge Cases

#### Case 1: Selection Spans Multiple Monitors
**Example**: Start at x=1800 (left monitor), drag to x=2100 (right monitor)

**Current Behavior**: Works! `mss.grab()` handles any coordinate range

**Action**: ✅ No changes needed in capture logic

#### Case 2: Overlay Only Shows on Primary Monitor
**Example**: User can't see overlay on secondary monitor

**Current Behavior**: ❌ Broken - overlay only on primary

**Solution**: Create separate overlay window for each monitor

#### Case 3: Mouse Coordinates Across Monitors
**Example**: QML MouseArea coordinates might be relative to overlay window

**Current Behavior**: Need to test, but likely works since overlay is positioned at (0,0)

**Solution**: Ensure overlay x/y offset is added to mouse coordinates

### Implementation Plan

#### Phase 1: Multi-Monitor Overlay (45 min)
- [ ] Update `overlay.qml` to detect all monitors
- [ ] Create overlay instances for each monitor in `main.py`
  - One QML overlay window per physical screen
  - Position each at correct offset (e.g., monitor 2 at x=1920)
- [ ] Synchronize mouse drag across all overlays
  - Share selection state via controller
  - Draw selection rectangle on all screens
- [ ] Handle edge transitions (dragging from one screen to another)

#### Phase 2: Coordinate Translation (20 min)
- [ ] Add monitor offset to mouse coordinates before passing to `captureRegion`
- [ ] Ensure absolute screen coordinates are used (not window-relative)
- [ ] Test with 2+ monitors in different arrangements (horizontal, vertical, mixed)

#### Phase 3: Virtual Desktop Coordinates (15 min)
- [ ] Get virtual desktop geometry from Qt
- [ ] Handle negative coordinates (monitor to the left of primary)
- [ ] Handle vertical stacking

#### Phase 4: Edge Case Handling (20 min)
- [ ] Minimum selection size validation (already exists: 5x5)
- [ ] Handle monitor disconnection during selection
- [ ] Cancel selection if monitors change mid-capture

#### Phase 5: Testing & Polish (30 min)
- [ ] Test on single monitor (should still work)
- [ ] Test on dual monitor (horizontal)
- [ ] Test on triple monitor
- [ ] Test on vertical arrangement
- [ ] Test mixed DPI monitors (if applicable)

---

## Implementation Schedule

### Hotkey Configuration: ~1.5 hours
1. Fix display (5 min) ← Start here
2. Make dynamic (20 min)
3. Persist settings (15 min)
4. Config UI (30 min)
5. Re-registration (15 min)

### Multi-Monitor Support: ~2 hours
1. Multi-monitor overlay (45 min)
2. Coordinate translation (20 min)
3. Virtual desktop (15 min)
4. Edge cases (20 min)
5. Testing (30 min)

**Total Estimated Time**: ~3.5 hours

---

## Technical Design

### New Files
- `src/core/config.py` - Configuration management
- `src/ui/HotkeyInput.qml` - Hotkey capture widget (optional, can add to Settings.qml)

### Modified Files
- `main.py` - Hotkey listener restart, multi-monitor overlay creation
- `src/ui/controller.py` - Expose hotkey property, monitor info
- `src/ui/overlay.qml` - Support monitor offset, shared selection state
- `src/ui/Settings.qml` - Add hotkey configuration UI
- `src/ui/main.qml` - Display live hotkey value

### Dependencies
**No new dependencies needed!**
- `pynput` - already installed ✅
- `mss` - already installed ✅
- `QSettings` - part of PySide6 ✅

---

## Risk Assessment

### Hotkey Configuration
- **Risk**: Low
- **Complexity**: Medium
- **Compatibility**: High (works everywhere pynput works)

### Multi-Monitor Support  
- **Risk**: Medium
- **Complexity**: Medium-High
- **Compatibility**: High (Qt handles multi-monitor well)

**Biggest Challenge**: Synchronizing selection rectangles across multiple overlay windows in real-time.

**Mitigation**: Use shared state in Controller, emit signals to update all overlays simultaneously.

---

## Recommendation

✅ **I'm confident in implementing both features.**

**Start Order**:
1. Hotkey display fix (quick win, visible improvement)
2. Hotkey configuration (high value, medium complexity)
3. Multi-monitor overlay (higher complexity but feasible)

Shall I begin implementation?
