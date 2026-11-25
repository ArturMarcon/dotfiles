import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell._Window
import Quickshell.Hyprland

Item {
    id: powerRoot
    implicitWidth: panel.width
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

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

    HudPanel {
        id: panel
        width: 32
        height: Theme.pillHeight
        fillColor: powerRoot.popupOpen ? Theme.panelActive : (pillArea.containsMouse ? "#cc5a1a24" : Theme.panelFill)
        strokeColor: powerRoot.popupOpen || pillArea.containsMouse ? Theme.heartLight : Theme.panelStroke

        Glyph {
            anchors.centerIn: parent
            name: "power"
            size: 15
            color: pillArea.containsMouse || powerRoot.popupOpen ? Theme.sunbeam : Theme.crimson
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

    // Rest Menu Popup
    PopupWindow {
        id: powerPopup
        visible: powerRoot.popupOpen
        color: "transparent"
        implicitWidth: 250
        implicitHeight: powerColumn.implicitHeight + 28
        anchor.window: powerRoot.barWindow
        anchor.rect.x: powerRoot.mapToItem(null, 0, 0).x - (250 - panel.width)
        anchor.rect.y: Theme.barHeight + 4

        onClosed: {
            powerRoot.lastCloseTime = Date.now();
            powerRoot.popupOpen = false;
        }

        HudPanel {
            anchors.fill: parent
            cut: 10
            fillColor: Theme.popupFill
            strokeColor: Theme.popupStroke

            ColumnLayout {
                id: powerColumn
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Glyph {
                        name: "campfire"
                        size: 22
                        color: Theme.amber
                    }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "Rest"
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            color: Theme.sunbeam
                        }
                        Text {
                            text: "Session & power"
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeSmall
                            font.italic: true
                            color: Theme.leaf
                        }
                    }
                }

                Flourish {
                    Layout.fillWidth: true
                }

                Repeater {
                    model: [
                        { title: "Stasis", subtitle: "Lock screen", icon: "lock", cmd: "qs -p /home/arturmarcon/.config/quickshell/hyrule-lock/shell.qml || loginctl lock-session &", color: Theme.sunlit },
                        { title: "Rest by the Fire", subtitle: "Suspend to RAM", icon: "campfire", cmd: "systemctl suspend &", color: Theme.amber },
                        { title: "Blood Moon", subtitle: "Reboot system", icon: "blood-moon", cmd: "systemctl reboot &", color: Theme.heartLight },
                        { title: "Depart", subtitle: "Power off system", icon: "power", cmd: "systemctl poweroff &", color: Theme.crimson }
                    ]

                    delegate: MenuEntry {
                        title: modelData.title
                        subtitle: modelData.subtitle
                        icon: modelData.icon
                        accent: modelData.color
                        onActivated: {
                            procPower.command = ["bash", "-c", modelData.cmd];
                            procPower.running = true;
                            powerRoot.popupOpen = false;
                        }
                    }
                }
            }
        }
    }

    Process {
        id: procPower
    }
}
