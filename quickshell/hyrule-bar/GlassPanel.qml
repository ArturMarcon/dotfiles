import QtQuick

// Dark glass in a double cream frame, as on the game's pause menu.
// Shared by the bar's popups and the desktop widgets.
Item {
    id: glass
    property real radius: 12
    property color fill: Theme.menuFill
    default property alias content: inner.data

    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: glass.fill
        border.width: 1
        border.color: Theme.menuBorder

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: glass.radius - 3
            color: "transparent"
            border.width: 1
            border.color: Theme.menuInner
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
