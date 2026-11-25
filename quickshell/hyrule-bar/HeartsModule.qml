import QtQuick
import Quickshell

// CPU usage as ten heart containers. Every heart is 10% of headroom and
// load chips away at them a quarter (2.5%) at a time.
Item {
    id: heartsRoot
    implicitWidth: hearts.width + 4
    implicitHeight: Theme.slotSize
    width: implicitWidth
    height: implicitHeight

    readonly property int heartCount: 10
    readonly property real usage: SystemStats.cpu

    readonly property int quarters: Math.round((1 - usage) * heartCount * 4)
    readonly property int lastHeart: Math.ceil(quarters / 4) - 1
    readonly property bool lowHealth: quarters <= 8

    Row {
        id: hearts
        anchors.centerIn: parent
        spacing: 3
        opacity: hover.hovered ? 0.25 : 1.0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

        Repeater {
            model: heartsRoot.heartCount

            HeartContainer {
                width: 17
                height: 16
                fill: Math.max(0, Math.min(4, heartsRoot.quarters - index * 4)) / 4
                pulsing: heartsRoot.lowHealth && index === heartsRoot.lastHeart
            }
        }
    }

    // Exact reading on hover
    Text {
        anchors.centerIn: parent
        text: "CPU  " + Math.round(heartsRoot.usage * 100) + "%"
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.fontSizeMedium
        font.bold: true
        color: heartsRoot.lowHealth ? Theme.heartLight : Theme.hudText
        opacity: hover.hovered ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
    }

    HoverHandler {
        id: hover
    }
}
