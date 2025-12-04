import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: window
    visible: true
    width: 440
    height: 680
    minimumWidth: 380
    minimumHeight: 580
    title: "Lexiclip"
    
    // Dark theme color palette
    readonly property color surfaceColor: "#1a1d2e"  // Dark navy background
    readonly property color surfaceTextColor: "#ffffff"  // White text
    readonly property color primaryColor: "#5c6bc0"  // Premium Indigo
    readonly property color primaryTextColor: "#ffffff"
    readonly property color surfaceVariant: "#252836"  // Lighter dark for cards
    readonly property color outlineColor: "#2d3142"  // Subtle borders
    readonly property color secondaryText: "#9ca3af"  // Light gray
    readonly property color hoverColor: "#2f334d"  // Lighter for hover states
    
    SystemPalette { id: palette; colorGroup: SystemPalette.Active }
    color: surfaceColor

    // Handle close event - hide to tray instead of quitting
    onClosing: function(close) {
        close.accepted = false  // Prevent actual quit
        window.hide()  // Hide to tray
    }

    // Handle minimize - hide to tray
    onVisibilityChanged: {
        if (window.visibility === Window.Minimized) {
            window.hide()
        }
    }

    // Processing state
    property bool isProcessing: false

    Connections {
        target: bridge
        function onCaptureStarted() {
            isProcessing = true
        }
        function onOcrSuccess(text) {
            isProcessing = false
            showSuccessToast()
            // Populate and select text in the new text box
            capturedTextArea.text = text
            capturedTextArea.selectAll()
            capturedTextArea.forceActiveFocus()
            
            window.show()
            window.raise()
            window.requestActivate()
        }
    }

    // Success Toast
    Rectangle {
        id: successToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: toastContent.width + 40
        height: 48
        radius: 24
        color: "#43a047"  // Success green
        visible: false
        z: 1000
        
        // Elevation shadow
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 2
            radius: 8
            samples: 16
            color: Qt.rgba(0, 0, 0, 0.2)
        }

        RowLayout {
            id: toastContent
            anchors.centerIn: parent
            spacing: 8

            Image {
                source: "../../assets/icons/success.svg"
                width: 24
                height: 24
                sourceSize.width: 24
                sourceSize.height: 24
            }

            Label {
                id: successLabel
                text: "Copied to clipboard"
                color: "white"
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        SequentialAnimation {
            id: toastAnimation
            NumberAnimation {
                target: successToast
                property: "opacity"
                from: 0
                to: 1
                duration: 200
            }
            PauseAnimation { duration: 2000 }
            NumberAnimation {
                target: successToast
                property: "opacity"
                from: 1
                to: 0
                duration: 200
            }
            onFinished: successToast.visible = false
        }
    }

    function showSuccessToast() {
        successToast.visible = true
        successToast.opacity = 0
        toastAnimation.start()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        anchors.bottomMargin: 16
        spacing: 20

        // Settings icon - top right
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            Button {
                anchors.right: parent.right
                width: 32
                height: 32
                flat: true
                
                onClicked: settingsLoader.active = true
                
                contentItem: Image {
                    source: "../../assets/icons/menu.svg"
                    width: 24
                    height: 24
                    sourceSize.width: 24
                    sourceSize.height: 24
                    anchors.centerIn: parent
                    opacity: parent.hovered ? 1.0 : 0.7
                    
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        // Header Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                text: "Lexiclip"
                font.pixelSize: 36
                font.weight: Font.Bold
                color: surfaceTextColor
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Press " + bridge.hotkeyDisplay + " to capture"
                font.pixelSize: 14
                color: secondaryText
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Main Capture Button - Google style
        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: 48  // Reduced from 56
            text: isProcessing ? "Processing..." : "Capture Text"
            enabled: !isProcessing
            scale: down ? 0.98 : 1.0
            
            onClicked: {
                bridge.triggerCapture()
            }
            
            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
            
            background: Rectangle {
                color: parent.down ? "#2d3142" : 
                       parent.hovered ? "#353849" : "#2a2d3e"
                radius: 8
                
                // Material elevation
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: parent.down ? 2 : (parent.hovered ? 6 : 4)
                    radius: parent.down ? 4 : (parent.hovered ? 10 : 8)
                    samples: 16
                    color: Qt.rgba(0, 0, 0, parent.hovered ? 0.2 : 0.15)
                }
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            contentItem: RowLayout {
                spacing: 12
                
                BusyIndicator {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    running: isProcessing
                    visible: isProcessing
                    
                    contentItem: Item {
                        implicitWidth: 24
                        implicitHeight: 24
                        
                        Rectangle {
                            width: parent.width
                            height: parent.height
                            radius: width / 2
                            border.width: 3
                            border.color: primaryTextColor
                            color: "transparent"
                            opacity: 0.3
                        }
                        
                        Rectangle {
                            id: spinner
                            width: parent.width
                            height: parent.height
                            radius: width / 2
                            border.width: 3
                            border.color: primaryTextColor
                            color: "transparent"
                            
                            Rectangle {
                                width: parent.width / 4
                                height: parent.height / 4
                                radius: width / 2
                                color: primaryTextColor
                                x: parent.width / 2 - width / 2
                                y: 0
                            }
                            
                            RotationAnimation {
                                target: spinner
                                property: "rotation"
                                from: 0
                                to: 360
                                duration: 1000
                                running: isProcessing
                                loops: Animation.Infinite
                            }
                        }
                    }
                }
                
                Text {
                    text: parent.parent.text
                    font.pixelSize: 17  // Increased from 15
                    font.weight: Font.Medium
                    color: primaryTextColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }
                
                Item { width: isProcessing ? 24 : 0 }  // Balance spacing
            }
        }

        // History Section
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Recent Captures"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: secondaryText
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.5
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Clear"
                    flat: true
                    font.pixelSize: 12
                    visible: historyList.count > 0
                    onClicked: bridge.clearHistory()
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: parent.hovered ? "#d32f2f" : secondaryText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // History Card (Top Half)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                color: surfaceVariant
                radius: 8
                
                // Material elevation
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 1
                    radius: 3
                    samples: 8
                    color: Qt.rgba(0, 0, 0, 0.08)
                }

                ListView {
                    id: historyList
                    anchors.fill: parent
                    anchors.margins: 4
                    clip: true
                    model: bridge.historyModel
                    spacing: 0
                    
                    ScrollBar.vertical: ScrollBar {
                        active: true
                        width: 10
                    }
                    
                    // Empty state
                    Label {
                        visible: historyList.count === 0
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -20
                        text: "No captures yet"
                        color: secondaryText
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    delegate: Item {
                        width: parent.width - 12 // Space for scrollbar
                        height: 40 // Compact height
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: itemMouse.containsMouse ? hoverColor : "transparent"
                            radius: 4
                            
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: modelData.snippet
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    color: surfaceTextColor
                                    maximumLineCount: 1
                                }
                                
                                Text {
                                    text: modelData.timestamp
                                    font.pixelSize: 11
                                    color: secondaryText
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    bridge.copyHistoryItem(index)
                                    // Also populate the text box
                                    capturedTextArea.text = modelData.text
                                    capturedTextArea.selectAll()
                                    capturedTextArea.forceActiveFocus()
                                    showSuccessToast()
                                }
                            }
                        }
                    }
                }
            }
            
            // Text Box Area (Bottom Half - "Red Box" area)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: "white"
                radius: 8
                
                // Material elevation
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 1
                    radius: 3
                    samples: 8
                    color: Qt.rgba(0, 0, 0, 0.08)
                }
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 8
                    
                    TextArea {
                        id: capturedTextArea
                        placeholderText: "Captured text will appear here..."
                        color: "black"
                        font.pixelSize: 14
                        font.family: "Monospace" // Good for code/data
                        selectByMouse: true
                        selectionColor: primaryColor
                        selectedTextColor: "white"
                        wrapMode: TextEdit.Wrap
                        background: null // Remove default background
                        
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            cursorShape: Qt.IBeamCursor
                            onClicked: (mouse) => {
                                contextMenu.popup()
                            }
                        }

                        Menu {
                            id: contextMenu
                            
                            MenuItem {
                                text: "Cut"
                                enabled: capturedTextArea.selectedText.length > 0
                                onTriggered: capturedTextArea.cut()
                            }
                            MenuItem {
                                text: "Copy"
                                enabled: capturedTextArea.selectedText.length > 0
                                onTriggered: capturedTextArea.copy()
                            }
                            MenuItem {
                                text: "Paste"
                                enabled: capturedTextArea.canPaste
                                onTriggered: capturedTextArea.paste()
                            }
                            MenuItem {
                                text: "Select All"
                                onTriggered: capturedTextArea.selectAll()
                            }
                            
                            MenuSeparator { visible: capturedTextArea.selectedText.length > 0 }
                            
                            MenuItem {
                                text: "Search on Google"
                                visible: capturedTextArea.selectedText.length > 0
                                onTriggered: Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(capturedTextArea.selectedText))
                            }
                        }
                    }
                }
            }

            // Helpful hint
            Label {
                text: "Click any item to copy again"
                font.pixelSize: 12
                color: secondaryText
                Layout.alignment: Qt.AlignHCenter
                visible: historyList.count > 0
            }
        }


    }

    Loader {
        id: settingsLoader
        active: false
        source: "Settings.qml"
        onLoaded: item.visible = true
        Connections {
            target: settingsLoader.item
            function onVisibleChanged() {
                if (!settingsLoader.item.visible) {
                    settingsLoader.active = false
                }
            }
        }
    }
}
