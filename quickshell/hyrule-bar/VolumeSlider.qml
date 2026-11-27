import QtQuick

// A slider from the game's options menu: thin cream track with notches every
// 10%, a glowing Sheikah-blue fill and a diamond knob. Drag, click or scroll.
Item {
    id: slider
    property real value: 0
    property bool muted: false
    signal moved(real value)

    implicitWidth: 160
    implicitHeight: 22

    readonly property real inset: 7
    readonly property real span: width - inset * 2
    readonly property real knobX: inset + Math.max(0, Math.min(1, value)) * span
    readonly property color fillColor: muted ? Theme.hudTextDim : Theme.sheikah

    function setFrom(x) {
        moved(Math.round(Math.max(0, Math.min(1, (x - inset) / span)) * 100) / 100);
    }

    Rectangle {
        x: slider.inset
        width: slider.span
        height: 2
        radius: 1
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.gaugeTrack
    }

    Repeater {
        model: 11

        Rectangle {
            x: slider.inset + index * slider.span / 10 - width / 2
            width: 1
            height: index % 5 === 0 ? 8 : 4
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.hudTextDim
            opacity: 0.55
        }
    }

    // Fill and its glow
    Rectangle {
        x: slider.inset
        width: slider.knobX - slider.inset
        height: 6
        radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: slider.fillColor
        opacity: 0.22
    }

    Rectangle {
        x: slider.inset
        width: slider.knobX - slider.inset
        height: 2
        radius: 1
        anchors.verticalCenter: parent.verticalCenter
        color: slider.fillColor
    }

    Rectangle {
        width: 11
        height: 11
        rotation: 45
        x: slider.knobX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: area.pressed ? slider.fillColor : Theme.sheikahFill
        border.width: 1.5
        border.color: slider.fillColor
        scale: area.containsMouse || area.pressed ? 1.2 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animDurationFast } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => slider.setFrom(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) slider.setFrom(mouse.x); }
    }

    WheelHandler {
        onWheel: (wheel) => {
            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            slider.moved(Math.round(Math.max(0, Math.min(1, slider.value + step)) * 100) / 100);
        }
    }
}
