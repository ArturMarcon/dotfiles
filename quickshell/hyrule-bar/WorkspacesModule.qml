import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspaces as inventory slots, the focused one selected in Sheikah blue,
// followed by the active window's title.
Row {
    id: workspacesRoot
    spacing: 12
    height: Theme.slotSize

    // Set by the bar so the title never runs into the clock
    property real titleMaxWidth: 260
    readonly property bool showTitle: titleMaxWidth >= 60
    readonly property real fixedWidth: slotsRow.width + spacing

    Row {
        id: slotsRow
        spacing: 7
        height: Theme.slotSize

        Repeater {
            model: Hyprland.workspaces

            delegate: ItemSlot {
                id: slot
                active: modelData.focused

                Text {
                    anchors.centerIn: parent
                    text: modelData.id > 0 ? modelData.id.toString() : "✧"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    color: slot.active ? "#ffffff" : (modelData.active || slot.hovered ? Theme.hudText : Theme.hudTextDim)
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                }

                // Shown on another monitor: a small dot under the slot
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 2
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.hudText
                    visible: modelData.active && !modelData.focused
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
                }
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: workspacesRoot.showTitle
        width: Math.min(workspacesRoot.titleMaxWidth, implicitWidth)
        text: (Hyprland.activeToplevel && Hyprland.activeToplevel.title) ? Hyprland.activeToplevel.title : "Wandering the wilds"
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.fontSizeMedium
        font.italic: true
        color: Theme.hudTextDim
        elide: Text.ElideRight
    }
}
