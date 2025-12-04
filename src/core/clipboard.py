from PySide6.QtGui import QGuiApplication, QClipboard

def copy_to_clipboard(text: str):
    """
    Copies text to the system clipboard.
    Requires a QGuiApplication to be running.
    """
    clipboard = QGuiApplication.clipboard()
    if clipboard:
        clipboard.setText(text, QClipboard.Mode.Clipboard)
        # Also copy to selection (primary selection) on Linux for middle-click paste
        clipboard.setText(text, QClipboard.Mode.Selection)
    else:
        print("Error: Could not access clipboard (No QGuiApplication?)")
