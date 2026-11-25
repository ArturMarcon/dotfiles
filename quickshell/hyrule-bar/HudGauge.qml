import QtQuick
import QtQuick.Shapes

// A round meter like the game's corner gauges: dark glass disc, thin cream rim,
// an arc for the value and a glyph in the middle that turns into the number on hover.
Item {
    id: gauge
    property real value: 0
    property color arcColor: Theme.hudText
    property color trackColor: Theme.gaugeTrack
    property string glyph: ""
    property color glyphColor: Theme.hudText
    property string label: ""
    property bool flashing: false
    readonly property bool hovered: hover.hovered

    implicitWidth: 26
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: gauge.hovered ? Theme.slotFillHover : Theme.slotFill
        border.width: 1
        border.color: gauge.hovered ? Theme.slotBorderHover : Theme.slotBorder
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
    }

    Shape {
        id: arcs
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Running low: the arc flashes, like an emptying stamina wheel
        SequentialAnimation on opacity {
            running: gauge.flashing
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 450 }
            NumberAnimation { to: 1.0; duration: 450 }
            onStopped: arcs.opacity = 1.0
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: gauge.trackColor
            strokeWidth: 3
            PathAngleArc {
                centerX: gauge.width / 2; centerY: gauge.height / 2
                radiusX: gauge.width / 2 - 4; radiusY: gauge.height / 2 - 4
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: gauge.arcColor
            strokeWidth: 3
            capStyle: gauge.value > 0.03 ? ShapePath.RoundCap : ShapePath.FlatCap
            PathAngleArc {
                centerX: gauge.width / 2; centerY: gauge.height / 2
                radiusX: gauge.width / 2 - 4; radiusY: gauge.height / 2 - 4
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, gauge.value))
                Behavior on sweepAngle { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }
            }
        }
    }

    Glyph {
        anchors.centerIn: parent
        name: gauge.glyph
        size: 11
        color: gauge.glyphColor
        opacity: gauge.hovered && gauge.label !== "" ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
    }

    Text {
        anchors.centerIn: parent
        text: gauge.label
        font.family: Theme.fontDisplay
        font.pixelSize: gauge.label.length > 2 ? 8 : 10
        font.bold: true
        color: Theme.hudText
        opacity: gauge.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
    }

    HoverHandler {
        id: hover
    }
}
