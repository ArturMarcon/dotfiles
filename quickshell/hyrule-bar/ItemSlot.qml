import QtQuick

// An inventory slot from the game's menus: dark glass in a thin cream frame.
// `active` lights it Sheikah blue, like the selected slot.
Item {
    id: slot
    property bool active: false
    readonly property bool hovered: hover.hovered
    property real radius: 5
    default property alias content: inner.data

    implicitWidth: Theme.slotSize
    implicitHeight: Theme.slotSize

    // Halo around the selected slot
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: slot.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.sheikah
        opacity: slot.active ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal } }
    }

    Rectangle {
        anchors.fill: parent
        radius: slot.radius
        color: slot.active ? Theme.sheikahFill : (slot.hovered ? Theme.slotFillHover : Theme.slotFill)
        border.width: 1
        border.color: slot.active ? Theme.sheikah : (slot.hovered ? Theme.slotBorderHover : Theme.slotBorder)
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    HoverHandler {
        id: hover
    }
}
