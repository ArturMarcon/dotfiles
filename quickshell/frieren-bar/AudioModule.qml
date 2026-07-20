import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: audioRoot
    implicitWidth: width
    implicitHeight: height
    width: audioPill.width
    height: Theme.pillHeight

    property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property bool isMuted: sinkAudio ? sinkAudio.muted : false
    property double volLevel: sinkAudio ? sinkAudio.volume : 0.0
    property int volPercent: Math.round(volLevel * 100)

    Rectangle {
        id: audioPill
        implicitWidth: width
        implicitHeight: height
        width: audioRow.implicitWidth + 22
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: audioArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget
        border.width: 1
        border.color: audioRoot.isMuted ? Theme.starkRed : (audioArea.containsMouse ? Theme.zoltraakGold : Theme.borderSubtle)

        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Mana gauge bar at bottom of pill
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            anchors.left: parent.left
            anchors.leftMargin: 6
            width: Math.max(0, Math.min(parent.width - 12, (parent.width - 12) * audioRoot.volLevel))
            height: 2
            radius: 1
            color: audioRoot.isMuted ? Theme.starkRed : Theme.zoltraakGold
            opacity: audioArea.containsMouse || audioRoot.volLevel > 0 ? 0.8 : 0.0
            Behavior on width { NumberAnimation { duration: 80 } }
        }

        RowLayout {
            id: audioRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: {
                    if (audioRoot.isMuted) return "\uf026";
                    if (audioRoot.volLevel <= 0.01) return "\uf026";
                    if (audioRoot.volLevel < 0.35) return "\uf026";
                    if (audioRoot.volLevel < 0.70) return "\uf027";
                    return "\uf028";
                }
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: audioRoot.isMuted ? Theme.starkRed : Theme.zoltraakGold
            }

            Text {
                text: audioRoot.volPercent + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: audioRoot.isMuted ? Theme.starkRed : Theme.textPrimary
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
