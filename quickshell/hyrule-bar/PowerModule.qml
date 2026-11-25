import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell._Window
import Quickshell.Hyprland

// Power in an inventory slot; opens the Rest menu.
Item {
    id: powerRoot
    implicitWidth: Theme.slotSize
    implicitHeight: Theme.slotSize
    width: implicitWidth
    height: implicitHeight

    property var barWindow: null
    property bool popupOpen: false
    property double lastCloseTime: 0

    HyprlandFocusGrab {
        active: powerRoot.popupOpen
        windows: [ powerPopup ]
        onCleared: {
            powerRoot.popupOpen = false;
        }
    }

    ItemSlot {
        id: slot
        anchors.fill: parent
        active: powerRoot.popupOpen

        Glyph {
            anchors.centerIn: parent
            name: "power"
            size: 13
            color: slot.hovered || powerRoot.popupOpen ? Theme.heartLight : Theme.hudText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (Date.now() - powerRoot.lastCloseTime < 200) return;
                powerRoot.popupOpen = !powerRoot.popupOpen;
            }
        }
    }

    PopupWindow {
        id: powerPopup
        visible: powerRoot.popupOpen
        color: "transparent"
        implicitWidth: 260
        implicitHeight: restMenu.implicitHeight
        anchor.item: powerRoot
        anchor.rect.x: powerRoot.width - 260
        anchor.rect.y: powerRoot.height + (Theme.barHeight - powerRoot.height) / 2 + 4

        onClosed: {
            powerRoot.lastCloseTime = Date.now();
            powerRoot.popupOpen = false;
        }

        MenuFrame {
            id: restMenu
            anchors.fill: parent
            title: "Rest"
            subtitle: "Session & power"

            Repeater {
                model: [
                    { title: "Stasis", subtitle: "Lock the session", icon: "lock", cmd: "qs -p /home/arturmarcon/.config/quickshell/hyrule-lock/shell.qml || loginctl lock-session &", color: Theme.sheikah },
                    { title: "Rest by the Fire", subtitle: "Suspend", icon: "campfire", cmd: "systemctl suspend &", color: Theme.amber },
                    { title: "Blood Moon", subtitle: "Reboot", icon: "blood-moon", cmd: "systemctl reboot &", color: Theme.heartLight },
                    { title: "Depart", subtitle: "Power off", icon: "power", cmd: "systemctl poweroff &", color: Theme.crimson }
                ]

                delegate: MenuEntry {
                    title: modelData.title
                    subtitle: modelData.subtitle
                    icon: modelData.icon
                    accent: modelData.color
                    onActivated: {
                        procPower.command = ["bash", "-c", modelData.cmd];
                        procPower.running = true;
                        powerRoot.popupOpen = false;
                    }
                }
            }
        }
    }

    Process {
        id: procPower
    }
}
