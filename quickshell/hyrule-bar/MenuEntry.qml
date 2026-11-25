import QtQuick
import QtQuick.Layouts

// One row in a popup menu (launcher & power). Hovering highlights it the way
// the game marks the selected menu option: a glowing band with a blue pointer.
Item {
    id: entry
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property color accent: Theme.hudText
    signal activated()

    readonly property bool selected: area.containsMouse
    readonly property color cream: Theme.hudText

    Layout.fillWidth: true
    implicitHeight: 42

    // Selection band
    Item {
        anchors.fill: parent
        opacity: entry.selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(entry.cream.r, entry.cream.g, entry.cream.b, 0.02) }
                GradientStop { position: 0.3; color: Qt.rgba(entry.cream.r, entry.cream.g, entry.cream.b, 0.14) }
                GradientStop { position: 1.0; color: Qt.rgba(entry.cream.r, entry.cream.g, entry.cream.b, 0.0) }
            }
        }

        Repeater {
            model: [0, 1]

            Rectangle {
                y: modelData === 0 ? 0 : entry.height - 1
                width: entry.width
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(entry.cream.r, entry.cream.g, entry.cream.b, 0.0) }
                    GradientStop { position: 0.35; color: Qt.rgba(entry.cream.r, entry.cream.g, entry.cream.b, 0.55) }
                    GradientStop { position: 1.0; color: Qt.rgba(entry.cream.r, entry.cream.g, entry.cream.b, 0.0) }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 10
        spacing: 10

        Glyph {
            name: "play"
            size: 9
            color: Theme.sheikah
            opacity: entry.selected ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
        }

        Glyph {
            name: entry.icon
            size: 17
            color: entry.selected ? entry.accent : Theme.hudTextDim
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: entry.title
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: Theme.hudText
            }

            Text {
                Layout.fillWidth: true
                text: entry.subtitle
                font.family: Theme.fontUi
                font.pixelSize: 10
                color: Theme.hudTextDim
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: entry.activated()
    }
}
