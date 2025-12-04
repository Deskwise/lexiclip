# PlasmaOCR MVP Completion Checklist

**Last Updated:** 2025-11-25  
**Target Platform:** Linux (KDE Plasma on X11, Ubuntu LTS)  
**Status:** ~70% Complete - Core functionality working, missing input methods & polish

---

## ✅ Completed Features

- [x] **Hotkey → Region Selection → OCR → Clipboard** - Core workflow functional
- [x] **History Management** - Stores last 10 captures with timestamps
- [x] **Settings UI** - Basic settings dialog implemented
- [x] **Auto-copy to clipboard** - Text automatically copied after OCR
- [x] **System tray integration** - App runs in background
- [x] **Modern UI Design** - Rounded corners, card-based layout, hover effects
- [x] **Helpful UX hints** - User guidance for clicking history items

---

## 🔥 Priority Tasks (MVP Blockers)

### **#1: Robust Error Handling** ⏱️ 1 hour
**Priority:** CRITICAL - App currently crashes on errors  
**Status:** 🔴 Not Started

#### What's Needed:
- [ ] Graceful handling of API failures (no internet, rate limits, invalid API key)
- [ ] User-friendly error notifications (non-blocking toasts instead of crash dialogs)
- [ ] Retry mechanism for transient failures
- [ ] Fallback messaging when Gemini API is unreachable
- [ ] Input validation (empty regions, invalid image formats)

#### Implementation Notes:
```python
# src/core/ocr.py - Add comprehensive error handling
def extract_text(image: Image.Image) -> str:
    """
    Needs to handle:
    - Missing/invalid API key
    - Network timeouts
    - Rate limiting (429 errors)
    - Invalid image formats
    - API service errors (5xx)
    """
```

#### Acceptance Criteria:
- ✅ App doesn't crash on API failures
- ✅ User sees helpful error messages (e.g., "No internet connection", "API key invalid")
- ✅ Errors logged to console for debugging
- ✅ Auto-retry for network timeouts (max 2 retries)
- ✅ Clear error states in UI (red toast notification)

#### Files to Modify:
- `src/core/ocr.py` - Add try/catch blocks and error types
- `src/ui/controller.py` - Emit error signals to QML
- `src/ui/main.qml` - Add toast notification component
- `src/ui/overlay.qml` - Handle capture errors (empty region)

---

### **#2: Paste Image Support (Ctrl+V)** ⏱️ 1 hour
**Priority:** HIGH - Core PRD requirement (Section 6.2)  
**Status:** 🔴 Not Started

#### What's Needed:
- [ ] Monitor clipboard for image data
- [ ] "Paste Image" button in main window
- [ ] Global Ctrl+V handler when app has focus
- [ ] Support for PNG, JPG, and other image formats from clipboard
- [ ] Visual feedback when image is pasted

#### Implementation Notes:
```python
# src/ui/controller.py - Add clipboard monitoring
@Slot()
def pasteImage(self):
    """
    - Get QImage from QClipboard
    - Convert to PIL Image
    - Process through OCR pipeline
    """
```

#### Acceptance Criteria:
- ✅ Can paste screenshots from clipboard (e.g., from Firefox, GIMP)
- ✅ "Paste" button appears in main window
- ✅ Ctrl+V works when window is focused
- ✅ Pasted images processed same as captured regions
- ✅ Error handling for non-image clipboard data

#### Files to Modify:
- `src/ui/controller.py` - Add `pasteImage()` method
- `src/ui/main.qml` - Add "Paste Image" button to action row
- `main.py` - No changes needed

---

### **#3: Open File Dialog** ⏱️ 30 minutes
**Priority:** MEDIUM - Nice to have, PRD mentions as "last resort"  
**Status:** 🔴 Not Started

#### What's Needed:
- [ ] File picker dialog (PNG, JPG, JPEG, BMP)
- [ ] "Open File..." button in main window
- [ ] Load image from disk and process through OCR
- [ ] Error handling for corrupted/unsupported files

#### Implementation Notes:
```python
# src/ui/controller.py
@Slot()
def openFileDialog(self):
    """
    - QFileDialog.getOpenFileName()
    - Load image with PIL
    - Process through OCR
    """
```

#### Acceptance Criteria:
- ✅ File picker shows only image files
- ✅ Selected image loads and processes correctly
- ✅ Works with absolute paths and special characters
- ✅ Error message for unsupported formats

