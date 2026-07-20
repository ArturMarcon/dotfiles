import QtQuick
import Quickshell
import "../frieren-bar" as Frieren

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        Frieren.FrierenBar {
        }
    }
}
