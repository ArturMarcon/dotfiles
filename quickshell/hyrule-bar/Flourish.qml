import QtQuick

// Divider line fading out from a small center diamond.
Item {
    id: flourish
    property color color: Theme.leaf
    implicitHeight: 9

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: flourish.color }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.6
    }

    Rectangle {
        anchors.centerIn: parent
        width: 6
        height: 6
        rotation: 45
        color: Theme.abyss
        border.width: 1
        border.color: flourish.color
    }
}
