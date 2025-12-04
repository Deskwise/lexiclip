from PySide6.QtCore import QObject, Slot, Property, Signal, QThread
from PySide6.QtWidgets import QMessageBox
from src.core import capture, ocr, clipboard, history
from src.core.config import Config
import traceback

class Worker(QThread):
    finished = Signal(str)
    error = Signal(str)

    def __init__(self, img):
        super().__init__()
        self.img = img

    def run(self):
        try:
            text = ocr.extract_text(self.img)
            self.finished.emit(text)
        except Exception as e:
            self.error.emit(str(e))

class Controller(QObject):
    historyChanged = Signal()
    captureRequested = Signal()
    captureStarted = Signal()
    ocrSuccess = Signal(str)
    hotkeyChanged = Signal(str)  # Emits display string
    hotkeyUpdateRequested = Signal(str)  # Emits pynput format for main.py
    autostartChanged = Signal(bool)
    autostartUpdateRequested = Signal(bool)  # Tell main.py to update autostart file
    
    def __init__(self):
        super().__init__()
        self._history = history.load_history()
        self._config = Config()
        self.worker = None
        self._monitors = []  # Will be set by main.py
    
    def setMonitors(self, monitors):
        """Set monitor info from Qt screens."""
        self._monitors = monitors
    
    @Property('QVariantList')
    def monitors(self):
        """Get list of monitor geometries [{"x": 0, "y": 0, "width": 1920, "height": 1080}, ...]"""
        return self._monitors

    @Slot()
    def triggerCapture(self):
        """Called by hotkey to show overlay."""
        self.captureRequested.emit()

    @Property('QVariantList', notify=historyChanged)
    def historyModel(self):
        return self._history

    @Slot(int, int, int, int)
    def captureRegion(self, x, y, w, h):
        print(f"Capturing region: {x}, {y}, {w}x{h}")
        # Removed blocking dialog
        
        try:
            img = capture.capture_region(x, y, w, h)
            print(f"Image captured successfully: {img.size}")
            
            # Run OCR in background thread
            self.captureStarted.emit()
            self.worker = Worker(img)
            self.worker.finished.connect(self.on_ocr_finished)
            self.worker.error.connect(self.on_ocr_error)
            self.worker.start()
            
        except Exception as e:
            error_msg = f"Capture error: {str(e)}\n\n{traceback.format_exc()}"
            print(error_msg)
            QMessageBox.critical(None, "Capture Error", error_msg)

    def on_ocr_finished(self, text):
        print(f"OCR Finished: {text[:100]}...")
        clipboard.copy_to_clipboard(text)
        history.add_entry(text)
        self._history = history.load_history()
        self.historyChanged.emit()
        self.ocrSuccess.emit(text)
        # Removed blocking success dialog

    def on_ocr_error(self, err):
        error_msg = f"OCR Error: {err}"
        print(error_msg)
        QMessageBox.critical(None, "OCR Error", error_msg)

    @Slot(int)
    def copyHistoryItem(self, index):
        if 0 <= index < len(self._history):
            text = self._history[index]['text']
            clipboard.copy_to_clipboard(text)
            print("Copied from history")

    @Slot()
    def clearHistory(self):
        history.clear_history()
        self._history = []
        self.historyChanged.emit()
    
    @Property(str, notify=hotkeyChanged)
    def hotkeyDisplay(self):
        """Get user-friendly hotkey display string."""
        return self._config.get_hotkey_display()
    
    @Slot(str)
    def setHotkey(self, hotkey_pynput_format: str):
        """
        Update the hotkey configuration.
        
        Args:
            hotkey_pynput_format: Hotkey in pynput format (e.g., '<ctrl>+<shift>+c')
        """
        self._config.set_hotkey(hotkey_pynput_format)
        self.hotkeyChanged.emit(self._config.get_hotkey_display())
        self.hotkeyUpdateRequested.emit(hotkey_pynput_format)
    
    @Property(str)
    def apiKey(self):
        """Get the Gemini API key (masked for display)."""
        key = self._config.get_api_key()
        if len(key) > 8:
            return key[:4] + "..." + key[-4:]
        return key if key else ""
    
    @Slot(str)
    def setApiKey(self, api_key: str):
        """
        Set the Gemini API key.
        
        Args:
            api_key: The API key to store
        """
        self._config.set_api_key(api_key.strip())
    
    @Property(bool, notify=autostartChanged)
    def autostartEnabled(self):
        """Get whether autostart is enabled."""
        return self._config.get_autostart_enabled()
    
    @Slot(bool)
    def setAutostartEnabled(self, enabled: bool):
        """
        Enable or disable autostart.
        
        Args:
            enabled: True to start on login, False to disable
        """
        self._config.set_autostart_enabled(enabled)
        self.autostartChanged.emit(enabled)
        self.autostartUpdateRequested.emit(enabled)
