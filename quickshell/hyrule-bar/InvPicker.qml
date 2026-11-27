import QtQuick
import QtQuick.Layouts
import Quickshell

// "Open With → Other Application…": every installed app, filtered as you
// type, in the same glass box as the inventory's other questions.
Item {
    id: picker
    property bool open: false
    property string subtitle: ""
    property var onPick: null
    property int current: 0

    signal closed()

    visible: open

    readonly property var apps: {
        var q = filter.text.toLowerCase().trim();
        return Array.from(DesktopEntries.applications.values)
            .filter(a => !a.noDisplay && (q === ""
                || a.name.toLowerCase().indexOf(q) >= 0
                || (a.genericName || "").toLowerCase().indexOf(q) >= 0))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    onAppsChanged: current = 0
    onCurrentChanged: list.positionViewAtIndex(current, ListView.Contain)

    function ask(sub, cb) {
        subtitle = sub;
        onPick = cb;
        filter.text = "";
        current = 0;
        open = true;
        filter.forceActiveFocus();
    }

    function choose(i) {
        var app = apps[i];
        if (!app) return;
        var cb = onPick;
        cancel();
        if (cb) cb(app);
    }

    function cancel() {
        open = false;
        closed();
    }

    Rectangle {
        anchors.fill: parent
        color: "#8c000000"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: picker.cancel()
        }
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(440, parent.width - 40)
        height: Math.min(560, parent.height - 40)

        GlassPanel {
            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rule {
                    Layout.fillWidth: true
                    fadeLeft: true
                }

                Text {
                    text: "Open With"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fontSizeLarge + 2
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: Theme.hudText
                }

                Rule {
                    Layout.fillWidth: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: picker.subtitle
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontDisplay
                font.pixelSize: 13
                font.italic: true
                color: Theme.hudTextDim
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 4
                color: Theme.invSlot
                border.width: 2
                border.color: filter.activeFocus ? Theme.invGold : Theme.invSlotBorder

                Glyph {
                    id: filterGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: 14
                    color: Theme.hudTextDim
                }

                TextInput {
                    id: filter
                    anchors.left: filterGlyph.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    font.family: Theme.fontDisplay
                    font.pixelSize: 14
                    color: Theme.hudText
                    selectionColor: "#664fd2ff"
                    Keys.onUpPressed: picker.current = Math.max(0, picker.current - 1)
                    Keys.onDownPressed: picker.current = Math.min(picker.apps.length - 1, picker.current + 1)
                    Keys.onReturnPressed: picker.choose(picker.current)
                    Keys.onEnterPressed: picker.choose(picker.current)
                    Keys.onEscapePressed: picker.cancel()
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: picker.apps
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: appRow
                    required property var modelData
                    required property int index
                    readonly property bool active: index === picker.current

                    width: list.width
                    height: 36

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        opacity: appRow.active ? 1 : 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#05f6f2e4" }
                            GradientStop { position: 0.3; color: "#26f6f2e4" }
                            GradientStop { position: 1.0; color: "#00f6f2e4" }
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 6
                        spacing: 9

                        Glyph {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "play"
                            size: 8
                            color: Theme.sheikah
                            opacity: appRow.active ? 1 : 0
                        }

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            source: Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
                            sourceSize: Qt.size(44, 44)
                            asynchronous: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: appRow.modelData.name
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: appRow.active
                            color: Theme.hudText
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: picker.current = appRow.index
                        onClicked: picker.choose(appRow.index)
                    }
                }
            }
        }
    }
}
