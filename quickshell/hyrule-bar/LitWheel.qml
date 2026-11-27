import QtQuick
import QtQuick.Shapes

// A round meter like the game's wheels (stamina, sound), glowing in its own
// colour: dark disc, a ring that fills clockwise from the top with `value`
// (0..1, or -1 to keep it full) and the item in the middle. Brighter on
// hover, flaring when used.
Item {
    id: wheel
    property color accent: Theme.sheikah
    property string glyph: ""
    property real glyphSize: 11
    property string label: ""          // shown instead of the glyph on hover
    property real value: -1
    property bool flashing: false      // running low: the ring pulses
    property bool held: false          // keep the hover light, e.g. while a menu is open
    property real turn: 0              // turns the item over, for swap animations
    readonly property bool hovered: slot.hovered
    signal clicked(var mouse)

    implicitWidth: Theme.wheelSize
    implicitHeight: Theme.wheelSize
    width: implicitWidth
    height: implicitHeight

    property real hoverGlow: slot.hovered || held ? 1 : 0
    Behavior on hoverGlow { NumberAnimation { duration: Theme.animDurationFast } }

    property real flareLevel: 0
    function flare() { flareAnim.restart(); }

    SequentialAnimation {
        id: flareAnim
        NumberAnimation { target: wheel; property: "flareLevel"; to: 1.4; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: wheel; property: "flareLevel"; to: 0; duration: 600; easing.type: Easing.InQuad }
    }

    property real shownValue: value < 0 ? 1 : Math.max(0, Math.min(1, value))
    Behavior on shownValue { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }

    // A round inventory slot carries the disc, rim, halo and bloom
    ItemSlot {
        id: slot
        anchors.fill: parent
        radius: width / 2
        active: true
        fadeColors: false
        accent: wheel.accent
        accentFill: Qt.rgba(wheel.accent.r * 0.18, wheel.accent.g * 0.18, wheel.accent.b * 0.18, 0.85)
        boost: 0.7 * wheel.hoverGlow + wheel.flareLevel
        frameStrength: 0.35
    }

    Shape {
        id: ring
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        readonly property real r: wheel.width / 2 - 4

        SequentialAnimation on opacity {
            running: wheel.flashing
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 450 }
            NumberAnimation { to: 1.0; duration: 450 }
            onStopped: ring.opacity = 1.0
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.rgba(wheel.accent.r, wheel.accent.g, wheel.accent.b, 0.22)
            strokeWidth: 3
            PathAngleArc {
                centerX: wheel.width / 2; centerY: wheel.height / 2
                radiusX: ring.r; radiusY: ring.r
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.lighter(wheel.accent, 1 + 0.2 * wheel.hoverGlow)
            strokeWidth: 3
            capStyle: wheel.shownValue > 0.03 && wheel.shownValue < 0.999 ? ShapePath.RoundCap : ShapePath.FlatCap
            PathAngleArc {
                centerX: wheel.width / 2; centerY: wheel.height / 2
                radiusX: ring.r; radiusY: ring.r
                startAngle: -90
                sweepAngle: 360 * wheel.shownValue
            }
        }
    }

    Glyph {
        anchors.centerIn: parent
        name: wheel.glyph
        size: wheel.glyphSize
        fadeColor: false
        color: Qt.lighter(wheel.accent, 1 + 0.25 * wheel.hoverGlow)
        scale: 1 + 0.12 * wheel.hoverGlow
        opacity: wheel.label !== "" ? 1 - wheel.hoverGlow : 1

        transform: Rotation {
            origin.x: wheel.glyphSize / 2
            origin.y: wheel.glyphSize / 2
            axis { x: 0; y: 1; z: 0 }
            angle: wheel.turn
        }
    }

    Text {
        anchors.centerIn: parent
        text: wheel.label
        font.family: Theme.fontDisplay
        font.pixelSize: wheel.label.length > 2 ? 8 : 10
        font.bold: true
        color: Qt.lighter(wheel.accent, 1.3)
        opacity: wheel.hoverGlow
        visible: wheel.label !== ""
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => wheel.clicked(mouse)
    }
}
