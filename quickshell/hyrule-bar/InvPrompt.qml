import QtQuick

// A button prompt in the inventory's bottom strip: keycap, then what it does.
Item {
    id: prompt
    property string key: ""
    property string label: ""
    signal clicked()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    opacity: area.containsMouse ? 0.75 : 1

    Row {
        id: row
        spacing: 7

        InvKeycap {
            anchors.verticalCenter: parent.verticalCenter
            key: prompt.key
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: prompt.label
            font.family: Theme.fontDisplay
            font.pixelSize: 13
            font.bold: true
            color: Theme.invInk
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: prompt.clicked()
    }
}
