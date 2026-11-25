import QtQuick
import QtQuick.Shapes

// Vector icon on a 24x24 grid, so the bar needs no icon font.
// `s` is stroked, `f` is filled.
Item {
    id: glyph
    property string name: ""
    property color color: Theme.textPrimary
    property real size: Theme.iconSize
    property real weight: 2

    implicitWidth: size
    implicitHeight: size

    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

    readonly property var icons: ({
        "slate":       { s: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0 M12 5.5l5 6.5-5 6.5-5-6.5z", f: "M10.4 12a1.6 1.6 0 1 0 3.2 0a1.6 1.6 0 1 0-3.2 0" },
        "sun":         { s: "M12 2.5v2 M12 19.5v2 M4.6 4.6l1.4 1.4 M18 18l1.4 1.4 M2.5 12h2 M19.5 12h2 M4.6 19.4l1.4-1.4 M18 6l1.4-1.4", f: "M7.5 12a4.5 4.5 0 1 0 9 0a4.5 4.5 0 1 0-9 0" },
        "moon":        { s: "", f: "M19.5 14.6A8 8 0 1 1 9.4 4.5a6.4 6.4 0 0 0 10.1 10.1z" },
        "speaker":     { s: "M15.5 9a4 4 0 0 1 0 6 M18.2 6.3a7.8 7.8 0 0 1 0 11.4", f: "M3.5 9.2h3.8L12 5v14l-4.7-4.2H3.5z" },
        "speaker-low": { s: "M15.5 9a4 4 0 0 1 0 6", f: "M3.5 9.2h3.8L12 5v14l-4.7-4.2H3.5z" },
        "speaker-off": { s: "M15.5 9.5l5 5 M20.5 9.5l-5 5", f: "M3.5 9.2h3.8L12 5v14l-4.7-4.2H3.5z" },
        "bolt":        { s: "", f: "M13.5 2L5 13.5h6L10 22l9-12.2h-6.2z" },
        "power":       { s: "M12 3v8.5 M7 5.8A8 8 0 1 0 17 5.8", f: "" },
        "lock":        { s: "M5.5 11h13v9.5h-13z M8.5 11V8a3.5 3.5 0 0 1 7 0v3", f: "" },
        "campfire":    { s: "M4 20.5l16-3.5 M20 20.5L4 17", f: "M12 3c1 3.5 5 5.2 5 9.2a5 5 0 0 1-10 0c0-2 1-3.3 2-4.2 0 1.6.8 2.6 1.8 2.8C10.6 8.5 11 5.5 12 3z" },
        "blood-moon":  { s: "M12 2.5v1.5 M12 20v1.5 M2.5 12h1.5 M20 12h1.5", f: "M6 12a6 6 0 1 0 12 0a6 6 0 1 0-12 0" },
        "terminal":    { s: "M3.5 5h17v14h-17z M7 9.5l3 2.5-3 2.5 M12.5 15h4.5", f: "" },
        "folder":      { s: "M3 7a1 1 0 0 1 1-1h5l2 2h9a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z", f: "" },
        "search":      { s: "M4 10.5a6.5 6.5 0 1 0 13 0a6.5 6.5 0 1 0-13 0 M15.5 15.5L20.5 20.5", f: "" },
        "camera":      { s: "M3.5 8h4l1.6-2.2h5.8L16.5 8h4v11.5h-17z M8.5 13.5a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0-7 0", f: "" },
        "chevron-left":  { s: "M15 5l-7 7 7 7", f: "" },
        "chevron-right": { s: "M9 5l7 7-7 7", f: "" },
        "diamond":     { s: "", f: "M12 3l7 9-7 9-7-9z" },
        "note":        { s: "M9 18V6.5l10-2.5v12", f: "M4 18a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0 M14 16a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0" },
        "prev":        { s: "M6.5 6v12", f: "M18.5 5.5v13L9 12z" },
        "next":        { s: "M17.5 6v12", f: "M5.5 5.5v13L15 12z" },
        "play":        { s: "", f: "M7.5 4.5v15L19.5 12z" },
        "pause":       { s: "", f: "M6.5 5h4v14h-4z M13.5 5h4v14h-4z" },
        "gpu":         { s: "M3 6.5h15.5v11H3z M18.5 9h2.5 M18.5 15h2.5 M6.5 17.5v3 M10.5 17.5v3 M14.5 17.5v3", f: "M7.5 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0" },
        "memory":      { s: "M3.5 7h17v9h-17z M6 16v3 M10 16v3 M14 16v3 M18 16v3", f: "M6.5 10h3v3h-3z M10.5 10h3v3h-3z M14.5 10h3v3h-3z" },
        "thermo":      { s: "M10 14.5V5.5a2 2 0 0 1 4 0v9", f: "M8.5 16.5a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0-7 0" }
    })
    readonly property var icon: icons[name] || { s: "", f: "" }

    Shape {
        width: 24
        height: 24
        scale: glyph.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: glyph.icon.f ? glyph.color : "transparent"
            strokeColor: "transparent"
            fillRule: ShapePath.WindingFill
            PathSvg { path: glyph.icon.f || "M0 0" }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: glyph.icon.s ? glyph.color : "transparent"
            strokeWidth: glyph.weight
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: glyph.icon.s || "M0 0" }
        }
    }
}
