import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// Tray apps in inventory slots.
Row {
    id: trayRoot
    spacing: 6
    visible: SystemTray.items && SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        delegate: ItemSlot {
            IconImage {
                anchors.centerIn: parent
                source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                implicitSize: Theme.iconSize
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton)
                        modelData.secondaryActivate();
                    else
                        modelData.activate();
                }
            }

            WheelHandler {
                onWheel: (wheel) => modelData.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false)
            }
        }
    }
}
