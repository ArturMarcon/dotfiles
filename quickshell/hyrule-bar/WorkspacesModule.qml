import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: workspacesRoot
    spacing: 10
    height: Theme.pillHeight

    // Set by the bar so the title never runs into the center section
    property real titleMaxWidth: 260
    readonly property bool showTitle: titleMaxWidth >= 60
    readonly property real fixedWidth: slotsRow.width + divider.width + spacing * 2

    // Shrine Markers (Workspaces)
    Row {
        id: slotsRow
        spacing: 5
        height: Theme.pillHeight

        Repeater {
            model: Hyprland.workspaces

            delegate: HudPanel {
                id: wsSlot
                width: modelData.focused ? 44 : (wsArea.containsMouse ? 32 : 26)
                height: Theme.pillHeight
                cut: 4
                fillColor: modelData.focused ? Theme.panelActive : (wsArea.containsMouse ? Theme.panelHover : Theme.panelFill)
                strokeColor: modelData.focused ? Theme.sunlit : (modelData.active ? Theme.shrineTeal : (wsArea.containsMouse ? Theme.leaf : Theme.panelStroke))

                Behavior on width { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "diamond"
                        size: 9
                        color: Theme.sunlit
                        visible: modelData.focused
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.id > 0 ? modelData.id.toString() : "✧"
                        font.family: Theme.fontDisplay
                        font.pixelSize: modelData.focused ? Theme.fontSizeMedium : Theme.fontSizeSmall
                        font.bold: true
                        color: modelData.focused ? Theme.sunbeam : (modelData.active ? Theme.shrineTeal : Theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
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
    Glyph {
        id: divider
        anchors.verticalCenter: parent.verticalCenter
        visible: workspacesRoot.showTitle
        name: "diamond"
        size: 7
        color: Theme.moss
    }

    // Current Quest (Window Title)
    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: workspacesRoot.showTitle
        width: Math.min(workspacesRoot.titleMaxWidth, implicitWidth)
        text: (Hyprland.activeToplevel && Hyprland.activeToplevel.title) ? Hyprland.activeToplevel.title : "Wandering the wilds"
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.fontSizeMedium
        font.italic: true
        color: Theme.textSecondary
        elide: Text.ElideRight
    }
}
