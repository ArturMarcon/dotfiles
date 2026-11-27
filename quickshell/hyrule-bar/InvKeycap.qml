import QtQuick

// A button prompt's keycap, like the game's round (A) (B) badges.
Rectangle {
    id: cap
    property string key: ""
    property color ink: Theme.invInk
    property color face: Theme.invCream

    implicitHeight: 22
    implicitWidth: Math.max(implicitHeight, keyText.implicitWidth + 12)
    radius: implicitHeight / 2
    color: ink

    Text {
        id: keyText
        anchors.centerIn: parent
        text: cap.key
        font.family: Theme.fontUi
        font.pixelSize: 11
        font.bold: true
        color: cap.face
    }
}
