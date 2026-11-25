import QtQuick
import QtQuick.Layouts

// Popup body in the style of the game's pause menu: dark glass in a double
// cream frame, with the title set like an area name between fading rules.
Item {
    id: frame
    property string title: ""
    property string subtitle: ""
    default property alias content: column.data

    implicitWidth: 260
    implicitHeight: column.implicitHeight + 36

    GlassPanel {
        anchors.fill: parent
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            visible: frame.title !== ""
            spacing: 10

            Rule {
                Layout.fillWidth: true
                fadeLeft: true
            }

            Text {
                text: frame.title
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeLarge + 1
                font.bold: true
                font.letterSpacing: 1.5
                color: Theme.hudText
            }

            Rule {
                Layout.fillWidth: true
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 6
            visible: frame.subtitle !== ""
            text: frame.subtitle
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fontSizeSmall
            font.italic: true
            color: Theme.hudTextDim
        }
    }
}
