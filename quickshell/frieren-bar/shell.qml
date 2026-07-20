import QtQuick
import Quickshell

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        FrierenBar {
        }
    }
}
