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
    implicitWidth: width
    implicitHeight: height
    width: hasMedia ? mediaPill.width : 0
    height: Theme.pillHeight

    Behavior on width { NumberAnimation { duration: Theme.animDurationNormal; easing.type: Easing.OutCubic } }

    Rectangle {
        id: mediaPill
        implicitWidth: width
        implicitHeight: height
        width: mediaRow.implicitWidth + 24
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: mediaArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget
        border.width: 1
        border.color: mediaRoot.isPlaying ? Theme.arcaneViolet : Theme.borderSubtle

        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Glow aura when playing
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.arcaneViolet
            opacity: mediaRoot.isPlaying ? 0.35 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDurationNormal } }
        }

        RowLayout {
            id: mediaRow
            anchors.centerIn: parent
            spacing: 8

            // Bard's Melody Icon
            Text {
                text: mediaRoot.isPlaying ? "♬" : "♫"
                font.pixelSize: 14
                color: mediaRoot.isPlaying ? Theme.zoltraakGold : Theme.textSecondary
                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
            }

            // Track Info
            Text {
                Layout.maximumWidth: 200
                text: {
                    if (!mediaRoot.activePlayer) return "";
                    var artist = mediaRoot.activePlayer.trackArtist;
                    var title = mediaRoot.activePlayer.trackTitle || "Unknown Track";
                    return artist ? (artist + " • " + title) : title;
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textPrimary
                elide: Text.ElideRight
            }

            // Controls (Visible when hovering or playing)
            RowLayout {
                spacing: 4
                visible: mediaArea.containsMouse || mediaRoot.isPlaying

                // Prev
                Text {
                    text: "⏮"
                    font.pixelSize: 12
                    color: prevArea.containsMouse ? Theme.zoltraakGold : Theme.textSecondary
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.previous()
                    }
                }

                // Play / Pause
                Text {
                    text: mediaRoot.isPlaying ? "⏸" : "▶"
                    font.pixelSize: 13
                    color: playArea.containsMouse ? Theme.zoltraakGold : Theme.textPrimary
                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.togglePlaying()
                    }
                }

                // Next
                Text {
                    text: "⏭"
                    font.pixelSize: 12
                    color: nextArea.containsMouse ? Theme.zoltraakGold : Theme.textSecondary
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
            onClicked: if (mediaRoot.activePlayer && !playArea.containsMouse && !prevArea.containsMouse && !nextArea.containsMouse) {
                mediaRoot.activePlayer.togglePlaying();
            }
        }
    }
}
