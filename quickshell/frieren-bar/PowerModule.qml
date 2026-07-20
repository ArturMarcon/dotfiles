import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell._Window
import Quickshell.Hyprland

Item {
    id: powerRoot
    implicitWidth: width
    implicitHeight: height
    width: pill.width
    height: Theme.pillHeight
    
    property var barWindow: null
    property bool popupOpen: false
    property double lastCloseTime: 0

    HyprlandFocusGrab {
        active: powerRoot.popupOpen
        windows: [ powerPopup ]
        onCleared: {
            powerRoot.popupOpen = false;
        }
    }

    Rectangle {
        id: pill
        implicitWidth: width
        implicitHeight: height
        width: powerRoot.popupOpen || pillArea.containsMouse ? 38 : 34
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: powerRoot.popupOpen ? Theme.bgWidgetActive : (pillArea.containsMouse ? Theme.starkRed : Theme.bgWidget)
        border.width: 1
        border.color: powerRoot.popupOpen ? Theme.zoltraakGold : (pillArea.containsMouse ? Theme.zoltraakGold : Theme.borderSubtle)

        Behavior on width { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Subtle glow aura
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.starkRed
            opacity: powerRoot.popupOpen || pillArea.containsMouse ? 0.5 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
        }

        Text {
            anchors.centerIn: parent
            text: "\uf011"
            font.family: Theme.fontFamily
            font.pixelSize: 15
            color: pillArea.containsMouse || powerRoot.popupOpen ? Theme.zoltraakGold : Theme.starkRed
            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (Date.now() - powerRoot.lastCloseTime < 200) return;
                powerRoot.popupOpen = !powerRoot.popupOpen;
            }
        }
    }

    // Journey's Rest Power Popup Window
    PopupWindow {
        id: powerPopup
        visible: powerRoot.popupOpen
        color: "transparent"
        implicitWidth: 240
        implicitHeight: 310
        anchor.window: powerRoot.barWindow
        anchor.rect.x: powerRoot.mapToItem(null, 0, 0).x - (240 - pill.width)
        anchor.rect.y: Theme.barHeight + 4

        onClosed: {
            powerRoot.lastCloseTime = Date.now();
            powerRoot.popupOpen = false;
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.bgPanelTranslucent
            border.width: 1
            border.color: Theme.starkRed

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
                        color: Theme.starkRed
                    }
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Journey's Rest"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: "Session & Power Relic"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.starkRed
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderSubtle
                }

                // Power Actions
                Repeater {
                    model: [
                        { title: "Arcane Seal", subtitle: "Lock Screen", icon: "\uf023", cmd: "qs -p /home/arturmarcon/.config/quickshell/frieren-lock/lockscreen.qml || loginctl lock-session &", color: Theme.zoltraakGold },
                        { title: "Slumber", subtitle: "Suspend to RAM", icon: "\uf186", cmd: "systemctl suspend &", color: Theme.arcaneViolet },
                        { title: "Rebirth", subtitle: "Reboot System", icon: "\uf021", cmd: "systemctl reboot &", color: Theme.himmelBlue },
                        { title: "Depart", subtitle: "Power Off System", icon: "\uf011", cmd: "systemctl poweroff &", color: Theme.starkRed }
                    ]

                    delegate: Rectangle {
                        id: actBtn
                        Layout.fillWidth: true
                        height: 44
                        radius: 8
                        color: actArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget
                        border.width: 1
                        border.color: actArea.containsMouse ? modelData.color : Theme.borderSubtle

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
                                color: actArea.containsMouse ? modelData.color : Theme.textMuted
                            }
                        }

                        MouseArea {
                            id: actArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                procPower.command = ["bash", "-c", modelData.cmd];
                                procPower.running = true;
                                powerRoot.popupOpen = false;
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Process {
        id: procPower
    }
}
