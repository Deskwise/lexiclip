
from PySide6.QtGui import QImageReader, QIcon
from PySide6.QtWidgets import QApplication
import sys
import pathlib

app = QApplication(sys.argv)

print("Supported Image Formats:")
print([fmt.data().decode('utf-8') for fmt in QImageReader.supportedImageFormats()])

icon_path = pathlib.Path("src/ui/assets/icons/app_icon.svg").resolve()
# Try relative path if that fails, based on where we run it
if not icon_path.exists():
    icon_path = pathlib.Path("assets/icons/app_icon.svg").resolve()

print(f"\nChecking icon at: {icon_path}")
if icon_path.exists():
    icon = QIcon(str(icon_path))
    print(f"Icon isNull: {icon.isNull()}")
    print(f"Available Sizes: {icon.availableSizes()}")
    
    # Try to get a pixmap
    pixmap = icon.pixmap(64, 64)
    print(f"Pixmap isNull: {pixmap.isNull()}")
else:
    print("Icon file not found for test.")
