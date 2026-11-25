import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: audioRoot
    implicitWidth: audioPanel.width
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

    property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property bool isMuted: sinkAudio ? sinkAudio.muted : false
    property double volLevel: sinkAudio ? sinkAudio.volume : 0.0
    property int volPercent: Math.round(volLevel * 100)

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    HudPanel {
        id: audioPanel
        width: audioRow.implicitWidth + 20
        height: Theme.pillHeight
        fillColor: audioArea.containsMouse ? Theme.panelHover : Theme.panelFill
        strokeColor: audioRoot.isMuted ? Theme.crimson : (audioArea.containsMouse ? Theme.sunlit : Theme.panelStroke)

        // Volume gauge along the bottom edge
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            anchors.left: parent.left
            anchors.leftMargin: 7
            width: Math.max(0, Math.min(parent.width - 14, (parent.width - 14) * audioRoot.volLevel))
            height: 2
            color: audioRoot.isMuted ? Theme.crimson : Theme.leaf
            opacity: 0.75
            Behavior on width { NumberAnimation { duration: 80 } }
        }

        Row {
            id: audioRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            spacing: 6

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                name: {
                    if (audioRoot.isMuted || audioRoot.volLevel <= 0.01) return "speaker-off";
                    if (audioRoot.volLevel < 0.5) return "speaker-low";
                    return "speaker";
                }
                color: audioRoot.isMuted ? Theme.crimson : Theme.sunlit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: audioRoot.volPercent + "%"
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: audioRoot.isMuted ? Theme.heartLight : Theme.textPrimary
            }
        }

        MouseArea {
            id: audioArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (audioRoot.sinkAudio) {
                    audioRoot.sinkAudio.muted = !audioRoot.sinkAudio.muted;
                }
            }
        }

        WheelHandler {
            onWheel: (wheel) => {
                if (audioRoot.sinkAudio) {
                    var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    audioRoot.sinkAudio.volume = Math.max(0.0, Math.min(1.5, audioRoot.sinkAudio.volume + step));
                }
            }
        }
    }
}
