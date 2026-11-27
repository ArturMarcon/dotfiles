import QtQuick

// Right-click menu inside the inventory window: the pause menu's dark glass,
// with the blue pointer on the hovered row. Entries are
// { title, glyph or iconSource, hint, danger, action } or { separator: true }.
// An action may show another list in the same spot, for submenus.
Item {
    id: menu
    property bool open: false
    property var entries: []
    property int hovered: -1
    property real atX: 0
    property real atY: 0

    visible: open

    function show(list, x, y) {
        entries = list;
        atX = x;
        atY = y;
        hovered = -1;
        open = true;
    }

    function close() {
        open = false;
    }

    function activate(i) {
        var e = entries[i];
        if (!e || e.separator) return;
        close();
        e.action();
    }

    // Keyboard, forwarded by the view while the menu is open
    function move(delta) {
        if (entries.length === 0) return;
        var i = hovered;
        for (var n = 0; n < entries.length; n++) {
            i = (i + delta + entries.length) % entries.length;
            if (!entries[i].separator) break;
        }
        hovered = i;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: menu.close()
    }

    Item {
        id: panel
        width: 250
        height: column.implicitHeight + 16
        x: Math.max(8, Math.min(menu.atX, menu.width - width - 8))
        y: Math.max(8, Math.min(menu.atY, menu.height - height - 8))

        GlassPanel {
            anchors.fill: parent
            radius: 10
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column
            x: 8
            y: 8
            width: parent.width - 16

            Repeater {
                model: menu.entries

                Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool active: index === menu.hovered

                    width: column.width
                    height: modelData.separator ? 11 : 32

                    Rule {
                        visible: row.modelData.separator === true
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                    }

                    Rectangle {
                        visible: !row.modelData.separator
                        anchors.fill: parent
                        radius: 4
                        opacity: row.active ? 1 : 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#05f6f2e4" }
                            GradientStop { position: 0.3; color: "#26f6f2e4" }
                            GradientStop { position: 1.0; color: "#00f6f2e4" }
                        }
                    }

                    Row {
                        visible: !row.modelData.separator
                        anchors.verticalCenter: parent.verticalCenter
                        x: 4
                        spacing: 8

                        Glyph {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "play"
                            size: 8
                            color: Theme.sheikah
                            opacity: row.active ? 1 : 0
                        }

                        Glyph {
                            visible: !row.modelData.iconSource
                            anchors.verticalCenter: parent.verticalCenter
                            name: row.modelData.glyph || ""
                            size: 16
                            color: row.modelData.danger ? Theme.crimson : (row.active ? Theme.hudText : Theme.hudTextDim)
                        }

                        Image {
                            visible: !!row.modelData.iconSource
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            source: row.modelData.iconSource || ""
                            sourceSize: Qt.size(32, 32)
                            asynchronous: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.title || ""
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            color: row.modelData.danger ? Theme.heartLight : Theme.hudText
                        }
                    }

                    Text {
                        visible: !row.modelData.separator
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.hint || ""
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                        color: Theme.hudTextDim
                        opacity: 0.8
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !row.modelData.separator
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: menu.hovered = row.index
                        onClicked: menu.activate(row.index)
                    }
                }
            }
        }
    }
}
