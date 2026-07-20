import QtQuick
import Quickshell

ShellRoot {
    id: root

    FloatingWindow {
        id: testWindow
        title: "Magic Circle Lock Screen - Prototype Test Window"
        width: 1080
        height: 720
        visible: true

        MagicCircleSurface {
            anchors.fill: parent
            isTestMode: true
            enableIntruderCapture: true // Takes picture on miss and displays on background for next try
            onUnlockTriggered: {
                console.log("[Test Window] Unlock signal emitted! 95% threshold reached successfully.");
            }
        }
    }
}
