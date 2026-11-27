import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQml
import Qt.labs.folderlistmodel
import Quickshell.Io

// Right side of the inventory: the selected item shown large, where the game
// stands Link, and its description card beneath. Text files open like a
// scroll; trashed things remember where they came from. Permissions and a
// folder's total size are looked up in the background once the selection
// settles.
Item {
    id: details
    property var item: null
    property var view: null

    readonly property bool textual: item !== null && (item.kind === "doc" || item.kind === "code") && item.size < 200000
    property string preview: ""
    property string origin: ""
    property string discarded: ""
    property string perms: ""
    property string dirSize: ""         // "…" while counting

    readonly property string itemPath: item ? item.path : ""

    onItemPathChanged: {
        perms = "";
        dirSize = item && item.isDir && !view.inTrashRoot ? "…" : "";
        lookupDelay.restart();
    }

    Timer {
        id: lookupDelay
        interval: 220
        onTriggered: {
            if (details.itemPath === "") return;
            // Each command echoes the path first, so answers that come back
            // after the selection moved on are recognised and dropped
            var tag = ["sh", "-c", "printf '%s\\n' \"$0\"; exec \"$@\"", details.itemPath, details.view.ops];
            propsProc.exec(tag.concat(["props", details.itemPath]));
            if (details.dirSize === "…") duProc.exec(tag.concat(["du", details.itemPath]));
        }
    }

    Process {
        id: propsProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                if (lines[0] !== details.itemPath || lines.length < 2) return;
                var f = lines[1].split("\t");
                if (f.length === 2) details.perms = f[0].slice(1) + "  ·  " + f[1];
            }
        }
    }

    Process {
        id: duProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                if (lines[0] !== details.itemPath) return;
                var n = Number(lines[1]);
                details.dirSize = lines[1] && !isNaN(n) ? details.view.humanSize(n) : "Too big to count quickly";
            }
        }
    }

    FileView {
        id: textFile
        path: details.textual ? details.item.path : ""
        printErrors: false
        onPathChanged: details.preview = ""
        onLoaded: {
            var t = text();
            details.preview = t.indexOf("\u0000") >= 0 ? "" : t.split("\n").slice(0, 80).join("\n");
        }
    }

    // The Trash keeps an info file per item with its old path and the date
    FileView {
        id: trashInfo
        path: details.item && details.view.inTrashRoot
            ? details.view.home + "/.local/share/Trash/info/" + details.item.name + ".trashinfo" : ""
        printErrors: false
        onPathChanged: {
            details.origin = "";
            details.discarded = "";
        }
        onLoaded: {
            var t = text();
            var p = t.match(/^Path=(.*)$/m);
            var d = t.match(/^DeletionDate=(.*)$/m);
            if (p) {
                var full = decodeURIComponent(p[1]);
                details.origin = details.view.prettyPath(full.replace(/\/[^\/]*$/, "") || "/");
            }
            if (d) details.discarded = details.view.formatDate(new Date(d[1]));
        }
    }

    Instantiator {
        id: contents
        model: details.item && details.item.isDir ? 1 : 0

        FolderListModel {
            folder: details.view.fileUrl(details.item.path)
            showDotAndDotDot: false
            showHidden: details.view.showHidden
        }
    }

    // The stage
    Item {
        id: stage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.min(parent.height * 0.5, width * 0.9)

        // Item art floats in a warm glow over a soft shadow
        Shape {
            id: glow
            visible: details.item !== null && !shown.hasThumb && !details.textual
            anchors.centerIn: shown
            width: shown.width * 1.6
            height: width
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"
                strokeWidth: 0
                fillGradient: RadialGradient {
                    centerX: glow.width / 2
                    centerY: glow.height / 2
                    centerRadius: glow.width / 2
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0.0; color: "#38f6d36b" }
                    GradientStop { position: 0.45; color: "#12f6d36b" }
                    GradientStop { position: 1.0; color: "#00f6d36b" }
                }

                PathAngleArc {
                    centerX: glow.width / 2
                    centerY: glow.height / 2
                    radiusX: glow.width / 2
                    radiusY: glow.height / 2
                    sweepAngle: 360
                }
            }
        }

        Shape {
            id: shadow
            visible: glow.visible
            anchors.horizontalCenter: shown.horizontalCenter
            y: shown.y + shown.height * 0.86
            width: shown.width * 0.9
            height: width
            preferredRendererType: Shape.CurveRenderer
            transform: Scale { origin.y: 0; yScale: 0.16 }

            ShapePath {
                strokeColor: "transparent"
                strokeWidth: 0
                fillGradient: RadialGradient {
                    centerX: shadow.width / 2
                    centerY: shadow.height / 2
                    centerRadius: shadow.width / 2
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0.0; color: "#8c000000" }
                    GradientStop { position: 1.0; color: "#00000000" }
                }

                PathAngleArc {
                    centerX: shadow.width / 2
                    centerY: shadow.height / 2
                    radiusX: shadow.width / 2
                    radiusY: shadow.height / 2
                    sweepAngle: 360
                }
            }
        }

        // Thumbnails sit in a thin frame; item art floats on its own
        Rectangle {
            id: photoFrame
            visible: shown.hasThumb && !details.textual
            anchors.centerIn: shown
            width: shown.paintedWidth + 10
            height: shown.paintedHeight + 10
            radius: 4
            color: Theme.invSlot
            border.width: 1
            border.color: Theme.invSlotBorder
        }

        InvItemImage {
            id: shown
            readonly property real paintedWidth: hasThumb ? Math.min(width, height * aspect) : 0
            readonly property real paintedHeight: hasThumb ? Math.min(height, width / aspect) : 0
            property real aspect: 1

            visible: details.item !== null && !details.textual
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: hasThumb ? parent.width - 30 : Math.min(parent.width, parent.height) * 0.62
            height: hasThumb ? parent.height - 30 : width
            item: details.item
            view: details.view
            pixelSize: 640
            crop: false

            // Aspect of the loaded thumbnail, for the frame
            Image {
                visible: false
                source: shown.thumbFile !== "" ? shown.view.fileUrl(shown.thumbFile) : ""
                sourceSize: Qt.size(640, 640)
                asynchronous: true
                autoTransform: true
                onStatusChanged: if (status === Image.Ready && implicitHeight > 0) shown.aspect = implicitWidth / implicitHeight
            }
        }

        // Text files: unrolled like a scroll
        Rectangle {
            visible: details.textual
            anchors.fill: parent
            anchors.margins: 12
            radius: 4
            color: "#f2ead9ae"
            border.width: 1
            border.color: "#c9a96a"
            clip: true

            Text {
                anchors.fill: parent
                anchors.margins: 14
                text: details.preview
                textFormat: Text.PlainText
                font.family: "monospace"
                font.pixelSize: 11
                color: "#3b2d18"
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                clip: true
            }

            // Rolled ends
            Repeater {
                model: [0, 1]

                Rectangle {
                    required property int modelData
                    x: -4
                    y: modelData === 0 ? -6 : parent.height - 6
                    width: parent.width + 8
                    height: 12
                    radius: 6
                    color: "#c9a96a"
                }
            }
        }

        Text {
            visible: details.item === null
            anchors.centerIn: parent
            text: "Nothing to show"
            font.family: Theme.fontDisplay
            font.pixelSize: 15
            font.italic: true
            color: Theme.hudTextDim
            opacity: 0.6
        }
    }

    // Description card
    Rectangle {
        id: card
        visible: details.item !== null
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: stage.bottom
        anchors.topMargin: 14
        height: Math.min(parent.height - stage.height - 14, info.implicitHeight + 36)
        radius: 8
        color: Theme.invPanel
        border.width: 1
        border.color: Theme.invSlotBorder
        clip: true

        ColumnLayout {
            id: info
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: details.item ? details.item.name : ""
                font.family: Theme.fontDisplay
                font.pixelSize: 21
                font.bold: true
                color: Theme.hudText
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 8

                Glyph {
                    name: "diamond"
                    size: 10
                    color: Theme.sheikah
                }

                Text {
                    text: details.item ? details.view.typeLabel(details.item, contents.object ? contents.object.count : 0) : ""
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.sheikah
                }
            }

            Rule {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                color: Theme.hudTextDim
            }

            Text {
                Layout.fillWidth: true
                text: details.item ? details.view.flavor(details.item) : ""
                wrapMode: Text.Wrap
                font.family: Theme.fontDisplay
                font.pixelSize: 14
                font.italic: true
                color: Theme.hudTextDim
                lineHeight: 1.15
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                columns: 2
                columnSpacing: 14
                rowSpacing: 5

                Repeater {
                    model: details.item ? details.view.facts(details.item, details.origin, details.discarded, details.perms, details.dirSize) : []

                    Text {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: index % 2 === 1
                        Layout.alignment: Qt.AlignTop
                        text: modelData
                        elide: index % 2 === 1 ? Text.ElideMiddle : Text.ElideNone
                        font.family: index % 2 === 0 ? Theme.fontDisplay : Theme.fontUi
                        font.pixelSize: 12
                        font.bold: index % 2 === 0
                        font.letterSpacing: index % 2 === 0 ? 0.6 : 0
                        color: index % 2 === 0 ? Theme.invGold : Theme.hudText
                    }
                }
            }
        }
    }
}