#### Files to Modify:
- `src/ui/controller.py` - Add `openFileDialog()` method
- `src/ui/main.qml` - Add "Open File..." button (maybe in Settings?)

---

### **#4: Drag & Drop Support** ⏱️ 1-1.5 hours
**Priority:** MEDIUM - PRD requirement (Section 6.2)  
**Status:** 🔴 Not Started

#### What's Needed:
- [ ] Main window accepts dropped image files
- [ ] Visual feedback for drag-over (highlight drop zone)
- [ ] Support for both local files and image data
- [ ] Multi-file handling (process first image, ignore rest)

#### Implementation Notes:
```qml
// src/ui/main.qml - Add drop area
DropArea {
    anchors.fill: parent
    onDropped: (drop) => {
        if (drop.hasUrls) {
            // Get first image URL
            // Call bridge.processDroppedFile(url)
        }
    }
    onEntered: {
        // Visual feedback
    }
}
```

```python
# src/ui/controller.py
@Slot(str)
def processDroppedFile(self, file_url: str):
    """
    - Parse file:// URL
    - Validate image format
    - Load and process
    """
```

#### Acceptance Criteria:
- ✅ Can drag image from file manager onto window
- ✅ Window shows visual feedback during drag-over
- ✅ Dropped images processed immediately
- ✅ Error handling for non-image files

#### Files to Modify:
- `src/ui/main.qml` - Add `DropArea` component
- `src/ui/controller.py` - Add `processDroppedFile()` method

---

### **#5: Performance Validation & Logging** ⏱️ 30 minutes
**Priority:** LOW - Good to have for optimization  
**Status:** 🔴 Not Started

#### What's Needed:
- [ ] Time capture → OCR → clipboard workflow
- [ ] Log metrics to console
- [ ] Validate against PRD targets (Section 8.4):
  - Capture: < 100ms
  - OCR API latency: < 1.5s avg
  - Text to clipboard: instant
- [ ] Identify bottlenecks

#### Implementation Notes:
```python
# src/ui/controller.py
import time

@Slot(int, int, int, int)
def captureRegion(self, x, y, w, h):
    start_time = time.time()
    
    # Capture
    capture_end = time.time()
    print(f"Capture time: {(capture_end - start_time) * 1000:.2f}ms")
    
    # OCR (in worker)
    # Log in on_ocr_finished()
```

#### Acceptance Criteria:
- ✅ Logs printed for each stage: capture, OCR, clipboard
- ✅ Total workflow typically under 3 seconds
- ✅ Identify if OCR or network is bottleneck
- ✅ Optional: Add timestamp to history entries for analysis

#### Files to Modify:
- `src/ui/controller.py` - Add timing logs
- `src/core/ocr.py` - Log API roundtrip time
- `src/core/capture.py` - Log capture time

---

## 📊 MVP Completion Metrics

**Time Remaining:** ~4-5 hours  
**Estimated Completion:** Within 1 day of focused work

### PRD Completion Status (Section 12):
- ✅ Hotkey → Region selection → OCR → Clipboard works reliably
- 🔴 Drag/drop **not implemented**
- 🔴 Paste **not implemented**
- ✅ History works
- ✅ Settings persist
- 🔴 Error states **partially handled** (needs improvement)
- ❓ Latency **not validated** (needs testing)

---

## 🎯 Next Steps

1. **Start with #1 (Error Handling)** - Most critical, enables safe testing of other features
2. **Then #2 (Paste Support)** - Quick win, high user value
3. **Then #3 (Open File)** - Easy, rounds out input methods
4. **Then #4 (Drag & Drop)** - More complex, can skip if time-constrained
5. **Finally #5 (Performance)** - Validation and optimization

---

## 🚀 Post-MVP Roadmap

After completing these 5 tasks, consider:
- **Packaging** - AppImage/Flatpak builds
- **Documentation** - User guide, installation instructions
- **Testing** - Real-world usage on different KDE Plasma setups
- **User Feedback** - Share on r/linux, r/kde to validate product-market fit

**Then decide:** Wayland support (Phase 4) vs. Visual OCR (Phase 2)?

---

## 📝 Notes

- **Current Platform:** KDE Plasma X11 on Ubuntu LTS (user's environment)
- **Wayland support** deferred to Phase 4 (smart decision!)
- **UI modernization** ✅ Complete (rounded corners, better UX, helpful hints)
- **Core functionality** ✅ Working well

**Bottom Line:** We're close! 4-5 hours of focused work to ship the MVP.
