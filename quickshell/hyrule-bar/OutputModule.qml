import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// Headset (Sheikah blue) or speakers (ember orange), as a lit wheel left of
// the volume wheel. Left click swaps the output (hypr/audio-output.sh);
// right click opens the Sound menu.
Item {
    id: outputRoot
    implicitWidth: Theme.wheelSize
    implicitHeight: Theme.wheelSize
    width: implicitWidth
    height: implicitHeight

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/audio-output.sh"
    property string output: ""
    property string shownGlyph: ""
    property bool popupOpen: false
    property double lastCloseTime: 0

    property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property bool isMuted: sinkAudio ? sinkAudio.muted : false
    property real volLevel: sinkAudio ? sinkAudio.volume : 0

    function glyphFor(out) {
        return out === "headset" ? "headset" : "speakers";
    }

    function colorFor(out) {
        return out === "headset" ? Theme.sheikah : Theme.ember;
    }

    // The slot's colour crossfades while the item turns over
    property color accent: Theme.ember
    Behavior on accent {
        enabled: outputRoot.shownGlyph !== ""
        ColorAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    property real turn: 0

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    // The script decides which output is active; ask again whenever the default changes
    Process {
        id: statusProc
        command: [outputRoot.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: outputRoot.output = text.trim()
        }
    }

    Process {
        id: toggleProc
        command: [outputRoot.script, "toggle"]
    }

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { statusProc.running = true; }
    }

    Component.onCompleted: statusProc.running = true

    // Swapping outputs turns the item over in its slot, like rotating gear in the inventory
    onOutputChanged: {
        accent = colorFor(output);
        if (shownGlyph === "") shownGlyph = glyphFor(output);
        else swap.restart();
    }

    SequentialAnimation {
        id: swap
        ScriptAction { script: slot.flare() }
        NumberAnimation { target: outputRoot; property: "turn"; to: 90; duration: 110; easing.type: Easing.InQuad }
        ScriptAction { script: outputRoot.shownGlyph = outputRoot.glyphFor(outputRoot.output) }
        PropertyAction { target: outputRoot; property: "turn"; value: -90 }
        NumberAnimation { target: outputRoot; property: "turn"; to: 0; duration: 160; easing.type: Easing.OutBack }
    }

    HyprlandFocusGrab {
        active: outputRoot.popupOpen
        windows: [ soundPopup ]
        onCleared: outputRoot.popupOpen = false
    }

    LitWheel {
        id: slot
        anchors.fill: parent
        accent: outputRoot.accent
        glyph: outputRoot.shownGlyph
        glyphSize: 12
        held: outputRoot.popupOpen
        turn: outputRoot.turn

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (Date.now() - outputRoot.lastCloseTime < 200) return;
                outputRoot.popupOpen = !outputRoot.popupOpen;
            } else if (!toggleProc.running) {
                toggleProc.running = true;
            }
        }
    }

    PopupWindow {
        id: soundPopup
        visible: outputRoot.popupOpen
        color: "transparent"
        implicitWidth: 280
        implicitHeight: soundMenu.implicitHeight
        anchor.item: outputRoot
        anchor.rect.x: (outputRoot.width - 280) / 2
        anchor.rect.y: outputRoot.height + (Theme.barHeight - outputRoot.height) / 2 + 4

        onClosed: {
            outputRoot.lastCloseTime = Date.now();
            outputRoot.popupOpen = false;
        }

        MenuFrame {
            id: soundMenu
            anchors.fill: parent
            title: "Sound"
            subtitle: outputRoot.output === "headset" ? "Headset" : "Speakers"

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 10

                // Mute
                Item {
                    implicitWidth: 18
                    implicitHeight: 18

                    Glyph {
                        anchors.centerIn: parent
                        name: outputRoot.isMuted || outputRoot.volLevel <= 0.01 ? "speaker-off" : (outputRoot.volLevel < 0.5 ? "speaker-low" : "speaker")
                        size: 16
                        color: outputRoot.isMuted ? Theme.heartLight : (muteHover.hovered ? Theme.sheikah : Theme.hudText)
                    }

                    HoverHandler {
                        id: muteHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: if (outputRoot.sinkAudio) outputRoot.sinkAudio.muted = !outputRoot.sinkAudio.muted
                    }
                }

                VolumeSlider {
                    Layout.fillWidth: true
                    value: outputRoot.volLevel
                    muted: outputRoot.isMuted
                    onMoved: (v) => {
                        if (!outputRoot.sinkAudio) return;
                        outputRoot.sinkAudio.volume = v;
                        if (v > 0 && outputRoot.sinkAudio.muted) outputRoot.sinkAudio.muted = false;
                    }
                }

                Text {
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(outputRoot.volLevel * 100) + "%"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    color: outputRoot.isMuted ? Theme.hudTextDim : Theme.hudText
                }
            }
        }
    }
}
