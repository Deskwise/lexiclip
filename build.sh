#!/bin/bash
source venv/bin/activate
pyinstaller --name PlasmaOCR \
            --onefile \
            --windowed \
            --add-data "src/ui/*.qml:src/ui" \
            --hidden-import "PySide6.QtQml" \
            --hidden-import "PySide6.QtQuick" \
            --hidden-import "PySide6.QtQuick.Controls" \
            --hidden-import "PySide6.QtQuick.Layouts" \
            --hidden-import "PySide6.QtQuick.Window" \
            main.py
echo "Build complete. Executable is in dist/PlasmaOCR"
