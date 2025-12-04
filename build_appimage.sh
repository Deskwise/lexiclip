#!/bin/bash
set -e

# 1. Build with PyInstaller
echo "Building with PyInstaller..."
# Ensure we are using the venv python if available, or system python
PYTHON_CMD="python3"
if [ -d "venv" ]; then
    PYTHON_CMD="./venv/bin/python3"
fi
$PYTHON_CMD -m PyInstaller PlasmaOCR.spec

# 2. Prepare AppDir
echo "Preparing AppDir..."
rm -rf AppDir
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
mkdir -p AppDir/usr/share/applications

# Copy Executable (onedir mode produces a directory, we need to copy the contents)
# But wait, AppImage usually expects a single binary or a wrapper script in usr/bin.
# Since we are using onedir (directory based), we should copy the whole folder to usr/bin/PlasmaOCR
# and create a symlink or wrapper.
# Actually, for AppImage, 'onefile' is often easier, but 'onedir' is faster to start.
# Let's copy the 'dist/PlasmaOCR' FOLDER to 'AppDir/usr/bin/PlasmaOCR'
cp -r dist/PlasmaOCR AppDir/usr/bin/

# Copy Icon
cp assets/icons/app_icon.svg AppDir/usr/share/icons/hicolor/256x256/apps/lexiclip.svg
cp assets/icons/app_icon.svg AppDir/lexiclip.svg # For the root dir

# Create Desktop File
cat > AppDir/lexiclip.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Lexiclip OCR
Exec=PlasmaOCR/PlasmaOCR
Icon=lexiclip
Categories=Utility;
Terminal=false
EOF

# Create AppRun
# Since our executable is in a subdirectory (usr/bin/PlasmaOCR/PlasmaOCR),
# we need a custom AppRun script to point to it.
cat > AppDir/AppRun <<EOF
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export PATH="\${HERE}/usr/bin/PlasmaOCR:\${PATH}"
export LD_LIBRARY_PATH="\${HERE}/usr/lib:\${LD_LIBRARY_PATH}"
exec "\${HERE}/usr/bin/PlasmaOCR/PlasmaOCR" "\$@"
EOF
chmod +x AppDir/AppRun

# 3. Generate AppImage
echo "Generating AppImage..."
if [ ! -f appimagetool-x86_64.AppImage ]; then
    wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

# Run appimagetool
# ARCH=x86_64 ./appimagetool-x86_64.AppImage AppDir LexiclipOCR-x86_64.AppImage
# Note: In some environments (like Docker), FUSE might not be available.
# We can use --appimage-extract-and-run to run appimagetool itself if needed,
# or pass --no-appimage-sanity-check if building *inside* docker without fuse.

./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir LexiclipOCR-x86_64.AppImage

echo "Build Complete: LexiclipOCR-x86_64.AppImage"
