import sys
import os
import pathlib
import platform

class PlatformUtils:
    @staticmethod
    def get_platform():
        if sys.platform.startswith('win'):
            return 'windows'
        elif sys.platform.startswith('darwin'):
            return 'macos'
        else:
            return 'linux'

    @staticmethod
    def get_resource_path(relative_path: str) -> pathlib.Path:
        """
        Get the absolute path to a resource, works for dev and for PyInstaller.
        """
        try:
            # PyInstaller creates a temp folder and stores path in _MEIPASS
            base_path = pathlib.Path(sys._MEIPASS)
            # When frozen, assets are usually at the root of the temp dir or in a specific folder
            # depending on how they were added in datas.
            # In spec file: datas=[('src/ui/*.qml', 'src/ui')]
            # If we add assets, we should check where they land.
            # For this project structure, let's assume assets are copied to root or 'assets' folder.
        except Exception:
            # Running in a normal Python environment
            # This file is in src/core/platform_utils.py
            # Root is ../../
            base_path = pathlib.Path(__file__).parent.parent.parent

        return (base_path / relative_path).resolve()

    @staticmethod
    def ensure_autostart(enabled: bool):
        """
        Ensures the application is set to autostart (or not) based on the enabled flag.
        Also handles desktop shortcut creation if applicable.
        """
        current_platform = PlatformUtils.get_platform()
        
        if current_platform == 'linux':
            PlatformUtils._ensure_autostart_linux(enabled)
        elif current_platform == 'windows':
            PlatformUtils._ensure_autostart_windows(enabled)
        elif current_platform == 'macos':
            PlatformUtils._ensure_autostart_macos(enabled)

    @staticmethod
    def _ensure_autostart_linux(enabled: bool):
        home = pathlib.Path.home()
        autostart_dir = home / ".config" / "autostart"
        autostart_dir.mkdir(parents=True, exist_ok=True)
        desktop_dir = home / "Desktop"
        desktop_dir.mkdir(parents=True, exist_ok=True)

        exec_path = pathlib.Path(sys.executable).resolve()
        
        if getattr(sys, 'frozen', False):
            exec_cmd = str(exec_path)
            # In frozen mode, we expect assets to be bundled.
            # However, for the desktop file Icon entry, we need a permanent path on disk,
            # not the temp path in _MEIPASS which disappears.
            # So usually we'd install the icon to /usr/share/icons or ~/.local/share/icons.
            # For this portable app approach, we might point to the executable itself if it has an icon,
            # or we might fail to show an icon if it's not extracted.
            # Fallback: try to find the icon relative to the AppImage/executable if possible.
            icon_path = exec_path.parent / "assets/icons/app_icon.svg"
        else:
            # Running from source
            root_dir = pathlib.Path(__file__).parent.parent.parent
            script_path = root_dir / "main.py"
            exec_cmd = f"{exec_path} {script_path}"
            icon_path = root_dir / "assets/icons/app_icon.svg"

        # If icon doesn't exist at the expected location, try to use the one in the source tree
        # This is a best-effort for the desktop file
        if not icon_path.exists():
             icon_path = PlatformUtils.get_resource_path("assets/icons/app_icon.svg")

        desktop_content = f"[Desktop Entry]\n" \
                         f"Type=Application\n" \
                         f"Name=Lexiclip OCR\n" \
                         f"Exec={exec_cmd}\n" \
                         f"Icon={icon_path}\n" \
                         f"Terminal=false\n" \
                         f"StartupNotify=true\n"

        autostart_path = autostart_dir / "lexiclip.desktop"
        desktop_path = desktop_dir / "lexiclip.desktop"
        
        # Always create desktop shortcut on Linux if it doesn't exist
        if not desktop_path.exists():
            try:
                desktop_path.write_text(desktop_content)
                desktop_path.chmod(0o755)
            except Exception as e:
                print(f"Failed to create desktop shortcut: {e}")
        
        # Handle autostart
        if enabled:
            if not autostart_path.exists():
                try:
                    autostart_path.write_text(desktop_content)
                    autostart_path.chmod(0o755)
                except Exception as e:
                    print(f"Failed to create autostart entry: {e}")
        else:
            if autostart_path.exists():
                try:
                    autostart_path.unlink()
                except Exception as e:
                    print(f"Failed to remove autostart entry: {e}")

    @staticmethod
    def _ensure_autostart_windows(enabled: bool):
        try:
            import winreg
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 
                               r"Software\Microsoft\Windows\CurrentVersion\Run", 
                               0, winreg.KEY_ALL_ACCESS)
            
            app_name = "LexiclipOCR"
            
            if enabled:
                exe_path = sys.executable
                # If frozen, use the executable path.
                # If running from source, we generally don't support autostart easily without a bat file wrapper,
                # but we can try pointing to pythonw.exe + script.
                if getattr(sys, 'frozen', False):
                    winreg.SetValueEx(key, app_name, 0, winreg.REG_SZ, exe_path)
                else:
                    # Running from source on Windows
                    # This is tricky because we need arguments.
                    # winreg value can contain arguments.
                    script_path = pathlib.Path(__file__).parent.parent.parent / "main.py"
                    # Use pythonw.exe to avoid console window if possible, or just sys.executable
                    cmd = f'"{exe_path}" "{script_path.resolve()}"'
                    winreg.SetValueEx(key, app_name, 0, winreg.REG_SZ, cmd)
            else:
                try:
                    winreg.DeleteValue(key, app_name)
                except FileNotFoundError:
                    pass
            
            winreg.CloseKey(key)
        except ImportError:
            print("winreg module not found (not on Windows?)")
        except Exception as e:
            print(f"Windows autostart error: {e}")

    @staticmethod
    def _ensure_autostart_macos(enabled: bool):
        """
        Manage macOS autostart via LaunchAgents.
        """
        home = pathlib.Path.home()
        launch_agents = home / "Library" / "LaunchAgents"
        launch_agents.mkdir(parents=True, exist_ok=True)
        plist_path = launch_agents / "com.lexiclip.ocr.plist"
        
        if enabled:
            # Determine executable path
            if getattr(sys, 'frozen', False):
                # In a .app bundle, sys.executable points to the binary inside Contents/MacOS
                # We want to launch that directly.
                exec_path = sys.executable
                args = [str(exec_path)]
            else:
                # Running from source
                # Use sys.executable (python) and main.py path
                exec_path = sys.executable
                script_path = pathlib.Path(__file__).parent.parent.parent / "main.py"
                args = [str(exec_path), str(script_path.resolve())]

            # Construct Plist content
            # We use a simple string formatting here to avoid external dependencies like plistlib if not needed,
            # but plistlib is standard library, so let's use it for safety if we were being robust.
            # For now, simple string is fine and readable.
            
            args_xml = "\n".join([f"            <string>{arg}</string>" for arg in args])
            
            plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.lexiclip.ocr</string>
    <key>ProgramArguments</key>
    <array>
{args_xml}
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>"""
            
            try:
                plist_path.write_text(plist_content)
            except Exception as e:
                print(f"Failed to create macOS autostart plist: {e}")
                
        else:
            if plist_path.exists():
                try:
                    plist_path.unlink()
                except Exception as e:
                    print(f"Failed to remove macOS autostart plist: {e}")
