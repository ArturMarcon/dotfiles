import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: mediaRoot

    property var activePlayer: Mpris.players && Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool isPlaying: activePlayer && activePlayer.isPlaying
    property bool hasMedia: activePlayer !== null && (activePlayer.isPlaying || activePlayer.trackTitle !== "")

    visible: hasMedia
    implicitWidth: hasMedia ? mediaPanel.width : 0
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

    HudPanel {
        id: mediaPanel
        width: mediaRow.implicitWidth + 22
        Behavior on width { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }
        height: Theme.pillHeight
        fillColor: mediaArea.containsMouse ? Theme.panelHover : Theme.panelFill
        strokeColor: mediaRoot.isPlaying ? Theme.shrineTeal : Theme.panelStroke

        RowLayout {
            id: mediaRow
            anchors.centerIn: parent
            spacing: 8

            Glyph {
                name: "note"
                size: 14
                color: mediaRoot.isPlaying ? Theme.shrineTeal : Theme.textSecondary
            }

            Text {
                Layout.maximumWidth: 200
                text: {
                    if (!mediaRoot.activePlayer) return "";
                    var artist = mediaRoot.activePlayer.trackArtist;
                    var title = mediaRoot.activePlayer.trackTitle || "Unknown Track";
                    return artist ? (artist + " · " + title) : title;
                }
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                color: Theme.textPrimary
                elide: Text.ElideRight
            }

            // Controls (visible when hovering or playing)
            RowLayout {
                spacing: 6
                visible: mediaArea.containsMouse || mediaRoot.isPlaying

                Glyph {
                    name: "prev"
                    size: 12
                    color: prevArea.containsMouse ? Theme.sunlit : Theme.textSecondary
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.previous()
                    }
                }

                Glyph {
                    name: mediaRoot.isPlaying ? "pause" : "play"
                    size: 12
                    color: playArea.containsMouse ? Theme.sunlit : Theme.textPrimary
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.togglePlaying()
                    }
                }

                Glyph {
                    name: "next"
                    size: 12
                    color: nextArea.containsMouse ? Theme.sunlit : Theme.textSecondary
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.next()
                    }
                }
            }
        }

        MouseArea {
            id: mediaArea
            anchors.fill: parent
            hoverEnabled: true
            z: -1
            onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.togglePlaying()
        }
    }
}
