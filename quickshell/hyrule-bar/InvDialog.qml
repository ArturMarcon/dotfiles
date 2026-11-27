import QtQuick
import QtQuick.Layouts

// A small question box over the inventory: rename, new folder, or a
// confirmation before something can't be undone.
Item {
    id: dialog
    property bool open: false
    property string title: ""
    property string message: ""
    property bool withInput: false
    property bool danger: false
    property string acceptLabel: "Confirm"
    property var onAccept: null

    signal closed()

    visible: open

    // opts: { title, message, text, select, acceptLabel, danger, accept(text) }
    function ask(opts) {
        title = opts.title || "";
        message = opts.message || "";
        withInput = opts.text !== undefined;
        danger = opts.danger === true;
        acceptLabel = opts.acceptLabel || "Confirm";
        onAccept = opts.accept;
        open = true;
        if (withInput) {
            field.text = opts.text;
            field.forceActiveFocus();
            // Select the name without its extension, so typing replaces just that
            var end = opts.select !== undefined ? opts.select : opts.text.length;
            field.select(0, end);
        } else {
            keys.forceActiveFocus();
        }
    }

    function accept() {
        if (withInput && field.text.trim() === "") return;
        var cb = onAccept;
        var value = field.text.trim();
        cancel();
        if (cb) cb(value);
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
            onPressed: dialog.cancel()
        }
    }

    Item {
        id: keys
        Keys.onReturnPressed: dialog.accept()
        Keys.onEnterPressed: dialog.accept()
        Keys.onEscapePressed: dialog.cancel()
    }

    Item {
        anchors.centerIn: parent
        width: 420
        height: body.implicitHeight + 44

        GlassPanel {
            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 22
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rule {
                    Layout.fillWidth: true
                    fadeLeft: true
                }

                Text {
                    text: dialog.title
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fontSizeLarge + 2
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: dialog.danger ? Theme.heartLight : Theme.hudText
                }

                Rule {
                    Layout.fillWidth: true
                }
            }

            Text {
                Layout.fillWidth: true
                visible: dialog.message !== ""
                text: dialog.message
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontDisplay
                font.pixelSize: 14
                color: Theme.hudTextDim
            }

            Rectangle {
                Layout.fillWidth: true
                visible: dialog.withInput
                implicitHeight: 40
                radius: 4
                color: Theme.invSlot
                border.width: 2
                border.color: field.activeFocus ? Theme.invGold : Theme.invSlotBorder

                TextInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    font.family: Theme.fontDisplay
                    font.pixelSize: 15
                    color: Theme.hudText
                    selectionColor: "#664fd2ff"
                    selectedTextColor: Theme.hudText
                    selectByMouse: true
                    Keys.onReturnPressed: dialog.accept()
                    Keys.onEnterPressed: dialog.accept()
                    Keys.onEscapePressed: dialog.cancel()
                }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 22

                Repeater {
                    model: [
                        { key: "⏎", label: dialog.acceptLabel, accept: true },
                        { key: "Esc", label: "Cancel", accept: false }
                    ]

                    Item {
                        id: choice
                        required property var modelData
                        implicitWidth: choiceRow.implicitWidth
                        implicitHeight: choiceRow.implicitHeight
                        opacity: choiceArea.containsMouse ? 0.75 : 1

                        Row {
                            id: choiceRow
                            spacing: 7

                            InvKeycap {
                                anchors.verticalCenter: parent.verticalCenter
                                key: choice.modelData.key
                                ink: Theme.invCream
                                face: Theme.invInk
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: choice.modelData.label
                                font.family: Theme.fontDisplay
                                font.pixelSize: 13
                                font.bold: true
                                color: choice.modelData.accept && dialog.danger ? Theme.heartLight : Theme.hudText
                            }
                        }

                        MouseArea {
                            id: choiceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: choice.modelData.accept ? dialog.accept() : dialog.cancel()
                        }
                    }
                }
            }
        }
    }
}
