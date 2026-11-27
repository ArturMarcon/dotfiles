import QtQuick

// An inventory slot from the game's menus: dark glass in a thin cream frame.
// `active` lights it in `accent` (Sheikah blue by default), like the selected slot;
// `boost` adds light on top: about 0.7 for hover, more for a flash.
Item {
    id: slot
    property bool active: false
    property color accent: Theme.sheikah
    property color accentFill: Theme.sheikahFill
    property real boost: 0
    // Off when the owner animates `accent` itself, so the frame doesn't lag behind the halo
    property bool fadeColors: true
    // How strongly the lit frame shows; LitWheel dims it under its ring
    property real frameStrength: 1
    readonly property color frameColor: boost > 0.3 ? Qt.lighter(accent, 1.2) : accent
    readonly property bool hovered: hover.hovered
    property real radius: 5
    default property alias content: inner.data

    implicitWidth: Theme.slotSize
    implicitHeight: Theme.slotSize

    // Soft bloom, only when boosted
    Rectangle {
        anchors.fill: parent
        anchors.margins: -5 - slot.boost
        radius: slot.radius + 5 + slot.boost
        color: "transparent"
        border.width: 3
        border.color: slot.accent
        opacity: slot.active ? Math.min(0.3, 0.14 * slot.boost) : 0
    }

    // Halo around the selected slot
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3 - slot.boost
        radius: slot.radius + 3 + slot.boost
        color: "transparent"
        border.width: 2
        border.color: slot.accent
        opacity: slot.active ? Math.min(1, 0.4 + 0.4 * slot.boost) : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal } }
    }

    Rectangle {
        anchors.fill: parent
        radius: slot.radius
        color: slot.active ? Qt.tint(slot.accentFill, Qt.rgba(slot.accent.r, slot.accent.g, slot.accent.b, Math.min(0.4, 0.18 * slot.boost)))
            : (slot.hovered ? Theme.slotFillHover : Theme.slotFill)
        border.width: 1
        border.color: slot.active ? Qt.rgba(slot.frameColor.r, slot.frameColor.g, slot.frameColor.b, slot.frameStrength)
            : (slot.hovered ? Theme.slotBorderHover : Theme.slotBorder)
        Behavior on color { enabled: slot.fadeColors; ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { enabled: slot.fadeColors; ColorAnimation { duration: Theme.animDurationFast } }
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    HoverHandler {
        id: hover
    }
}
