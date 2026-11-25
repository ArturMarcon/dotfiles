import QtQuick
import QtQuick.Shapes

// The Sheikah eye, on the same traced grid as the cursor theme
// (~/.config/hyrule-cursor/build.py). The artwork spans x 56..242, y 42..220.
Item {
    id: eye
    property color color: Theme.hudText
    property real size: 20

    implicitWidth: size * 186 / 178
    implicitHeight: size

    Shape {
        x: -56 * eye.size / 178
        y: -42 * eye.size / 178
        width: 300
        height: 300
        scale: eye.size / 178
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        // Inner ring, and the outer ring open on the right ending in a hook
        ShapePath {
            fillColor: "transparent"
            strokeColor: eye.color
            strokeWidth: 13
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M177 130 A27 27 0 1 1 123 130 A27 27 0 1 1 177 130 M188.5 157 A47 47 0 1 1 169.9 87.4 C182 82 193 77 202 80 C209 82 212 87 211 93" }
        }

        // Teardrop stem and the curl at the bottom left
        ShapePath {
            fillColor: "transparent"
            strokeColor: eye.color
            strokeWidth: 10
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M121 101 Q98 82 78 63 M107 158 C102 174 104 186 115 191" }
        }

        // Teardrop, crescent and the three arrowheads
        ShapePath {
            fillColor: eye.color
            strokeColor: "transparent"
            PathSvg { path: "M81.49 64.64 A15 11.5 40 1 1 58.51 45.36 A15 11.5 40 1 1 81.49 64.64 Z M183 87 C202 97 205 128 186 143 C194 124 193 104 183 87 Z M212 101 L242 128 L210 144 Z M204 155 L219 197 L172 186 Z M123 192 L164 192 L150 220 Z" }
        }
    }
}
