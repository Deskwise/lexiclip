import sys
import signal
import os
import pathlib
from PySide6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
from PySide6.QtGui import QIcon, QAction
from PySide6.QtCore import QSharedMemory, QBuffer, QIODevice
from PySide6.QtQml import QQmlApplicationEngine
from src.ui.controller import Controller
from pynput import keyboard

from src.core.platform_utils import PlatformUtils

def ensure_autostart():
    """Create desktop shortcuts and optionally autostart file based on config."""
    from src.core.config import Config
    config = Config()
    PlatformUtils.ensure_autostart(config.get_autostart_enabled())

# Call the function early so the shortcut exists before the UI shows
ensure_autostart()

def main():
    # Load environment variables
    from dotenv import load_dotenv
    load_dotenv()
    
    # Allow Ctrl+C to kill the app
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    app.setOrganizationName("Lexiclip")
    app.setApplicationName("Lexiclip OCR")

    # Single Instance Check using QLockFile (robust against crashes)
    from PySide6.QtCore import QLockFile, QDir
    
    # Store lock file in temp directory
    lock_file_path = QDir.tempPath() + "/lexiclip.lock"
    lock_file = QLockFile(lock_file_path)
    
    # Try to lock. setStaleLockTime(0) means we don't trust old locks automatically,
    # but tryLock() will check if the PID in the lock file is actually running.
    lock_file.setStaleLockTime(0)
    
    if not lock_file.tryLock(100):
        # Check if it's really running or just a stale lock from a crash
        # QLockFile handles this check in tryLock if we configure it right, 
        # but sometimes we need to be explicit.
        # Actually, tryLock() returns false if another process holds it.
        # If the process crashed, QLockFile should detect the PID is gone and acquire it.
        
        error = lock_file.error()
        if error == QLockFile.LockError.LockFailedError:
             print("Lexiclip is already running.")
             sys.exit(0)
        else:
             # Some other error, maybe permissions?
             print(f"Could not acquire lock: {error}")
             # If it's a permission error, we might want to exit. 
             # If it's just stale, tryLock should have worked.
             sys.exit(0)

    # Set up the application icon
    icon_path = PlatformUtils.get_resource_path("assets/icons/app_icon.svg")
    app_icon = QIcon()
    
    if icon_path.exists():
        print(f"Loading icon from: {icon_path}")
        app_icon = QIcon(str(icon_path))
    else:
        print(f"Icon file not found at: {icon_path}")
    
    # Fallback if icon is null or empty
    if app_icon.isNull():
        print("Icon is null, attempting fallback to system theme...")
        if QIcon.hasThemeIcon("camera-photo"):
            app_icon = QIcon.fromTheme("camera-photo")
        elif QIcon.hasThemeIcon("application-x-executable"):
            app_icon = QIcon.fromTheme("application-x-executable")
        else:
            print("No suitable theme icon found. Creating fallback pixel map.")
            # Create a simple colored pixmap as last resort
            from PySide6.QtGui import QPixmap, QColor, QPainter
            pixmap = QPixmap(64, 64)
            pixmap.fill(QColor("transparent"))
            painter = QPainter(pixmap)
            painter.setBrush(QColor("#00897b"))
            painter.drawEllipse(0, 0, 64, 64)
            painter.end()
            app_icon = QIcon(pixmap)

    app.setWindowIcon(app_icon)
    
    if app_icon.isNull():
        print("CRITICAL: Failed to load any icon. Tray icon may not appear.")

    engine = QQmlApplicationEngine()
    controller = Controller()
    
    # Detect monitors and pass to controller
    from PySide6.QtGui import QGuiApplication
    screens = QGuiApplication.screens()
    monitors = []
    for screen in screens:
        geom = screen.geometry()
        monitors.append({
            "x": geom.x(),
            "y": geom.y(),
            "width": geom.width(),
            "height": geom.height()
        })
    controller.setMonitors(monitors)
    print(f"Detected {len(monitors)} monitor(s): {monitors}")
    
    # Expose controller to QML
    engine.rootContext().setContextProperty("bridge", controller)
    
    # Load QML files
    base_path = os.path.dirname(os.path.abspath(__file__))
    qml_path = os.path.join(base_path, "src/ui/main.qml")
    overlay_path = os.path.join(base_path, "src/ui/overlay.qml")
    
    engine.load(qml_path)
    engine.load(overlay_path)
    
    if not engine.rootObjects():
        print("Error: Could not load QML files.")
        sys.exit(-1)
        
    main_window = engine.rootObjects()[0]

    # System Tray Icon
    tray_icon = QSystemTrayIcon(app_icon, app)
    tray_icon.setToolTip("Lexiclip OCR")
    tray_menu = QMenu()
    
    show_action = QAction("Show", app)
    show_action.triggered.connect(main_window.show)
    tray_menu.addAction(show_action)
    
    quit_action = QAction("Quit", app)
    quit_action.triggered.connect(app.quit)
    tray_menu.addAction(quit_action)
    
    tray_icon.setContextMenu(tray_menu)
    tray_icon.show()
    
    if not QSystemTrayIcon.isSystemTrayAvailable():
        print("WARNING: System Tray is not available on this system. Showing main window.")
        main_window.show()
    else:
        # Optional: Show main window on startup anyway for better UX
        main_window.show()
    
    # Handle tray activation (click)
    def on_tray_activated(reason):
        if reason == QSystemTrayIcon.Trigger:
            if main_window.isVisible():
                main_window.hide()
            else:
                main_window.showNormal()  # Ensure it's not minimized
                main_window.requestActivate()
                
    tray_icon.activated.connect(on_tray_activated)

    # Hotkey Listener with dynamic configuration
    from src.core.config import Config
    config = Config()
    
    listener = None  # Will hold the current hotkey listener
    
    def on_activate():
        """Callback when hotkey is pressed."""
        print(f"Hotkey pressed!")
        controller.triggerCapture()
    
    def start_hotkey_listener(hotkey_combo: str):
        """Start or restart the hotkey listener with the given combination."""
        nonlocal listener
        
        # Stop existing listener if any
        if listener is not None:
            try:
                listener.stop()
            except:
                pass
        
        try:
            # Start new listener
            listener = keyboard.GlobalHotKeys({
                hotkey_combo: on_activate
            })
            listener.start()
            print(f"Global hotkey listener started: {config.get_hotkey_display()}")
        except Exception as e:
            print(f"Failed to start hotkey listener: {e}")
    
    # Connect controller signal to update hotkey
    def on_hotkey_update_requested(new_hotkey: str):
        """Handler for when user changes hotkey in settings."""
        print(f"Updating hotkey to: {new_hotkey}")
        start_hotkey_listener(new_hotkey)
    
    controller.hotkeyUpdateRequested.connect(on_hotkey_update_requested)
    
    # Connect autostart signal
    def on_autostart_update_requested(enabled: bool):
        """Handler for when user toggles autostart."""
        print(f"Autostart {'enabled' if enabled else 'disabled'}")
        ensure_autostart()
    
    controller.autostartUpdateRequested.connect(on_autostart_update_requested)
    
    # Start with configured hotkey
    start_hotkey_listener(config.get_hotkey())

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
