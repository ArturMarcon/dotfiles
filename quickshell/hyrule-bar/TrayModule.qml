import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
    id: trayRoot
    property bool hasItems: SystemTray.items && SystemTray.items.values.length > 0

    visible: hasItems
    implicitWidth: hasItems ? trayPanel.width : 0
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

    HudPanel {
        id: trayPanel
        width: trayRow.implicitWidth + 14
        height: Theme.pillHeight

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: SystemTray.items

                delegate: HudPanel {
                    id: itemBox
                    width: Theme.pillHeight - 6
                    height: Theme.pillHeight - 6
                    cut: 3
                    fillColor: itemArea.containsMouse ? Theme.panelHover : "transparent"
                    strokeColor: itemArea.containsMouse ? Theme.shrineTeal : "transparent"

                    IconImage {
                        anchors.centerIn: parent
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                        implicitSize: Theme.iconSize
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                modelData.secondaryActivate();
                            } else {
                                modelData.activate();
                            }
                        }
                    }

                    WheelHandler {
                        onWheel: (wheel) => {
                            modelData.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false);
                        }
                    }
                }
            }
        }
    }
}
