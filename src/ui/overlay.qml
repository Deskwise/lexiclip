import QtQuick
import QtQuick.Window

Window {
    id: overlay
    visible: false
    color: "transparent"
    // Frameless, StayOnTop, BypassWindowManager (for X11 overlay)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.X11BypassWindowManagerHint
    
    // Cover entire virtual desktop (all monitors)
    Component.onCompleted: {
        // Get virtual desktop bounds
        var minX = 0, minY = 0, maxX = 0, maxY = 0;
        var monitors = bridge.monitors;
        
        if (monitors.length > 0) {
            minX = monitors[0].x;
            minY = monitors[0].y;
            maxX = monitors[0].x + monitors[0].width;
            maxY = monitors[0].y + monitors[0].height;
            
            for (var i = 1; i < monitors.length; i++) {
                var mon = monitors[i];
                minX = Math.min(minX, mon.x);
                minY = Math.min(minY, mon.y);
                maxX = Math.max(maxX, mon.x + mon.width);
                maxY = Math.max(maxY, mon.y + mon.height);
            }
            
            overlay.x = minX;
            overlay.y = minY;
            overlay.width = maxX - minX;
            overlay.height = maxY - minY;
            
            console.log("Overlay covers: x=" + minX + ", y=" + minY + ", w=" + (maxX - minX) + ", h=" + (maxY - minY));
        } else {
            // Fallback to primary screen
            overlay.x = 0;
            overlay.y = 0;
            overlay.width = Screen.width;
            overlay.height = Screen.height;
        }
    }

    property int startX: 0
    property int startY: 0
    property bool selecting: false

    Connections {
        target: bridge
        function onCaptureRequested() {
            overlay.visible = true
            overlay.selecting = false
            overlay.startX = 0
            overlay.startY = 0
            overlay.requestActivate()
        }
    }

    // Dim background
    Rectangle {
        anchors.fill: parent
        color: "#40000000" // Semi-transparent black
    }

    Rectangle {
        id: selectionRect
        visible: overlay.selecting
        color: "#20FFFFFF" // Very light fill
        border.color: "#00AAFF" // Plasma blue
        border.width: 2
        
        // Calculate geometry based on drag
        x: Math.min(overlay.startX, mouseArea.mouseX)
        y: Math.min(overlay.startY, mouseArea.mouseY)
        width: Math.abs(mouseArea.mouseX - overlay.startX)
        height: Math.abs(mouseArea.mouseY - overlay.startY)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        
        onPressed: {
            overlay.startX = mouseX
            overlay.startY = mouseY
            overlay.selecting = true
        }
        
        onReleased: {
            if (overlay.selecting) {
                overlay.selecting = false
                overlay.visible = false
                
                // Translate overlay-relative coordinates to absolute screen coordinates
                var rx = selectionRect.x + overlay.x
                var ry = selectionRect.y + overlay.y
                var rw = selectionRect.width
                var rh = selectionRect.height
                
                console.log("Selection: overlay-rel(" + selectionRect.x + "," + selectionRect.y + ") -> abs(" + rx + "," + ry + ") size=" + rw + "x" + rh);
                
                // Don't capture if too small
                if (rw > 5 && rh > 5) {
                    bridge.captureRegion(rx, ry, rw, rh)
                }
            }
        }
        
        // Right click to cancel
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                overlay.selecting = false
                overlay.visible = false
            }
        }
    }
    
    // Escape key to cancel
    Shortcut {
        sequence: "Esc"
        onActivated: {
            overlay.selecting = false
            overlay.visible = false
        }
    }
}
