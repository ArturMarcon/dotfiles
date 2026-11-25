import QtQuick
import QtQuick.Layouts

// One row in a popup menu (launcher & power).
HudPanel {
    id: entry
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property color accent: Theme.sunlit
    signal activated()

    Layout.fillWidth: true
    implicitHeight: 44
    cut: 6
    fillColor: area.containsMouse ? Theme.panelHover : Theme.panelFill
    strokeColor: area.containsMouse ? entry.accent : Theme.panelStroke

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Glyph {
            name: entry.icon
            size: 17
            color: entry.accent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: entry.title
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: Theme.textPrimary
            }

            Text {
                text: entry.subtitle
                font.family: Theme.fontUi
                font.pixelSize: 10
                color: Theme.textSecondary
            }
        }

        Glyph {
            name: "chevron-right"
            size: 12
            color: area.containsMouse ? entry.accent : Theme.textMuted
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: entry.activated()
    }
}
