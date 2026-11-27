import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland

// Wallpapers: the forest temple loop on landscape screens, a still on portrait
// ones (the vertical monitor). The video is decoded on the Intel iGPU (VAAPI)
// and drawn straight from GPU memory, so it costs the CPU very little;
// hypr/autostart.lua starts this with the environment that keeps the NVIDIA
// GPU out of it.
ShellRoot {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/wallpapers/"
    readonly property string animation: dir + "link-and-the-forest-temple-botw-moewalls-com.mp4"
    readonly property string still: dir + "botw-vertical.jpg"

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: wall
            required property var modelData
            readonly property bool portrait: modelData.height > modelData.width

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "hyrule-wallpaper"
            color: "black"

            Image {
                visible: wall.portrait
                anchors.fill: parent
                source: wall.portrait ? "file://" + root.still : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            // Each landscape screen plays its own copy: frames can't be shared
            // between windows. No audioOutput, so the sound is never decoded.
            Loader {
                anchors.fill: parent
                active: !wall.portrait

                sourceComponent: Item {
                    MediaPlayer {
                        source: "file://" + root.animation
                        loops: MediaPlayer.Infinite
                        videoOutput: output
                        Component.onCompleted: play()
                    }

                    VideoOutput {
                        id: output
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                    }
                }
            }
        }
    }
}
