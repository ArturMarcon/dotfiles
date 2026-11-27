import QtQuick
import Quickshell
import Quickshell.Io

// The Inventory window. While hidden its contents are unloaded, so the
// thumbnails don't sit in memory, and each opening starts fresh on the folder
// it's given (Home for Super+E). scripts/inventory-open.sh drives it over IPC.
Scope {
    id: root
    property alias shown: persist.shown

    // Survives hiding and config reloads; path only matters for the reloads,
    // since every opening names its folder
    PersistentProperties {
        id: persist
        reloadableId: "inventory"
        property bool shown: false
        property string path: ""
        property string select: ""          // a file to reveal on opening
        property bool showHidden: false
        property int sortMode: 0
        property real zoom: 1

        // The window can come back before the folder is restored; catch up
        onReloaded: {
            var v = loader.item;
            if (v && path !== "" && v.path !== path) {
                v.reveal(path, false);
                v.backStack = [];
            }
        }
    }

    function show(path, isFile) {
        if (path !== "") {
            if (loader.item) {
                loader.item.reveal(path, isFile);
            } else {
                persist.path = isFile ? path.replace(/\/[^\/]*$/, "") || "/" : path;
                persist.select = isFile ? path : "";
            }
        }
        persist.shown = true;
    }

    IpcHandler {
        target: "inventory"

        // Show the window; a folder path also opens that folder
        function open(path: string): void {
            root.show(path, false);
        }

        // Open the folder a file is in, with that file selected
        function reveal(path: string): void {
            root.show(path, true);
        }

        function toggle(): void {
            persist.shown = !persist.shown;
        }

        function close(): void {
            persist.shown = false;
        }
    }

    FloatingWindow {
        id: win
        title: "Inventory"
        visible: persist.shown
        implicitWidth: 1320
        implicitHeight: 820
        minimumSize: Qt.size(480, 360)
        color: "transparent"

        onVisibleChanged: {
            if (!visible) persist.shown = false;
        }

        Loader {
            id: loader
            anchors.fill: parent
            active: persist.shown
            focus: true

            sourceComponent: InventoryView {
                focus: true
                showHidden: persist.showHidden
                sortMode: persist.sortMode
                zoom: persist.zoom

                // Its starting values (Home, first item) would overwrite what's
                // saved, so only write back once it has caught up
                property bool restored: false

                onCloseRequested: persist.shown = false
                onPathChanged: if (restored) persist.path = path
                onShowHiddenChanged: if (restored) persist.showHidden = showHidden
                onSortModeChanged: if (restored) persist.sortMode = sortMode
                onZoomChanged: if (restored) persist.zoom = zoom

                Component.onCompleted: {
                    if (persist.path !== "") reveal(persist.select !== "" ? persist.select : persist.path, persist.select !== "");
                    persist.select = "";
                    persist.path = path;
                    restored = true;
                    backStack = [];
                    forceActiveFocus();
                }
            }
        }
    }
}
