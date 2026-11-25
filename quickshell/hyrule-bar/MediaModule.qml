import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Now playing, as plain floating text; controls appear on hover.
Item {
    id: mediaRoot

    property var activePlayer: Mpris.players && Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool isPlaying: activePlayer && activePlayer.isPlaying
    property bool hasMedia: activePlayer !== null && (activePlayer.isPlaying || activePlayer.trackTitle !== "")

    visible: hasMedia
    implicitWidth: hasMedia ? row.implicitWidth : 0
    implicitHeight: Theme.slotSize
    width: implicitWidth
    height: implicitHeight

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.togglePlaying()
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: "note"
            size: 14
            color: mediaRoot.isPlaying ? Theme.sheikah : Theme.hudTextDim
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 220)
            text: {
                if (!mediaRoot.activePlayer) return "";
                var artist = mediaRoot.activePlayer.trackArtist;
                var title = mediaRoot.activePlayer.trackTitle || "Unknown track";
                return artist ? (artist + " · " + title) : title;
            }
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.fontSizeSmall + 1
            font.italic: true
            color: hover.hovered ? Theme.hudText : Theme.hudTextDim
            elide: Text.ElideRight
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: hover.hovered

            Repeater {
                model: [
                    { icon: "prev", action: "previous" },
                    { icon: mediaRoot.isPlaying ? "pause" : "play", action: "togglePlaying" },
                    { icon: "next", action: "next" }
                ]

                Glyph {
                    name: modelData.icon
                    size: 12
                    color: controlArea.containsMouse ? Theme.sheikah : Theme.hudText

                    MouseArea {
                        id: controlArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer[modelData.action]()
                    }
                }
            }
        }
    }
}
