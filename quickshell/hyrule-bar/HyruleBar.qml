import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell._Window
import Quickshell.Wayland._WlrLayerShell

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

        // Portrait / narrow screens drop the media plate to make room
        readonly property bool compact: width < 1400

        // Canopy shade: deep at the edges, light filtering through the middle
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.barEdge }
                GradientStop { position: 0.5; color: Theme.barCenter }
                GradientStop { position: 1.0; color: Theme.barEdge }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#33000000" }
            }
        }

        // Sunlit seam along the bottom edge
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.moss }
                GradientStop { position: 0.3; color: Theme.fern }
                GradientStop { position: 0.5; color: Theme.sunlit }
                GradientStop { position: 0.7; color: Theme.fern }
                GradientStop { position: 1.0; color: Theme.moss }
            }
            opacity: 0.8
        }

        // Left Section: Slate, Heart Containers (CPU), Workspaces & Window Title
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            SlateLauncher {
                id: launcher
                barWindow: barWindow
            }

            HeartsModule {
                id: hearts
            }

            WorkspacesModule {
                titleMaxWidth: Math.min(260, centerSection.x - 20 - leftSection.x
                                        - launcher.width - hearts.width - leftSection.spacing * 2
                                        - fixedWidth)
            }
        }

        // Center Section: Time of Day & Media
        Row {
            id: centerSection
            anchors.centerIn: parent
            spacing: 10

            MediaModule {
                visible: hasMedia && !barRoot.compact
            }

            ClockModule {
                barWindow: barWindow
            }
        }

        // Right Section: Audio, Stamina (Battery), Tray, Rest (Power)
        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            AudioModule {}

            StaminaModule {}

            TrayModule {}

            PowerModule {
                barWindow: barWindow
            }
        }
    }
}
