import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell._Window
import Quickshell.Hyprland

Item {
    id: launcherRoot
    implicitWidth: panel.width
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

    property var barWindow: null
    property bool popupOpen: false
    property double lastCloseTime: 0

    HyprlandFocusGrab {
        active: launcherRoot.popupOpen
        windows: [ slatePopup ]
        onCleared: {
            launcherRoot.popupOpen = false;
        }
    }

    HudPanel {
        id: panel
        width: 34
        height: Theme.pillHeight
        fillColor: launcherRoot.popupOpen ? Theme.panelActive : (pillArea.containsMouse ? Theme.panelHover : Theme.panelFill)
        strokeColor: launcherRoot.popupOpen || pillArea.containsMouse ? Theme.shrineTeal : Theme.panelStroke

        Glyph {
            id: emblem
            anchors.centerIn: parent
            name: "slate"
            size: 17
            weight: 1.8
            color: launcherRoot.popupOpen || pillArea.containsMouse ? Theme.sunbeam : Theme.shrineTeal

            // Slow glow while idle, like a dormant shrine
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: !launcherRoot.popupOpen && !pillArea.containsMouse
                NumberAnimation { to: 0.55; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
                onStopped: emblem.opacity = 1.0
            }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (Date.now() - launcherRoot.lastCloseTime < 200) return;
                launcherRoot.popupOpen = !launcherRoot.popupOpen;
            }
        }
    }

    // Slate Popup
    PopupWindow {
        id: slatePopup
        visible: launcherRoot.popupOpen
        color: "transparent"
        implicitWidth: 260
        implicitHeight: slateColumn.implicitHeight + 28
        anchor.window: launcherRoot.barWindow
        anchor.rect.x: launcherRoot.mapToItem(null, 0, 0).x
        anchor.rect.y: Theme.barHeight + 4

        onClosed: {
            launcherRoot.lastCloseTime = Date.now();
            launcherRoot.popupOpen = false;
        }

        HudPanel {
            anchors.fill: parent
            cut: 10
            fillColor: Theme.popupFill
            strokeColor: Theme.popupStroke

            ColumnLayout {
                id: slateColumn
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Glyph {
                        name: "slate"
                        size: 22
                        weight: 1.6
                        color: Theme.shrineTeal
                    }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "Slate"
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            color: Theme.sunbeam
                        }
                        Text {
                            text: "Runes & tools"
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeSmall
                            font.italic: true
                            color: Theme.leaf
                        }
                    }
                }

                Flourish {
                    Layout.fillWidth: true
                    color: Theme.shrineTeal
                }

                Repeater {
                    model: [
                        { title: "Stasis", subtitle: "Lock Wayland session", icon: "lock", cmd: "qs -p /home/arturmarcon/.config/quickshell/hyrule-lock/shell.qml &", color: Theme.sunlit },
                        { title: "Terminal", subtitle: "Launch Kitty shell", icon: "terminal", cmd: "kitty &", color: Theme.shrineTeal },
                        { title: "Files", subtitle: "Browse file system", icon: "folder", cmd: "dolphin &", color: Theme.amber },
                        { title: "Search", subtitle: "Application launcher", icon: "search", cmd: "rofi -show drun || wofi --show drun &", color: Theme.leaf },
                        { title: "Camera", subtitle: "Capture screenshot", icon: "camera", cmd: "grim -g \"$(slurp)\" /tmp/screenshot.png || hyprshot -m region &", color: Theme.heartLight }
                    ]

                    delegate: MenuEntry {
                        title: modelData.title
                        subtitle: modelData.subtitle
                        icon: modelData.icon
                        accent: modelData.color
                        onActivated: {
                            procExec.command = ["bash", "-c", modelData.cmd];
                            procExec.running = true;
                            launcherRoot.popupOpen = false;
                        }
                    }
                }
            }
        }
    }

    Process {
        id: procExec
    }
}
