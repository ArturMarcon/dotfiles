import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell._Window
import Quickshell.Wayland._WlrLayerShell

// Calendar and system panels pinned to the desktop, above the wallpaper and
// below every window. shell.qml picks the screen.
WlrLayershell {
    id: desktop
    anchors {
        top: true
        left: true
    }
    margins {
        top: 18
        left: 18
    }
    // Zone 0 keeps the panels clear of the bar's reserved strip
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: column.width
    implicitHeight: column.height
    color: "transparent"

    layer: WlrLayer.Bottom
    namespace: "hyrule-desktop"
    keyboardFocus: WlrKeyboardFocus.None

    property var modelData: null
    screen: modelData

    Column {
        id: column
        spacing: 14

        // Faded so it doesn't pull focus from the wallpaper; brightens under the cursor
        property bool ready: false
        opacity: !ready ? 0 : (hover.hovered ? 1 : Theme.widgetRestOpacity)

        Component.onCompleted: ready = true
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        HoverHandler {
            id: hover
        }

        CalendarWidget {
            width: 580
            height: implicitHeight
        }

        SystemWidget {
            width: 580
            height: implicitHeight
        }
    }
}
