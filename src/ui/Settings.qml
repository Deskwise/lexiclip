import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: settingsWindow
    width: 500
    height: 550
    title: "Settings - Lexiclip"
    visible: false
    
    // Match main app dark theme
    readonly property color surfaceColor: "#1a1d2e"
    readonly property color surfaceTextColor: "#ffffff"
    readonly property color primaryColor: "#5c6bc0"
    readonly property color surfaceVariant: "#252836"
    readonly property color secondaryText: "#9ca3af"
    readonly property color outlineColor: "#2d3142"
    
    color: surfaceColor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // Header
        Label {
            text: "Settings"
            font.pixelSize: 24
            font.weight: Font.Bold
            color: surfaceTextColor
            Layout.alignment: Qt.AlignHCenter
        }

        // API Key Section
        // API Key Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Gemini API Key"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: surfaceTextColor
            }

            Pane {
                Layout.fillWidth: true
                padding: 16
                
                background: Rectangle {
                    color: surfaceVariant
                    radius: 8
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12
                    
                    TextField {
                        id: apiKeyInput
                        Layout.fillWidth: true
                        placeholderText: "sk-..."
                        echoMode: TextInput.Password
                        color: surfaceTextColor
                        font.pixelSize: 13
                        
                        background: Rectangle {
                            color: surfaceColor
                            border.color: apiKeyInput.activeFocus ? primaryColor : outlineColor
                            border.width: 2
                            radius: 4
                        }
                        
                        Component.onCompleted: {
                            text = bridge.apiKey
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Button {
                            text: "Save"
                            
                            onClicked: {
                                bridge.setApiKey(apiKeyInput.text)
                                savedLabel.visible = true
                                savedTimer.start()
                            }
                            
                            background: Rectangle {
                                color: parent.hovered ? Qt.lighter(primaryColor, 1.1) : primaryColor
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 13
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        
                        Label {
                            id: savedLabel
                            text: "✓ Saved"
                            color: "#43a047"
                            visible: false
                        }
                        
                        Timer {
                            id: savedTimer
                            interval: 2000
                            onTriggered: savedLabel.visible = false
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "Get API Key →"
                            flat: true
                            
                            onClicked: Qt.openUrlExternally("https://aistudio.google.com/app/apikey")
                            
                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 12
                                color: parent.hovered ? primaryColor : secondaryText
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }

        // Hotkey Display
        // Hotkey Display
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Capture Hotkey"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: surfaceTextColor
            }

            Pane {
                Layout.fillWidth: true
                padding: 16
                
                background: Rectangle {
                    color: surfaceVariant
                    radius: 8
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    Label {
                        text: bridge.hotkeyDisplay
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: primaryColor
                    }
                    
                    Label {
                        text: "(Configuration coming soon)"
                        font.pixelSize: 11
                        color: secondaryText
                    }
                }
            }
        }

        // Start on Login
        // Start on Login
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "Startup"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: surfaceTextColor
            }

            Pane {
                Layout.fillWidth: true
                padding: 16
                
                background: Rectangle {
                    color: surfaceVariant
                    radius: 8
                }
                
                CheckBox {
                    id: autostartCheckbox
                    text: "Start Lexiclip on Login"
                    checked: bridge.autostartEnabled
                    
                    onCheckedChanged: {
                        bridge.setAutostartEnabled(checked)
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 13
                        color: surfaceTextColor
                        leftPadding: parent.indicator.width + parent.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    indicator: Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        x: parent.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 3
                        border.color: parent.checked ? primaryColor : outlineColor
                        border.width: 2
                        color: parent.checked ? primaryColor : "transparent"
                        
                        Rectangle {
                            width: 12
                            height: 6
                            x: 4
                            y: 5
                            rotation: -45
                            visible: parent.parent.checked
                            
                            Rectangle {
                                width: 3
                                height: parent.height
                                color: "white"
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                            }
                            
                            Rectangle {
                                width: parent.width
                                height: 3
                                color: "white"
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                            }
                        }
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // Close button
        Button {
            text: "Close"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            
            onClicked: settingsWindow.visible = false
            
            background: Rectangle {
                color: parent.hovered ? "#353849" : "#2a2d3e"
                radius: 8
            }
            
            contentItem: Text {
                text: parent.text
                font.pixelSize: 14
                color: surfaceTextColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
