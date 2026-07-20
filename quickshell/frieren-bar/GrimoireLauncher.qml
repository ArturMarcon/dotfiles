import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell._Window
import Quickshell.Hyprland

Item {
    id: launcherRoot
    implicitWidth: width
    implicitHeight: height
    width: pill.width
    height: Theme.pillHeight
    
    property var barWindow: null
    property bool popupOpen: false
    property double lastCloseTime: 0

    HyprlandFocusGrab {
        active: launcherRoot.popupOpen
        windows: [ grimoirePopup ]
        onCleared: {
            launcherRoot.popupOpen = false;
        }
    }

    // Capsule / Pill Button
    Rectangle {
        id: pill
        implicitWidth: width
        implicitHeight: height
        width: launcherRoot.popupOpen || pillArea.containsMouse ? 116 : 38
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: launcherRoot.popupOpen ? Theme.bgWidgetActive : (pillArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget)
        border.width: 1
        border.color: launcherRoot.popupOpen ? Theme.zoltraakGold : (pillArea.containsMouse ? Theme.borderActive : Theme.borderSubtle)

        Behavior on width { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Glow effect when active
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.zoltraakGold
            opacity: launcherRoot.popupOpen ? 0.4 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            // Runic Star / Flamme Emblem
            Text {
                text: "✦"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                color: launcherRoot.popupOpen || pillArea.containsMouse ? Theme.zoltraakGold : Theme.textPrimary
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 12000
                    running: launcherRoot.popupOpen || pillArea.containsMouse
                }
            }

            // Expanded Text
            Text {
                text: "Grimoire"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.textPrimary
                visible: pill.width > 60
                opacity: pill.width > 80 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
            }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (Date.now() - launcherRoot.lastCloseTime < 200) return;
                launcherRoot.popupOpen = !launcherRoot.popupOpen;
            }
        }
    }

    // Frieren Grimoire Popup Window
    PopupWindow {
        id: grimoirePopup
        visible: launcherRoot.popupOpen
        color: "transparent"
        implicitWidth: 260
        implicitHeight: 340
        anchor.window: launcherRoot.barWindow
        anchor.rect.x: launcherRoot.mapToItem(null, 0, 0).x
        anchor.rect.y: Theme.barHeight + 4

        onClosed: {
            launcherRoot.lastCloseTime = Date.now();
            launcherRoot.popupOpen = false;
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.bgPanelTranslucent
            border.width: 1
            border.color: Theme.zoltraakGold

            // Glassmorphism and inner glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 10
                color: "transparent"
                border.width: 1
                border.color: Theme.borderSubtle
                opacity: 0.6
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: "❖"
                        font.pixelSize: 18
                        color: Theme.zoltraakGold
                    }
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Arcane Grimoire"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: "Spells & Relics of the Journey"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.arcaneViolet
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderSubtle
                }

                // Spell Buttons
                Repeater {
                    model: [
                        { title: "Arcane Seal", subtitle: "Lock Wayland Session", icon: "✧", cmd: "qs -p /home/arturmarcon/.config/quickshell/frieren-lock/lockscreen.qml &", color: Theme.zoltraakGold },
                        { title: "Runic Terminal", subtitle: "Launch Kitty Shell", icon: "◈", cmd: "kitty &", color: Theme.himmelBlue },
                        { title: "Scroll Archive", subtitle: "Browse File System", icon: "🕮", cmd: "dolphin &", color: Theme.arcaneViolet },
                        { title: "Spell Search", subtitle: "Application Launcher", icon: "✦", cmd: "rofi -show drun || wofi --show drun &", color: Theme.emeraldGreen },
                        { title: "Mana Capture", subtitle: "Capture Screenshot", icon: "❖", cmd: "grim -g \"$(slurp)\" /tmp/screenshot.png || hyprshot -m region &", color: Theme.starkRed }
                    ]

                    delegate: Rectangle {
                        id: spellBtn
                        Layout.fillWidth: true
                        height: 44
                        radius: 8
                        color: spellArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget
                        border.width: 1
                        border.color: spellArea.containsMouse ? modelData.color : Theme.borderSubtle

                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            Text {
                                text: modelData.icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                color: modelData.color
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: modelData.title
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                Text {
                                    text: modelData.subtitle
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textSecondary
                                }
                            }

                            Text {
                                text: "›"
                                font.pixelSize: 14
                                color: spellArea.containsMouse ? modelData.color : Theme.textMuted
                            }
                        }

                        MouseArea {
                            id: spellArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                procExec.command = ["bash", "-c", modelData.cmd];
                                procExec.running = true;
                                launcherRoot.popupOpen = false;
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Process {
        id: procExec
    }
}
