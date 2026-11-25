pragma Singleton
import QtQuick

QtObject {
    id: theme

    // =========================================================================
    // Hyrule Forest Palette — sampled from the overgrown-shrine painting:
    // deep teal shade, moss & sunlit lime canopy, amber light, heart-red bloom
    // =========================================================================
    readonly property color abyss: "#091d1a"        // Deepest Forest Shadow
    readonly property color deepTeal: "#0c2a27"     // Shaded Undergrowth
    readonly property color canopy: "#0e372e"       // Dark Canopy
    readonly property color forest: "#114632"       // Forest Green
    readonly property color pine: "#29543d"         // Pine Needles
    readonly property color moss: "#35694c"         // Shrine Moss
    readonly property color fern: "#669b62"         // Fern
    readonly property color leaf: "#9aca68"         // Leaf in Light
    readonly property color sunlit: "#c8df7c"       // Sunlit Lime (primary accent)
    readonly property color sunbeam: "#eef3c4"      // Light through the Arch
    readonly property color shrineTeal: "#7cc8b4"   // Tunic & Stream Glint
    readonly property color amber: "#e6ad5c"        // Warm Daylight
    readonly property color crimson: "#e0404f"      // Heart Red / Alerts

    // Bar Background (darker at the edges, light filtering in at the center)
    readonly property color barEdge: "#f0091d1a"
    readonly property color barCenter: "#f0113a30"

    // Panels (chamfered HUD plates)
    readonly property color panelFill: "#8c0e372e"
    readonly property color panelHover: "#cc1e4a38"
    readonly property color panelActive: "#e629543d"
    readonly property color panelStroke: "#8035694c"
    readonly property color popupFill: "#f70a2420"
    readonly property color popupStroke: "#a69aca68"

    // Text
    readonly property color textPrimary: "#eef3d6"
    readonly property color textSecondary: "#a9c08a"
    readonly property color textMuted: "#5f7d55"

    // Heart Containers & Stamina Wheel
    readonly property color heartRed: "#e0404f"
    readonly property color heartLight: "#ff8a86"
    readonly property color heartRim: "#f5e6c8"
    readonly property color heartEmpty: "#a6051411"
    readonly property color heartEmptyRim: "#80c8df7c"
    readonly property color stamina: "#b4dc5a"
    readonly property color staminaTrack: "#33b4dc5a"

    // Typography & Sizing
    readonly property string fontDisplay: "Noto Serif"
    readonly property string fontUi: "Noto Sans"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeMedium: 13
    readonly property int fontSizeLarge: 15

    readonly property int barHeight: 36
    readonly property int pillHeight: 26
    readonly property int cut: 5
    readonly property int iconSize: 15

    // Animation Durations
    readonly property int animDurationFast: 150
    readonly property int animDurationNormal: 250
    readonly property int animDurationSlow: 450
}
