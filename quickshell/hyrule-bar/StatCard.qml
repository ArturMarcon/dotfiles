import QtQuick

// One stat in the desktop system panel: label, big percentage, detail and a
// Sheikah-blue history chart that warms to amber and red under load.
Item {
    id: card
    property string icon: ""
    property string label: ""
    property real value: 0
    property var history: []
    property string detail: ""
    property string detailIcon: ""
    property string note: ""

    readonly property color tone: value >= 0.85 ? Theme.crimson : (value >= 0.6 ? Theme.amber : Theme.sheikah)

    // Inner slot, like an inventory cell
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.slotFill
        border.width: 1
        border.color: Theme.slotBorder
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 7

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: card.icon
            size: 16
            color: Theme.hudText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: card.label
            font.family: Theme.fontUi
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            font.letterSpacing: 2.5
            color: Theme.hudTextDim
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 4

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: card.detailIcon
            size: 14
            color: Theme.amber
            visible: card.detailIcon !== "" && card.detail !== ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: card.detail
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.hudText
        }
    }

    Text {
        id: percent
        anchors.left: parent.left
        anchors.leftMargin: 14
        y: 40
        text: Math.round(card.value * 100) + "%"
        font.family: Theme.fontDisplay
        font.pixelSize: 34
        font.bold: true
        color: card.value >= 0.6 ? card.tone : Theme.hudText
        Behavior on color { ColorAnimation { duration: Theme.animDurationSlow } }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.baseline: percent.baseline
        text: card.note
        font.family: Theme.fontUi
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.hudTextDim
    }

    Sparkline {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        height: 52
        values: card.history
        capacity: SystemStats.historyLength
        color: card.tone
    }
}
