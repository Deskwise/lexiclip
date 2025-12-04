# PRD — PlasmaOCR (MVP)

## 1. Product Summary

PlasmaOCR is a lightweight Linux desktop utility for instantly extracting text from screenshots and images. It is optimized for speed, simplicity, and low cost, using Gemini Flash for high‑quality but inexpensive OCR.

**MVP Core Workflow**

- Press hotkey → draw region → OCR → text auto‑copied.

## 2. Target Platform

- **OS**: Linux
- **Desktop Environment**: KDE Plasma (primary)
- **Session Type**: X11 (Wayland support in roadmap)
- **Packaging**: AppImage or Flatpak
- **Tech Stack**:
  - Qt/QML for GUI
  - Python or Rust backend
  - Gemini Flash Vision API

## 3. Target Users

- Developers
- Students
- Researchers
- Anyone who frequently screenshots content to capture text
- Users needing fast clipboard‑based extraction

## 4. Problem Statement

Current Linux OCR workflows are slow and fragmented:

1. Open screenshot tool
2. Select area
3. Save image
4. Open OCR app or website
5. Copy result

This interrupts focus, slows workflow, and feels clumsy. PlasmaOCR reduces OCR to a single gesture.

## 5. Primary User Journey (MVP)

**Scenario**: Extract text from screenshot

1. User presses global hotkey (e.g., `Ctrl+Shift+O`).
2. App shows region‑selection overlay (X11).
3. User drags to select region.
4. App immediately sends that image to Gemini Flash Vision.
5. User receives:
   - Text auto‑copied to clipboard.
   - Small popup: “Text copied ✔️”.
   - *(Optional)* A window shows the extracted text + a history entry.

Goal: Complete the entire flow in **1–3 seconds**.

## 6. Core Features (MVP)

### 6.1 Global Hotkey + Region Selection
- Configurable shortcut (`Ctrl+Shift+O` default).
- X11‑based selection box with drag‑to‑select, resize handles, and `Esc` to cancel.

### 6.2 Image Input
- Supports:
  - Region capture (primary).
  - Drag & drop onto app window.
  - Pasting image data (`Ctrl+V`).
  - “Open File” (last resort).

### 6.3 OCR (Gemini Flash Vision)
- Sends image to Flash Vision model.
- Prompts only for plain‑text extraction.
- Preserves line breaks, removes noise and commentary, avoids heavy reasoning to keep costs low.

### 6.4 Output
- Auto‑copy text to clipboard.
- Popup notification.
- Optional mini window with extracted text, copy button, and clear button.

### 6.5 History (Lightweight)
- Stores last **10** OCR results.
- Each entry shows timestamp + snippet.
- Click to recopy, delete single entry or clear all.

### 6.6 Settings
- Default OCR model (Flash Vision).
- Hotkey configuration.
- Auto‑copy toggle.
- History size.
- Theme (follows KDE global theme).

## 7. Non‑Goals (Not in MVP)

- Bounding boxes / text‑region highlighting.
- Semantic extraction (e.g., only numbers/emails/prices).
- Summaries or translations.
- Local OCR engine fallback (Tesseract).
- Multi‑region selection.
- Pro‑model tier support.
- Wayland portal integration.

These will appear in the roadmap.

## 8. Technical Requirements (MVP)

### 8.1 Architecture
- **Frontend**: Qt/QML
- **Backend**: Python or Rust
- **API Client**: Gemini Flash Vision
- **Clipboard**: KDE‑native (KClipBoard)

Backend performs:
- Image capture → Base64 conversion → API call → Returning text → Writing to clipboard → History storage (local JSON).

### 8.2 API Call Structure (High‑Level)
- Request includes image bytes (base64), Flash model name, simple OCR prompt.
- Output: plain text.

### 8.3 X11 Capture Implementation
- Use Qt or external tool (ImageMagick, `flameshot gui -r`, or pure Qt `grabWindow()`).
- Wayland not required for MVP.

### 8.4 Performance Targets
- Capture: < 100 ms
- OCR API latency: < 1.5 s avg
- Text to clipboard: instant
- App startup: < 300 ms

## 9. Privacy & Security

- No images stored unless history toggle enabled.
- History only stores text, not images.
- API key stored in KDE Wallet.
- HTTPS for all communication.
- No telemetry in MVP.

## 10. Success Metrics

- Users perform > 5 OCR actions/day.
- < 3 second end‑to‑end workflow.
- < 1 % crash rate.
- < 15 MB memory footprint idle.
- 80 % users use hotkey as main input.

## 11. Release Requirements

- AppImage and Flatpak builds.
- KDE integration (icon, category, launch entry).
- Clean settings UI.
- Installer‑free usage (AppImage drag & run).

## 12. MVP Completion Criteria

The MVP is “done” when:
- Hotkey → Region selection → OCR → Clipboard works reliably.
- Drag/drop and paste work.
- History works.
- Settings persist.
- Error states handled (API errors, no Internet).
- Latency stays within target.

## 📍 Roadmap (Beyond MVP)

### Phase 2 — Visual OCR (Google Lens‑like)
- Bounding boxes around detected text.
- Click to select regions.
- Multi‑select.
- Export text per‑region.
- Flash Vision or mid‑tier VL models.
- UI overlay engine.

### Phase 3 — Smart OCR
- “Extract only numbers/emails/prices”.
- “Translate this text”.
- “Summarize this screenshot”.
- “Turn screenshot text into Markdown”.
- Needs stronger reasoning model (Pro tier optional).

### Phase 4 — Wayland Support
- Implement `xdg-desktop-portal`.
- KWin DBus screenshot backend.
- Dual‑backend auto‑detection.

### Phase 5 — Local Offline Mode
- Tesseract fallback.
- GPU‑accelerated OCR option (PaddleOCR / EasyOCR).

### Phase 6 — Power Features
- Annotate screenshot.
- Text redaction.
- Auto‑language detection.
- OCR + auto‑save to Notes/Kate.
- Hotkey‑based instant action modes:
  - “OCR + translate”
  - “OCR + summarize”
  - “OCR + copy Markdown”

### Phase 7 — Cross‑platform (if wanted)
- Windows version.
- macOS version.
- GTK or Electron alternative UI.
