import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell._Window
import Quickshell.Hyprland

// The Sheikah eye opens the Slate menu. Dormant it breathes a faint glow;
// hovered or open it wakes up Sheikah blue, like a shrine switching on.
Item {
    id: launcherRoot
    implicitWidth: eye.implicitWidth + 8
    implicitHeight: Theme.slotSize
    width: implicitWidth
    height: implicitHeight

    property var barWindow: null
    property bool popupOpen: false
    property double lastCloseTime: 0
    readonly property bool awake: popupOpen || hover.hovered

    property real dormantGlow: 0
    SequentialAnimation on dormantGlow {
        running: !launcherRoot.awake
        loops: Animation.Infinite
        NumberAnimation { to: 0.6; duration: 2200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.0; duration: 2200; easing.type: Easing.InOutSine }
    }

    HyprlandFocusGrab {
        active: launcherRoot.popupOpen
        windows: [ slatePopup ]
        onCleared: {
            launcherRoot.popupOpen = false;
        }
    }

    SheikahEye {
        id: eye
        anchors.centerIn: parent
        size: 20
        color: launcherRoot.awake ? Theme.sheikah : Theme.hudText
        Behavior on color { ColorAnimation { duration: Theme.animDurationNormal } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.sheikah
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowBlur: 0.8
            shadowOpacity: launcherRoot.awake ? 1.0 : launcherRoot.dormantGlow
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (Date.now() - launcherRoot.lastCloseTime < 200) return;
            launcherRoot.popupOpen = !launcherRoot.popupOpen;
        }
    }

    PopupWindow {
        id: slatePopup
        visible: launcherRoot.popupOpen
        color: "transparent"
        implicitWidth: 270
        implicitHeight: slateMenu.implicitHeight
        // Anchored to the eye itself, so it follows wherever the bar lays it out
        anchor.item: launcherRoot
        anchor.rect.x: 0
        anchor.rect.y: launcherRoot.height + (Theme.barHeight - launcherRoot.height) / 2 + 4

        onClosed: {
            launcherRoot.lastCloseTime = Date.now();
            launcherRoot.popupOpen = false;
        }

        MenuFrame {
            id: slateMenu
            anchors.fill: parent
            title: "Sheikah Slate"
            subtitle: "Runes & tools"

            Repeater {
                model: [
                    { title: "Stasis", subtitle: "Lock the session", icon: "lock", cmd: "qs -p /home/arturmarcon/.config/quickshell/hyrule-lock/shell.qml &", color: Theme.sheikah },
                    { title: "Terminal", subtitle: "Open a kitty shell", icon: "terminal", cmd: "kitty &", color: Theme.shrineTeal },
                    { title: "Files", subtitle: "Browse with Dolphin", icon: "folder", cmd: "dolphin &", color: Theme.amber },
                    { title: "Search", subtitle: "Find an application", icon: "search", cmd: "wofi --show drun &", color: Theme.leaf },
                    { title: "Camera", subtitle: "Capture a region", icon: "camera", cmd: "~/.config/hypr/screenshot.sh region &", color: Theme.heartLight }
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

    Process {
        id: procExec
    }
}
