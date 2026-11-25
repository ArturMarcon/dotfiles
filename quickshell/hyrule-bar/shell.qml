import QtQuick
import Quickshell

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        HyruleBar {
        }
    }

    // The desktop widgets get one screen: the laptop, or DP-2 with the lid closed.
    // A new window is made when that changes, since moving a live one between
    // screens crashes Quickshell.
    Variants {
        model: {
            var preferred = ["eDP-1", "DP-2"];
            var screens = Quickshell.screens;
            for (var p = 0; p < preferred.length; p++) {
                for (var i = 0; i < screens.length; i++) {
                    if (screens[i].name === preferred[p]) return [screens[i]];
                }
            }
            return screens.length > 0 ? [screens[0]] : [];
        }

        DesktopWidgets {
        }
    }
}
