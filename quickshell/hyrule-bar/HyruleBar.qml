import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell._Window
import Quickshell.Wayland._WlrLayerShell

// The top of the screen as the game's HUD: no bar, just cream elements
// floating over a soft shade, each with a gentle drop shadow.
WlrLayershell {
    id: barWindow
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"

    layer: WlrLayer.Top
    namespace: "hyrule-bar"

    property var modelData: null
    screen: modelData

    Item {
        id: barRoot
        anchors.fill: parent

        // Portrait / narrow screens drop the media text and shorten the clock rules
        readonly property bool compact: width < 1400

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.hudShade }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Left: Sheikah eye, heart containers (CPU), workspaces & window title
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            layer.enabled: true
            layer.effect: HudShadow {}

            SlateLauncher {
                id: launcher
                barWindow: barWindow
            }

            HeartsModule {
                id: hearts
            }

            WorkspacesModule {
                titleMaxWidth: Math.min(280, clock.x - 24 - leftSection.x
                                        - launcher.width - hearts.width - leftSection.spacing * 2
                                        - fixedWidth)
            }
        }

        // Center: time of day
        ClockModule {
            id: clock
            anchors.centerIn: parent
            barWindow: barWindow
            compact: barRoot.compact
            layer.enabled: true
            layer.effect: HudShadow {}
        }

        // Right: now playing, sound & stamina gauges, tray, rest
        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            layer.enabled: true
            layer.effect: HudShadow {}

            MediaModule {
                visible: hasMedia && !barRoot.compact
            }

            AudioModule {}

            StaminaModule {}

            TrayModule {}

            PowerModule {
                barWindow: barWindow
            }
        }
    }
}
