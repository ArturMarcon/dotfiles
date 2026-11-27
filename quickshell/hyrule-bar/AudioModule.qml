import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Volume as the game's sound meter: a purple wheel, heart red when muted.
// Scroll to change, click to mute.
LitWheel {
    id: audioRoot

    property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property bool isMuted: sinkAudio ? sinkAudio.muted : false
    property double volLevel: sinkAudio ? sinkAudio.volume : 0.0

    accent: isMuted ? Theme.crimson : Theme.sound
    value: isMuted ? 0 : volLevel
    glyph: (isMuted || volLevel <= 0.01) ? "speaker-off" : (volLevel < 0.5 ? "speaker-low" : "speaker")
    label: Math.round(volLevel * 100).toString()

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    onClicked: {
        if (!sinkAudio) return;
        sinkAudio.muted = !sinkAudio.muted;
        flare();
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
