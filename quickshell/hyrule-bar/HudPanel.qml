import QtQuick
import QtQuick.Shapes

// Chamfered-corner plate used for every module, like an ancient-tech HUD panel.
// Children declared inside a HudPanel are drawn on top of the plate.
Item {
    id: panel
    property color fillColor: Theme.panelFill
    property color strokeColor: Theme.panelStroke
    property real strokeWidth: 1
    property real cut: Theme.cut

    Behavior on fillColor { ColorAnimation { duration: Theme.animDurationFast } }
    Behavior on strokeColor { ColorAnimation { duration: Theme.animDurationFast } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: plate
            readonly property real o: panel.strokeWidth / 2
            readonly property real r: panel.width - o
            readonly property real b: panel.height - o
            readonly property real c: panel.cut

            fillColor: panel.fillColor
            strokeColor: panel.strokeColor
            strokeWidth: panel.strokeWidth
            joinStyle: ShapePath.MiterJoin

            startX: plate.o + plate.c; startY: plate.o
            PathLine { x: plate.r - plate.c; y: plate.o }
            PathLine { x: plate.r; y: plate.o + plate.c }
            PathLine { x: plate.r; y: plate.b - plate.c }
            PathLine { x: plate.r - plate.c; y: plate.b }
            PathLine { x: plate.o + plate.c; y: plate.b }
            PathLine { x: plate.o; y: plate.b - plate.c }
            PathLine { x: plate.o; y: plate.o + plate.c }
            PathLine { x: plate.o + plate.c; y: plate.o }
        }
    }
}
