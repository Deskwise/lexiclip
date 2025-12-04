from PySide6.QtWidgets import QMainWindow, QLabel

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("PlasmaOCR")
        self.resize(400, 300)
        label = QLabel("PlasmaOCR MVP", self)
        label.move(100, 100)
