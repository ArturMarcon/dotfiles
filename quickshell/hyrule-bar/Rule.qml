import QtQuick

// A thin line fading away from a small diamond, as on the game's area titles.
Item {
    id: rule
    property bool fadeLeft: false   // true: fades toward the left, diamond on the right
    property color color: Theme.hudText
    readonly property color clear: Qt.rgba(color.r, color.g, color.b, 0)

    implicitWidth: 60
    implicitHeight: 7

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: rule.fadeLeft ? 0 : 7
        width: Math.max(0, parent.width - 7)
        height: 1
        opacity: 0.75
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: rule.fadeLeft ? rule.clear : rule.color }
            GradientStop { position: 1.0; color: rule.fadeLeft ? rule.color : rule.clear }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: rule.fadeLeft ? parent.width - 6 : 1
        width: 5
        height: 5
        rotation: 45
        color: "transparent"
        border.width: 1
        border.color: rule.color
    }
}
