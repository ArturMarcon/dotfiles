import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
    id: trayRoot
    property bool hasItems: SystemTray.items && SystemTray.items.values.length > 0
    
    visible: hasItems
    implicitWidth: width
    implicitHeight: height
    width: hasItems ? trayPill.width : 0
    height: Theme.pillHeight

    Behavior on width { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }

    Rectangle {
        id: trayPill
        implicitWidth: width
        implicitHeight: height
        width: trayRow.implicitWidth + 20
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: Theme.bgWidget
        border.width: 1
        border.color: Theme.borderSubtle

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: SystemTray.items

                delegate: Rectangle {
                    id: itemBox
                    implicitWidth: width
                    implicitHeight: height
                    width: Theme.pillHeight - 4
                    height: Theme.pillHeight - 4
                    radius: Theme.pillRadius - 2
                    color: itemArea.containsMouse ? Theme.bgWidgetHover : "transparent"
                    border.width: 1
                    border.color: itemArea.containsMouse ? Theme.borderActive : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

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
