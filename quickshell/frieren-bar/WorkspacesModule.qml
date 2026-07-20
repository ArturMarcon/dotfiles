import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Row {
    id: workspacesRoot
    spacing: 10
    height: Theme.pillHeight

    // Runic Spell Slots (Workspaces)
    Row {
        id: slotsRow
        spacing: 6
        height: Theme.pillHeight

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                id: wsSlot
                implicitWidth: width
                implicitHeight: height
                width: modelData.focused ? 48 : (wsArea.containsMouse ? 36 : 28)
                height: Theme.pillHeight
                radius: Theme.pillRadius
                
                color: modelData.focused ? Theme.bgWidgetActive : (wsArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget)
                border.width: 1
                border.color: modelData.focused ? Theme.zoltraakGold : (modelData.active ? Theme.arcaneViolet : (wsArea.containsMouse ? Theme.borderActive : Theme.borderSubtle))

                Behavior on width { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                // Inner golden/violet aura on active workspace
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: modelData.focused ? Theme.zoltraakGold : Theme.arcaneViolet
                    opacity: modelData.focused ? 0.45 : (modelData.active ? 0.2 : 0.0)
                    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: modelData.focused ? "✦" : (modelData.id > 0 ? modelData.id.toString() : "✧")
                        font.family: Theme.fontFamily
                        font.pixelSize: modelData.focused ? 13 : Theme.fontSizeSmall
                        font.bold: true
                        color: modelData.focused ? Theme.zoltraakGold : (modelData.active ? Theme.arcaneViolet : Theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }

                    Text {
                        text: modelData.id > 0 ? "I".repeat(modelData.id <= 5 ? modelData.id : 0) || modelData.id.toString() : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textPrimary
                        visible: modelData.focused && modelData.id <= 5
                        opacity: modelData.focused ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
                    }
                }

                MouseArea {
                    id: wsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Hyprland.dispatch("workspace " + modelData.id);
                    }
                }
            }
        }
    }

    // Divider
    Rectangle {
        width: 1
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.borderSubtle
    }

    // Active Quest / Grimoire Record (Window Title)
    Rectangle {
        id: titlePill
        width: Math.max(80, Math.min(320, titleRow.implicitWidth + 20))
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: titleArea.containsMouse ? Theme.bgWidgetHover : "transparent"
        border.width: 1
        border.color: titleArea.containsMouse ? Theme.borderSubtle : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        RowLayout {
            id: titleRow
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: "◈"
                font.pixelSize: 12
                color: Theme.arcaneViolet
            }

            Text {
                Layout.fillWidth: true
                text: (Hyprland.activeToplevel && Hyprland.activeToplevel.title) ? Hyprland.activeToplevel.title : "Journey across the Northern Plateau"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: titleArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
