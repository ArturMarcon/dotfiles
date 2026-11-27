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

    // Bar: the game's HUD floats over the scene, so only a soft shade from the top edge
    readonly property color hudShade: "#a6050e0c"
    readonly property color hudShadow: "#e6020807"
    readonly property color hudText: "#f6f2e4"
    readonly property color hudTextDim: "#c5c8b2"

    // Inventory slots: dark glass with a thin cream frame
    readonly property color slotFill: "#99050e0c"
    readonly property color slotFillHover: "#cc12261f"
    readonly property color slotBorder: "#66eef3d6"
    readonly property color slotBorderHover: "#d9eef3d6"
    readonly property color gaugeTrack: "#33eef3d6"

    // Sheikah tech: blue when awake or selected (matches the cursor's clickable state)
    readonly property color sheikah: "#4fd2ff"
    readonly property color sheikahFill: "#d90a2733"
    readonly property color ember: "#ff9a3d"          // Fire rod / Goron forge glow
    readonly property color sound: "#b38cff"          // The game's sound meter

    // Pause-menu popups
    readonly property color menuFill: "#eb050e0c"
    readonly property color menuBorder: "#4deef3d6"
    readonly property color menuInner: "#1feef3d6"

    // Panels (chamfered HUD plates)
    readonly property color panelFill: "#8c0e372e"
    readonly property color panelHover: "#cc1e4a38"
    readonly property color panelActive: "#e629543d"
    readonly property color panelStroke: "#8035694c"
    readonly property color popupFill: "#f70a2420"
    readonly property color popupStroke: "#a69aca68"

    // Inventory (file manager), after the game's inventory screen: cream strips,
    // dark glass slots, the gold frame on the selected item
    readonly property color invCream: "#f3efe0"
    readonly property color invCreamShade: "#d9d2b8"
    readonly property color invInk: "#1d1c18"
    readonly property color invInkSoft: "#4a473c"
    readonly property color invTabFaded: "#c9c2a8"
    readonly property color invBackdrop: "#8c060b09"
    readonly property color invPanel: "#a6141713"
    readonly property color invSlot: "#d90c0d0b"
    readonly property color invSlotEmpty: "#73121411"
    readonly property color invSlotBorder: "#33f3efe0"
    readonly property color invSlotBorderEmpty: "#1cf3efe0"
    readonly property color invGold: "#f6d36b"
    readonly property color invRupee: "#3cc46e"

    // Desktop widgets: the menus' glass, quiet over the wallpaper, full strength on hover
    readonly property color widgetFill: "#cc050e0c"
    readonly property real widgetRestOpacity: 0.55

    // Text
    readonly property color textPrimary: "#eef3d6"
    readonly property color textSecondary: "#a9c08a"
    readonly property color textMuted: "#5f7d55"

    // Heart Containers & Stamina Wheel
    readonly property color heartRed: "#e0404f"
    readonly property color heartLight: "#ff8a86"
    readonly property color heartRim: "#f5e6c8"
    readonly property color heartEmpty: "#99050e0c"
    readonly property color heartEmptyRim: "#b3eef3d6"
    readonly property color stamina: "#b4dc5a"
    readonly property color staminaTrack: "#33b4dc5a"

    // Typography & Sizing
    readonly property string fontDisplay: "Noto Serif"
    readonly property string fontUi: "Noto Sans"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeMedium: 13
    readonly property int fontSizeLarge: 15

    readonly property int barHeight: 36
    // Hyprland's outer gap (general.gaps_out in hypr/style-layout.lua): windows start
    // this far below the bar, so the HUD centres itself in the bar plus this strip
    readonly property int windowGap: 5
    readonly property int pillHeight: 26
    readonly property int slotSize: 24
    readonly property int wheelSize: 26
    readonly property int cut: 5
    readonly property int iconSize: 15

    // Animation Durations
    readonly property int animDurationFast: 150
    readonly property int animDurationNormal: 250
    readonly property int animDurationSlow: 450
}
