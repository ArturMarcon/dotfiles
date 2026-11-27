import QtQuick

// The inventory's category strip: a cream band of place icons between Q and E
// (the game's L and R). The open place sits on a dark tile with its name in
// a bubble above, like the game's tab label. Files dropped on a tab go to
// that place (on the Trash, to the Trash).
Item {
    id: strip
    property var places: []
    property int current: -1
    property var view: null
    signal picked(int index)
    signal step(int delta)
    signal menuRequested(int index, real x, real y)

    property int tabSize: 40
    property int tabGap: 10
    readonly property int bubbleHeight: 26

    implicitWidth: band.width
    implicitHeight: bubbleHeight + 8 + band.height

    Rectangle {
        id: band
        y: strip.bubbleHeight + 8
        width: tabs.width + 2 * 46
        height: strip.tabSize + 10
        radius: 6
        color: Theme.invCream

        InvKeycap {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            key: "Q"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: strip.step(-1)
            }
        }

        Row {
            id: tabs
            anchors.centerIn: parent
            spacing: strip.tabGap

            Repeater {
                model: strip.places

                Item {
                    id: tab
                    required property var modelData
                    required property int index
                    readonly property bool active: index === strip.current
                    readonly property bool dropHot: tabDrop.containsDrag

                    width: strip.tabSize
                    height: strip.tabSize

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: tab.dropHot ? Theme.sheikahFill : tab.active ? Theme.invInk : (tabArea.containsMouse ? Theme.invCreamShade : "transparent")
                        border.width: tab.dropHot ? 2 : 0
                        border.color: Theme.sheikah
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                    }

                    Glyph {
                        anchors.centerIn: parent
                        name: tab.modelData.glyph
                        size: Math.round(strip.tabSize * 0.6)
                        weight: 2.4
                        color: tab.dropHot ? Theme.sheikah : tab.active ? Theme.invCream : Theme.invInkSoft
                    }

                    MouseArea {
                        id: tabArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                var at = tab.mapToItem(strip, mouse.x, mouse.y);
                                strip.menuRequested(tab.index, at.x, at.y);
                            } else {
                                strip.picked(tab.index);
                            }
                        }
                    }

                    DropArea {
                        id: tabDrop
                        anchors.fill: parent
                        enabled: strip.view !== null
                        onEntered: (drag) => {
                            if (!strip.view.canDropInto(tab.modelData.path, drag)) drag.accepted = false;
                        }
                        onDropped: (drop) => {
                            var at = tab.mapToItem(strip.view, drop.x, drop.y);
                            strip.view.dropInto(tab.modelData.path, drop, at.x, at.y);
                        }
                    }
                }
            }
        }

        InvKeycap {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            key: "E"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: strip.step(1)
            }
        }
    }

    // Name bubble over the open tab
    Item {
        id: bubble
        visible: strip.current >= 0 && strip.current < strip.places.length
        x: band.x + tabs.x + strip.current * (strip.tabSize + strip.tabGap) + strip.tabSize / 2 - width / 2
        width: label.implicitWidth + 28
        height: strip.bubbleHeight + 6
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            width: parent.width
            height: strip.bubbleHeight
            radius: height / 2
            color: Theme.invInk
            border.width: 1
            border.color: Theme.invSlotBorder
        }

        // Pointer down to the tab
        Rectangle {
            x: parent.width / 2 - 5
            y: strip.bubbleHeight - 6
            width: 10
            height: 10
            rotation: 45
            color: Theme.invInk
        }

        Text {
            id: label
            x: 14
            height: strip.bubbleHeight
            verticalAlignment: Text.AlignVCenter
            text: bubble.visible ? strip.places[strip.current].name : ""
            font.family: Theme.fontDisplay
            font.pixelSize: 14
            font.bold: true
            color: Theme.invCream
        }
    }
}
