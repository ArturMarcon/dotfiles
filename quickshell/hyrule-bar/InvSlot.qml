import QtQuick
import QtQml
import Qt.labs.folderlistmodel

// One inventory slot: the item on dark glass, its name beneath. The selected
// slot gets the game's glowing gold frame; marked items (multi-select) a
// Sheikah-blue check where the game shows effect icons; folders their item
// count ("x12") in the corner, like a stack. Slots past the last item stay empty.
// Folders take drops: they glow Sheikah blue while something is held over them.
Item {
    id: slot
    property var item: null
    property var view: null
    property bool selected: false
    property bool marked: false
    property bool cut: false

    signal pressed(var mouse)
    signal doubleClicked()

    readonly property bool filled: item !== null
    readonly property real box: width - 14
    readonly property bool dropHot: dropZone.containsDrag

    // Folder contents, for the stack count; only folders get a model
    Instantiator {
        id: contents
        model: slot.filled && slot.item.isDir ? 1 : 0

        FolderListModel {
            folder: slot.view.fileUrl(slot.item.path)
            showDotAndDotDot: false
            showHidden: slot.view.showHidden
        }
    }
    readonly property int stack: contents.object ? contents.object.count : 0

    Item {
        id: frame
        x: 7
        y: 4
        width: slot.box
        height: slot.box
        opacity: slot.cut ? 0.45 : 1
        scale: slot.dropHot ? 1.06 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Easing.OutBack } }

        // Gold glow around the selected slot, breathing like the game's cursor
        Repeater {
            model: [{ m: -4, w: 3, o: 0.55 }, { m: -8, w: 4, o: 0.18 }]

            Rectangle {
                anchors.fill: parent
                anchors.margins: modelData.m
                radius: 6 - modelData.m
                color: "transparent"
                border.width: modelData.w
                border.color: slot.dropHot ? Theme.sheikah : Theme.invGold
                opacity: slot.dropHot ? modelData.o * 1.3 : (slot.selected ? modelData.o * glowPulse.level : 0)
                Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
            }
        }

        QtObject {
            id: glowPulse
            property real level: 1
            SequentialAnimation on level {
                running: slot.selected
                loops: Animation.Infinite
                NumberAnimation { to: 0.55; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: base
            anchors.fill: parent
            radius: 4
            color: slot.filled ? Theme.invSlot : Theme.invSlotEmpty
            border.width: slot.selected || slot.dropHot ? 3 : 1
            border.color: slot.dropHot ? Theme.sheikah : slot.selected ? Theme.invGold
                : (slot.marked ? Theme.sheikah : (hover.hovered && slot.filled ? Theme.slotBorderHover : (slot.filled ? Theme.invSlotBorder : Theme.invSlotBorderEmpty)))

            // A little light from above, like the game's lacquered slots
            Rectangle {
                anchors.fill: parent
                anchors.margins: parent.border.width
                radius: 3
                visible: slot.filled
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#14f3efe0" }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }
        }

        InvItemImage {
            id: art
            visible: slot.filled
            anchors.fill: parent
            anchors.margins: hasThumb ? 4 : slot.box * 0.12
            item: slot.item
            view: slot.view
            pixelSize: Math.round(slot.box * 1.5)
        }

        // Media marks on thumbnails, so a video frame isn't taken for a picture
        Rectangle {
            visible: slot.filled && art.hasThumb && (slot.item.kind === "video" || slot.item.kind === "audio")
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            width: 22
            height: 22
            radius: 11
            color: "#cc0c0d0b"
            border.width: 1
            border.color: Theme.invSlotBorder

            Glyph {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: slot.filled && slot.item.kind === "video" ? 1 : 0
                name: slot.filled && slot.item.kind === "video" ? "play" : "note"
                size: 11
                color: Theme.invCream
            }
        }

        // Marked: Sheikah-blue check in the corner
        Rectangle {
            visible: slot.marked
            x: 6
            y: 6
            width: 22
            height: 22
            radius: 11
            color: Theme.sheikahFill
            border.width: 1.5
            border.color: Theme.sheikah

            Glyph {
                anchors.centerIn: parent
                name: "check"
                size: 13
                weight: 2.6
                color: Theme.sheikah
            }
        }

        // Stack count for folders
        Text {
            visible: slot.filled && slot.item.isDir && slot.stack > 0
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            anchors.bottomMargin: 5
            text: "x" + slot.stack
            font.family: Theme.fontDisplay
            font.pixelSize: 15
            font.italic: true
            font.bold: true
            color: "#ffffff"
            style: Text.Outline
            styleColor: "#cc000000"
        }
    }

    Text {
        visible: slot.filled
        anchors.top: frame.bottom
        anchors.topMargin: 5
        x: 4
        width: slot.width - 8
        horizontalAlignment: Text.AlignHCenter
        text: slot.filled ? slot.item.name : ""
        elide: Text.ElideMiddle
        font.family: Theme.fontDisplay
        font.pixelSize: 12
        font.bold: slot.selected
        color: slot.selected ? Theme.invCream : Theme.hudTextDim
        style: Text.Raised
        styleColor: "#80000000"
    }

    HoverHandler {
        id: hover
        enabled: slot.filled
        cursorShape: Qt.PointingHandCursor
    }

    // Dragging a slot carries its file(s) to other apps
    Item {
        id: dragGhost
        Drag.active: area.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
        Drag.mimeData: slot.filled && slot.view ? { "text/uri-list": slot.view.dragUris(slot.item) } : {}
        Drag.imageSource: art.hasThumb && slot.filled ? slot.view.fileUrl(art.thumbFile) : ""
        Drag.imageSourceSize: Qt.size(96, 96)
        Drag.hotSpot.x: 48
        Drag.hotSpot.y: 48
    }

    DropArea {
        id: dropZone
        anchors.fill: frame
        enabled: slot.filled && slot.item.isDir
        onEntered: (drag) => {
            if (!slot.view.canDropInto(slot.item.path, drag)) drag.accepted = false;
        }
        onDropped: (drop) => {
            var at = slot.mapToItem(slot.view, drop.x + frame.x, drop.y + frame.y);
            slot.view.dropInto(slot.item.path, drop, at.x, at.y);
        }
    }

    MouseArea {
        id: area
        anchors.fill: frame
        enabled: slot.filled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: dragGhost
        preventStealing: true
        onPressed: (mouse) => slot.pressed(mouse)
        onDoubleClicked: (mouse) => { if (mouse.button === Qt.LeftButton) slot.doubleClicked(); }
    }
}
