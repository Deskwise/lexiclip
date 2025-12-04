"""Configuration management for Lexiclip OCR."""

from PySide6.QtCore import QSettings


class Config:
    """Manages application configuration with persistent storage."""
    
    def __init__(self):
        """Initialize configuration with QSettings."""
        self.settings = QSettings("Lexiclip", "Lexiclip OCR")
        
    def get_hotkey(self) -> str:
        """
        Get the configured hotkey combination.
        
        Returns:
            Hotkey string in pynput format (e.g., '<ctrl>+<shift>+o')
        """
        return self.settings.value("hotkey", "<ctrl>+<shift>+o")
    
    def set_hotkey(self, hotkey: str):
        """
        Set the hotkey combination.
        
        Args:
            hotkey: Hotkey string in pynput format
        """
        self.settings.setValue("hotkey", hotkey)
        self.settings.sync()
    
    def get_hotkey_display(self) -> str:
        """
        Get user-friendly hotkey display string.
        
        Returns:
            Human-readable hotkey string (e.g., 'Ctrl+Shift+O')
        """
        hotkey = self.get_hotkey()
        
        # Convert pynput format to display format
        display = hotkey.replace("<", "").replace(">", "")
        display = display.replace("ctrl", "Ctrl")
        display = display.replace("shift", "Shift")
        display = display.replace("alt", "Alt")
        display = display.replace("cmd", "Cmd")
        display = display.replace("+", " + ")
        
        # Capitalize each key
        parts = [p.strip() for p in display.split("+")]
        return " + ".join([p.capitalize() for p in parts])
    
    def get_api_key(self) -> str:
        """
        Get the Gemini API key.
        
        Returns:
            API key string (empty if not set)
        """
        return self.settings.value("gemini_api_key", "")
    
    def set_api_key(self, api_key: str):
        """
        Set the Gemini API key.
        
        Args:
            api_key: The API key to store
        """
        self.settings.setValue("gemini_api_key", api_key)
        self.settings.sync()
    
    def get_autostart_enabled(self) -> bool:
        """
        Get whether autostart is enabled.
        
        Returns:
            True if autostart is enabled, False otherwise
        """
        return self.settings.value("autostart_enabled", True, type=bool)
    
    def set_autostart_enabled(self, enabled: bool):
        """
        Set whether autostart is enabled.
        
        Args:
            enabled: True to enable autostart, False to disable
        """
        self.settings.setValue("autostart_enabled", enabled)
        self.settings.sync()
