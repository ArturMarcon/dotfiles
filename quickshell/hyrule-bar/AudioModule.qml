import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Volume as a round gauge, like the game's sound meter. Scroll to change, click to mute.
HudGauge {
    id: audioRoot

    property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property bool isMuted: sinkAudio ? sinkAudio.muted : false
    property double volLevel: sinkAudio ? sinkAudio.volume : 0.0

    value: isMuted ? 0 : volLevel
    arcColor: Theme.hudText
    glyph: (isMuted || volLevel <= 0.01) ? "speaker-off" : (volLevel < 0.5 ? "speaker-low" : "speaker")
    glyphColor: isMuted ? Theme.heartLight : Theme.hudText
    label: Math.round(volLevel * 100).toString()

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (audioRoot.sinkAudio)
                audioRoot.sinkAudio.muted = !audioRoot.sinkAudio.muted;
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
