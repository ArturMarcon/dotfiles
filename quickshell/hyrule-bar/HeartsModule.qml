import QtQuick
import Quickshell
import Quickshell.Io

// CPU usage as ten heart containers. Every heart is 10% of headroom and
// load chips away at them a quarter (2.5%) at a time.
Item {
    id: heartsRoot
    implicitWidth: hearts.width + 8
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

    readonly property int heartCount: 10
    property real usage: 0.0
    property var lastSample: null

    readonly property int quarters: Math.round((1 - usage) * heartCount * 4)
    readonly property int lastHeart: Math.ceil(quarters / 4) - 1
    readonly property bool lowHealth: quarters <= 8

    FileView {
        id: procStat
        path: "/proc/stat"
        blockLoading: true
    }

    function sample() {
        procStat.reload();
        var m = procStat.text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (!m) return;
        var v = m.slice(1).map(Number);
        var idle = v[3] + v[4];
        var total = v.reduce(function (a, b) { return a + b; }, 0);
        if (lastSample && total > lastSample.total) {
            var busy = 1 - (idle - lastSample.idle) / (total - lastSample.total);
            usage = Math.max(0, Math.min(1, busy));
        }
        lastSample = { idle: idle, total: total };
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: heartsRoot.sample()
    }

    Row {
        id: hearts
        anchors.centerIn: parent
        spacing: 3
        opacity: hover.hovered ? 0.25 : 1.0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }

        Repeater {
            model: heartsRoot.heartCount

            HeartContainer {
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
        color: heartsRoot.lowHealth ? Theme.heartLight : Theme.sunbeam
        opacity: hover.hovered ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
    }

    HoverHandler {
        id: hover
    }
}
