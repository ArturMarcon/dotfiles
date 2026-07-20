import QtQuick
import QtQuick.Layouts
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
    namespace: "frieren-bar"

    property var modelData: null
    screen: modelData

    Rectangle {
        id: barRoot
        anchors.fill: parent
        color: Theme.bgPanelTranslucent

        // Bottom Arcane Gradient Border
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.zoltraakGold }
                GradientStop { position: 0.5; color: Theme.arcaneViolet }
                GradientStop { position: 1.0; color: Theme.himmelBlue }
            }
            opacity: 0.75
        }

        // Inner subtle border on top
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.borderSubtle
            opacity: 0.4
        }

        // Left Section: Grimoire & Workspaces & Active Window Title
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            GrimoireLauncher {
                barWindow: barWindow
            }

            WorkspacesModule {}
        }

        // Center Section: Celestial Clock & Bard's MPRIS Media Player
        Row {
            id: centerSection
            anchors.centerIn: parent
            spacing: 12

            MediaModule {}

            ClockModule {
                barWindow: barWindow
            }
        }

        // Right Section: Audio Voice of Mana, UPower Battery, System Tray Relics, Power Rest
        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            AudioModule {}

            BatteryModule {}

            TrayModule {}

            PowerModule {
                barWindow: barWindow
            }
        }
    }
}
