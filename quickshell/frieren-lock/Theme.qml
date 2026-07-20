pragma Singleton
import QtQuick

QtObject {

    readonly property color mainColor: "#c084fc"
    id: theme

    // =========================================================================
    // Simplified Frieren ("Arcane & Celestial Journey") Palette
    // =========================================================================
    // Bar Background
    readonly property color bgPanelTranslucent: "#d90f1626" // Obsidian Night Sky Bar

    // Buttons & Modules
    readonly property color bgWidget: "#161f36"         // Obsidian Runic Pill Resting
    readonly property color bgWidgetHover: "#202d4d"    // Celestial Blue Hover
    readonly property color bgWidgetActive: "#2a3b66"   // Deep Navy Active

    // Borders
    readonly property color borderSubtle: "#202d4d"     // Subtle Midnight Border
    readonly property color borderActive: "#38bdf8"     // Himmel Blue Active Border

    // Text
    readonly property color textPrimary: "#f8fafc"      // Celestial Silver-White Text
    readonly property color textSecondary: "#94a3b8"    // Starlight Slate Gray Text
    readonly property color textMuted: "#64748b"        // Muted Grimoire Ink Text

    // Primary Frieren Accents
    readonly property color zoltraakGold: mainColor     // Zoltraak Golden Aura / Highlights
    readonly property color arcaneViolet: mainColor       // Fern's Purple Robes / Active Magic
    readonly property color himmelBlue: "#38bdf8"       // Himmel the Hero's Sky Blue
    readonly property color starkRed: mainColor        // Stark's Crimson / Alerts & Mute
    readonly property color emeraldGreen: mainColor    // Healing Magic / Charging Battery

    // Typography & Sizing
    readonly property string fontFamily: "JetBrainsMono Nerd Font, Symbols Nerd Font, FiraCode Nerd Font, Noto Sans Symbols 2, Outfit, Inter, sans-serif"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeMedium: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 16

    // Dimensions
    readonly property int barHeight: 34
    readonly property int pillHeight: 24
    readonly property int pillRadius: 6
    readonly property int iconSize: 14

    // Animation Durations
    readonly property int animDurationFast: 150
    readonly property int animDurationNormal: 250
    readonly property int animDurationSlow: 450
}
