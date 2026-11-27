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
    property bool fadeColor: true

    implicitWidth: size
    implicitHeight: size

    Behavior on color { enabled: glyph.fadeColor; ColorAnimation { duration: Theme.animDurationFast } }

    readonly property var icons: ({
        "slate":       { s: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0 M12 5.5l5 6.5-5 6.5-5-6.5z", f: "M10.4 12a1.6 1.6 0 1 0 3.2 0a1.6 1.6 0 1 0-3.2 0" },
        "sun":         { s: "M12 2.5v2 M12 19.5v2 M4.6 4.6l1.4 1.4 M18 18l1.4 1.4 M2.5 12h2 M19.5 12h2 M4.6 19.4l1.4-1.4 M18 6l1.4-1.4", f: "M7.5 12a4.5 4.5 0 1 0 9 0a4.5 4.5 0 1 0-9 0" },
        "moon":        { s: "", f: "M19.5 14.6A8 8 0 1 1 9.4 4.5a6.4 6.4 0 0 0 10.1 10.1z" },
        "speaker":     { s: "M15.5 9a4 4 0 0 1 0 6 M18.2 6.3a7.8 7.8 0 0 1 0 11.4", f: "M3.5 9.2h3.8L12 5v14l-4.7-4.2H3.5z" },
        "speaker-low": { s: "M15.5 9a4 4 0 0 1 0 6", f: "M3.5 9.2h3.8L12 5v14l-4.7-4.2H3.5z" },
        "speaker-off": { s: "M15.5 9.5l5 5 M20.5 9.5l-5 5", f: "M3.5 9.2h3.8L12 5v14l-4.7-4.2H3.5z" },
        // Output devices: a headband with a circlet gem, and a cabinet with a diamond tweeter
        "headset":     { s: "M4.6 14.5V12a7.4 7.4 0 0 1 14.8 0v2.5", f: "M3 13.2h3.6v7H5.2A2.2 2.2 0 0 1 3 18z M17.4 13.2H21V18a2.2 2.2 0 0 1-2.2 2.2h-1.4z M12 2.4l1.7 2.2-1.7 2.2-1.7-2.2z" },
        "stamina":     { s: "M9.5 3.5h5 M7.6 5.5h8.8a1.1 1.1 0 0 1 1.1 1.1v13.3a1.1 1.1 0 0 1-1.1 1.1H7.6a1.1 1.1 0 0 1-1.1-1.1V6.6a1.1 1.1 0 0 1 1.1-1.1z", f: "M12 9.2l2.5 3.5-2.5 3.5-2.5-3.5z" },
        "speakers":    { s: "M6.2 2.8h11.6a1.7 1.7 0 0 1 1.7 1.7v15a1.7 1.7 0 0 1-1.7 1.7H6.2a1.7 1.7 0 0 1-1.7-1.7v-15a1.7 1.7 0 0 1 1.7-1.7z M7.8 14.6a4.2 4.2 0 1 0 8.4 0a4.2 4.2 0 1 0-8.4 0", f: "M10.7 14.6a1.3 1.3 0 1 0 2.6 0a1.3 1.3 0 1 0-2.6 0 M12 5.2l1.5 1.9-1.5 1.9-1.5-1.9z" },
        "bolt":        { s: "", f: "M13.5 2L5 13.5h6L10 22l9-12.2h-6.2z" },
        "power":       { s: "M12 3.5v8.5 M7 6.3A8 8 0 1 0 17 6.3", f: "" },
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
        "thermo":      { s: "M10 14.5V5.5a2 2 0 0 1 4 0v9", f: "M8.5 16.5a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0-7 0" },
        // Inventory tabs: solid silhouettes, like the game's category icons
        "tab-home":      { s: "", f: "M12 2.8L2.5 11h2.8v9.8h5.2v-6h3v6h5.2V11h2.8z" },
        "tab-desktop":   { s: "M3.5 4.5h17v11h-17z", f: "M10.2 16h3.6l.8 3h2.4v1.8H7v-1.8h2.4z" },
        "tab-downloads": { s: "M4 14.5v5h16v-5", f: "M10.3 3h3.4v7.2h3.3L12 15.6 7 10.2h3.3z" },
        "tab-docs":      { s: "", f: "M6 2.5h8.6L19.5 7.4V20a1.5 1.5 0 0 1-1.5 1.5H6A1.5 1.5 0 0 1 4.5 20V4A1.5 1.5 0 0 1 6 2.5z M8 11v1.8h8V11z M8 15v1.8h8V15z" },
        "tab-pictures":  { s: "", f: "M3.5 7.5h3.8l1.6-2.5h6.2l1.6 2.5h3.8A1.5 1.5 0 0 1 22 9v10a1.5 1.5 0 0 1-1.5 1.5h-17A1.5 1.5 0 0 1 2 19V9a1.5 1.5 0 0 1 1.5-1.5z M12 10a3.7 3.7 0 1 0 0 7.4a3.7 3.7 0 1 0 0-7.4z" },
        "tab-videos":    { s: "", f: "M3 9.5h18v10a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 19.5z M2.9 7.4L19.3 3.3l.9 3.4L3.8 10.8z" },
        "tab-projects":  { s: "M8.5 6.5L3 12l5.5 5.5 M15.5 6.5L21 12l-5.5 5.5 M13.6 4l-3.2 16", f: "" },
        "tab-trash":     { s: "", f: "M5.3 7.5h13.4l-1.2 12.6a1.6 1.6 0 0 1-1.6 1.4H8.1a1.6 1.6 0 0 1-1.6-1.4z M3.5 4.5h17v2h-17z M9.5 2.5h5v2h-5z" },
        // Inventory actions
        "check":       { s: "M5 12.5l4.5 4.5L19 7.5", f: "" },
        "copy":        { s: "M8.5 8.5h11v11h-11z M5.5 15.5h-1v-11h11v1", f: "" },
        "cut":         { s: "M8 8l11 11.5 M16 8L5 19.5", f: "M3.5 5.5a3 3 0 1 0 6 0a3 3 0 1 0-6 0 M14.5 5.5a3 3 0 1 0 6 0a3 3 0 1 0-6 0" },
        "paste":       { s: "M8 4.5H6a1.5 1.5 0 0 0-1.5 1.5v13.5A1.5 1.5 0 0 0 6 21h12a1.5 1.5 0 0 0 1.5-1.5V6A1.5 1.5 0 0 0 18 4.5h-2 M8.5 3h7v3h-7z", f: "" },
        "pen":         { s: "M4 20l1-4.5L16 4.5l3.5 3.5L8.5 19z M14 6.5l3.5 3.5", f: "" },
        "folder-plus": { s: "M3 7a1 1 0 0 1 1-1h5l2 2h9a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z M12 10.5v6 M9 13.5h6", f: "" },
        "trash":       { s: "M4 6.5h16 M9.5 6.5V4h5v2.5 M6.5 6.5l1 14h9l1-14 M10 10v7 M14 10v7", f: "" },
        "restore":     { s: "M4.5 12a7.5 7.5 0 1 0 2.2-5.3 M4 3.5v4h4", f: "" },
        "link":        { s: "M10 14a4 4 0 0 0 5.7 0l3.3-3.3a4 4 0 0 0-5.7-5.7L12 6.3 M14 10a4 4 0 0 0-5.7 0L5 13.3a4 4 0 0 0 5.7 5.7l1.3-1.3", f: "" },
        "eye":         { s: "M2.5 12s3.5-6.5 9.5-6.5S21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z", f: "M9.5 12a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0-5 0" },
        "open":        { s: "M14 4h6v6 M20 4l-9 9 M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5", f: "" },
        "rupee":       { s: "", f: "M12 2l6 5v10l-6 5-6-5V7z" },
        "sort-az":     { s: "M3 18.5L7 5.5l4 13 M4.6 14h4.8 M14 6h6.5L14 18h6.5", f: "" },
        "clock":       { s: "M3.5 12a8.5 8.5 0 1 0 17 0a8.5 8.5 0 1 0-17 0 M12 7v5l3.5 2.2", f: "" },
        "tab-drive":   { s: "", f: "M4.5 6.5h15A1.5 1.5 0 0 1 21 8v8a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 16V8a1.5 1.5 0 0 1 1.5-1.5z M6 13.2v1.6h4v-1.6z M16.2 14a1.2 1.2 0 1 0 2.4 0a1.2 1.2 0 1 0-2.4 0" },
        "undo":        { s: "M8.5 6.5L4 11l4.5 4.5 M4.5 11H15a5 5 0 0 1 0 10h-3", f: "" },
        "box":         { s: "M3.5 8l8.5-4.5 8.5 4.5v8.5L12 21l-8.5-4.5z M3.5 8L12 12.5 20.5 8 M12 12.5V21", f: "" },
        "unbox":       { s: "M4 11v9h16v-9 M3 7.5h18V11H3z M12 3v7 M9.5 5.5L12 3l2.5 2.5", f: "" },
        "apps":        { s: "M4 4h6.5v6.5H4z M13.5 4H20v6.5h-6.5z M4 13.5h6.5V20H4z M13.5 13.5H20V20h-6.5z", f: "" },
        "file-plus":   { s: "M13.5 3H7a1.5 1.5 0 0 0-1.5 1.5v15A1.5 1.5 0 0 0 7 21h10a1.5 1.5 0 0 0 1.5-1.5V8z M13.5 3v5h5 M12 11.5v6 M9 14.5h6", f: "" },
        "select-all":  { s: "M4 4h16v16H4z M8 12l3 3 5-6", f: "" },
        "goto":        { s: "M3.5 12h13 M12 7l5 5-5 5 M20.5 4.5v15", f: "" },
        "eject":       { s: "", f: "M12 4.5l7.5 8.5h-15z M4.5 16h15v3h-15z" }
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
