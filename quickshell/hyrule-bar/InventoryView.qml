import QtQuick
import QtQuick.Layouts
import QtQml
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// The Inventory: a file manager laid out like the game's inventory screen.
// Places are the category tabs (Q/E switch them, like L/R), files are items in
// dark glass slots, the selected one gets the gold frame and is shown large on
// the right with its description. File work goes through
// scripts/inventory-ops.sh; nothing is ever overwritten, and nothing is
// deleted outright except from the Trash, and only after asking. Most changes
// can be undone (Ctrl+Z).
FocusScope {
    id: inv
    signal closeRequested()

    readonly property string home: Quickshell.env("HOME")
    readonly property string ops: Quickshell.shellDir + "/scripts/inventory-ops.sh"
    readonly property string thumbDir: home + "/.cache/hyrule-inventory"
    readonly property string trashDir: home + "/.local/share/Trash/files"
    readonly property string mediaDir: "/run/media/" + Quickshell.env("USER")

    // Mounted drives (USB sticks and such) get their own tabs, before the Trash
    property var drives: []
    readonly property var places: [
        { name: "Home", glyph: "tab-home", path: home },
        { name: "Desktop", glyph: "tab-desktop", path: home + "/Desktop" },
        { name: "Downloads", glyph: "tab-downloads", path: home + "/Downloads" },
        { name: "Documents", glyph: "tab-docs", path: home + "/Documents" },
        { name: "Pictures", glyph: "tab-pictures", path: home + "/Pictures" },
        { name: "Music", glyph: "note", path: home + "/Music" },
        { name: "Videos", glyph: "tab-videos", path: home + "/Videos" },
        { name: "Projects", glyph: "tab-projects", path: home + "/Projects" }
    ].concat(drives).concat([{ name: "Trash", glyph: "tab-trash", path: trashDir }])

    FolderListModel {
        id: drivesModel
        folder: inv.fileUrl(inv.mediaDir)
        showFiles: false
        showDotAndDotDot: false
        onCountChanged: inv.readDrives()
        onStatusChanged: inv.readDrives()
    }

    function readDrives() {
        var list = [];
        for (var i = 0; i < drivesModel.count; i++) {
            // With no drives the folder doesn't exist, and the model lists some other one
            var p = drivesModel.get(i, "filePath");
            if (p.indexOf(mediaDir + "/") === 0) list.push({ name: drivesModel.get(i, "fileName"), glyph: "tab-drive", path: p, drive: true });
        }
        drives = list;
    }

    // ---- Where we are -----------------------------------------------------

    property string path: home
    property var backStack: []
    property var forwardStack: []
    property var lastSelected: ({})     // folder -> path of the item selected there

    readonly property bool inTrash: path === trashDir || path.indexOf(trashDir + "/") === 0
    readonly property bool inTrashRoot: path === trashDir

    // The deepest place the current folder is inside of
    readonly property int placeIndex: {
        var best = -1;
        var bestLen = -1;
        for (var i = 0; i < places.length; i++) {
            var p = places[i].path;
            if ((path === p || path.indexOf(p + "/") === 0) && p.length > bestLen) {
                best = i;
                bestLen = p.length;
            }
        }
        return best;
    }

    readonly property var crumbs: {
        var root = placeIndex >= 0 ? places[placeIndex] : { name: "/", path: "" };
        var list = [{ label: root.name, path: root.path || "/" }];
        var rest = path.slice(root.path.length).split("/").filter(s => s !== "");
        var at = root.path;
        for (var i = 0; i < rest.length; i++) {
            at += "/" + rest[i];
            list.push({ label: rest[i], path: at });
        }
        return list;
    }

    function go(target, how) {
        if (!target) return;
        if (target.length > 1) target = target.replace(/\/+$/, "");
        if (target === path && deepQuery === "") return;
        if (target !== path) {
            if (how === "back") {
                forwardStack = forwardStack.concat([path]);
            } else if (how === "forward") {
                backStack = backStack.concat([path]);
            } else {
                backStack = backStack.concat([path]).slice(-60);
                forwardStack = [];
            }
        }
        rememberSelection();
        path = target;
        query = "";
        endDeepSearch();
        searchOpen = false;
        marked = ({});
        selectedPath = lastSelected[target] || "";
        selectedIndex = 0;
        menu.close();
        refreshSpace();
        rebuild();
    }

    function back() {
        if (backStack.length === 0) return;
        var target = backStack[backStack.length - 1];
        backStack = backStack.slice(0, -1);
        go(target, "back");
    }

    function forward() {
        if (forwardStack.length === 0) return;
        var target = forwardStack[forwardStack.length - 1];
        forwardStack = forwardStack.slice(0, -1);
        go(target, "forward");
    }

    function up() {
        if (deepQuery !== "") {
            closeSearch();
            return;
        }
        if (path === "/") return;
        var parent = parentOf(path);
        lastSelected[parent] = path;
        go(parent);
    }

    function stepPlace(delta) {
        var n = places.length;
        var i = placeIndex < 0 ? (delta > 0 ? 0 : n - 1) : (placeIndex + delta + n) % n;
        go(places[i].path);
    }

    function rememberSelection() {
        if (selectedItem && deepQuery === "") lastSelected[path] = selectedItem.path;
    }

    // Ask for a path (Ctrl+L); a file opens its folder with it selected
    function goToPrompt() {
        dialog.ask({
            title: "Go To",
            text: prettyPath(path),
            acceptLabel: "Go",
            accept: (where) => runOp(["resolve", where], "", (out) => {
                var f = out.trim().split("\t");
                if (f.length === 2) reveal(f[1], f[0] === "f");
            })
        });
    }

    // ---- What's here ------------------------------------------------------

    property bool showHidden: false
    property int sortMode: 0            // 0: by name, 1: newest first
    property real zoom: 1
    readonly property var zoomSteps: [0.7, 0.85, 1, 1.2, 1.45, 1.75]

    function toggleSort() {
        sortMode = sortMode === 1 ? 0 : 1;
    }

    function zoomBy(step) {
        var i = zoomSteps.indexOf(zoom);
        if (i < 0) i = 2;
        zoom = zoomSteps[Math.max(0, Math.min(zoomSteps.length - 1, i + step))];
    }

    onSortModeChanged: rebuild()

    property string query: ""
    property bool searchOpen: false

    property var items: []

    FolderListModel {
        id: folderModel
        folder: inv.fileUrl(inv.path)
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: inv.showHidden
        sortCaseSensitive: false
        sortField: inv.sortMode === 1 ? FolderListModel.Time : FolderListModel.Name
    }

    // The model fills in a bit at a time; rebuild once it settles
    Timer {
        id: rebuildTimer
        interval: 40
        onTriggered: inv.rebuild()
    }

    Connections {
        target: folderModel
        function onStatusChanged() { rebuildTimer.restart(); }
        function onCountChanged() { rebuildTimer.restart(); }
        function onRowsInserted() { rebuildTimer.restart(); }
        function onRowsRemoved() { rebuildTimer.restart(); }
        function onDataChanged() { rebuildTimer.restart(); }
        function onModelReset() { rebuildTimer.restart(); }
        function onLayoutChanged() { rebuildTimer.restart(); }
    }

    onQueryChanged: rebuild()

    function makeItem(name, path, isDir, size, modified) {
        var dot = name.lastIndexOf(".");
        var suffix = isDir || dot <= 0 ? "" : name.slice(dot + 1).toLowerCase();
        return {
            name: name,
            path: path,
            isDir: isDir,
            size: size,
            modified: modified,
            suffix: suffix,
            kind: kindOf(name, suffix, isDir)
        };
    }

    function rebuild() {
        var out = [];
        if (deepQuery !== "") {
            out = deepResults.slice().sort((a, b) => {
                if (a.isDir !== b.isDir) return a.isDir ? -1 : 1;
                if (sortMode === 1) return b.modified - a.modified;
                return a.name.localeCompare(b.name, undefined, { sensitivity: "base" });
            });
        } else if (folderModel.status === FolderListModel.Ready) {
            var q = query.toLowerCase();
            for (var i = 0; i < folderModel.count; i++) {
                var name = folderModel.get(i, "fileName");
                if (q !== "" && name.toLowerCase().indexOf(q) < 0) continue;
                out.push(makeItem(name, folderModel.get(i, "filePath"), folderModel.get(i, "fileIsDir"),
                    folderModel.get(i, "fileSize"), folderModel.get(i, "fileModified")));
            }
        }
        items = out;

        // Forget marks on things that are gone
        var kept = {};
        var changed = false;
        for (var p in marked) {
            if (out.some(it => it.path === p)) kept[p] = true;
            else changed = true;
        }
        if (changed) marked = kept;

        restoreSelection();
    }

    // ---- Searching below this folder (⏎ in the search box) ---------------

    property string deepQuery: ""
    property var deepResults: []
    property bool searching: false
    property int searchGen: 0

    function deepSearch() {
        var q = query.trim();
        if (q === "") return;
        searchGen++;
        deepQuery = q;
        deepResults = [];
        searching = true;
        rebuild();
        // The generation goes out first, so results from an older search are dropped
        searchProc.exec(["sh", "-c", "printf '%s\\n' \"$0\"; exec \"$@\"", String(searchGen),
            ops, "search", path, q, showHidden ? "1" : "0"]);
    }

    function endDeepSearch() {
        if (deepQuery === "" && !searching) return;
        searchGen++;
        searchProc.running = false;
        deepQuery = "";
        deepResults = [];
        searching = false;
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                if (lines[0] !== String(inv.searchGen)) return;
                var found = [];
                for (var i = 1; i < lines.length; i++) {
                    var f = lines[i].split("\t");
                    if (f.length < 4) continue;
                    var p = f.slice(3).join("\t");
                    found.push(inv.makeItem(p.replace(/^.*\//, ""), p, f[0] === "d", Number(f[1]), new Date(Number(f[2]) * 1000)));
                }
                inv.deepResults = found;
                inv.searching = false;
                inv.rebuild();
            }
        }
    }

    // ---- Selection --------------------------------------------------------

    property int selectedIndex: 0
    property string selectedPath: ""
    property string pendingSelect: ""   // select this as soon as it shows up (after rename, new folder)
    property int anchorIndex: -1        // where a Shift+arrow range started
    readonly property var selectedItem: selectedIndex >= 0 && selectedIndex < items.length ? items[selectedIndex] : null

    property var marked: ({})
    readonly property int markedCount: Object.keys(marked).length

    function select(i) {
        if (items.length === 0) {
            selectedIndex = -1;
            selectedPath = "";
            return;
        }
        selectedIndex = Math.max(0, Math.min(items.length - 1, i));
        selectedPath = items[selectedIndex].path;
        scrollAnim.stop();
        grid.positionViewAtIndex(selectedIndex, GridView.Contain);
    }

    function restoreSelection() {
        var want = pendingSelect !== "" ? pendingSelect : selectedPath;
        for (var i = 0; i < items.length; i++) {
            if (items[i].path === want) {
                if (want === pendingSelect) pendingSelect = "";
                select(i);
                return;
            }
        }
        // Keep the gold frame in the same spot when the item itself left
        select(selectedIndex < 0 ? 0 : selectedIndex);
    }

    function moveSelection(delta, extend) {
        if (items.length === 0) return;
        var from = selectedIndex;
        var i = selectedIndex + delta;
        if (delta === grid.columns && i >= items.length) {
            // Down into a short last row lands on its last item
            if (Math.floor(selectedIndex / grid.columns) === Math.floor((items.length - 1) / grid.columns)) return;
            i = items.length - 1;
        }
        if (i < 0) return;
        if (extend) {
            if (anchorIndex < 0) anchorIndex = from;
            var m = {};
            for (var k = Math.min(anchorIndex, i); k <= Math.max(anchorIndex, i) && k < items.length; k++) m[items[k].path] = true;
            marked = m;
        } else {
            anchorIndex = -1;
        }
        select(i);
    }

    function toggleMark(item) {
        if (!item) return;
        var m = Object.assign({}, marked);
        if (m[item.path]) delete m[item.path];
        else m[item.path] = true;
        marked = m;
    }

    function markRange(from, to) {
        var m = Object.assign({}, marked);
        for (var i = Math.min(from, to); i <= Math.max(from, to); i++) m[items[i].path] = true;
        marked = m;
    }

    function markAll() {
        var m = {};
        for (var i = 0; i < items.length; i++) m[items[i].path] = true;
        marked = m;
    }

    // What an action applies to: the marked items, or else the selected one
    function targets() {
        if (markedCount > 0) return items.filter(it => marked[it.path]);
        return selectedItem ? [selectedItem] : [];
    }

    function countLabel(list) {
        return list.length === 1 ? (list[0].name || baseName(list[0])) : list.length + " items";
    }

    // ---- Files ------------------------------------------------------------

    readonly property var kinds: {
        var k = {};
        var add = (kind, list) => list.split(" ").forEach(s => k[s] = kind);
        add("image", "png jpg jpeg gif webp bmp svg ico tif tiff avif jxl");
        add("video", "mp4 mkv webm mov avi m4v wmv flv mpg mpeg ogv 3gp");
        add("audio", "mp3 flac ogg oga opus wav m4a aac wma aiff mid midi");
        add("pdf", "pdf");
        add("doc", "txt md markdown rst org tex log csv tsv rtf odt doc docx ods xls xlsx odp ppt pptx ini conf cfg");
        add("code", "c h cc cpp hpp cs java kt py js mjs ts tsx jsx qml lua sh bash fish zsh rs go rb php html htm css scss json jsonc toml yaml yml xml sql zig nix vim glsl hlsl shader cmake mk");
        add("archive", "zip tar gz tgz xz bz2 zst 7z rar lz4 deb rpm iso img pkg");
        add("book", "epub mobi azw3 djvu cbz cbr");
        add("app", "appimage exe msi apk bin run x86_64 desktop");
        return k;
    }

    // What "Extract Here" can open (bsdtar, plus single compressed files)
    readonly property var extractable: ["zip", "tar", "gz", "tgz", "xz", "bz2", "zst", "7z", "rar", "lz4", "deb", "rpm", "iso", "cbz", "cbr", "tbz2", "txz"]

    function kindOf(name, suffix, isDir) {
        if (isDir) return "dir";
        if (kinds[suffix]) return kinds[suffix];
        var lower = name.toLowerCase();
        if (lower === "makefile" || lower === "dockerfile" || lower === "pkgbuild") return "code";
        if (lower.indexOf("readme") === 0 || lower === "license") return "doc";
        return "other";
    }

    function artFor(item) {
        if (!item) return "pouch";
        return ({
            dir: "chest", image: "picture", video: "film", audio: "ocarina", pdf: "book",
            doc: "scroll", code: "slate", archive: "crate", book: "book", app: "rupee"
        })[item.kind] || "pouch";
    }

    function typeLabel(item, count) {
        if (item.isDir) return "Folder · " + (count === 1 ? "1 item" : count + " items");
        var ext = item.suffix.toUpperCase();
        var name = ({
            image: ext + " image", video: ext + " video", audio: ext + " audio", pdf: "PDF document",
            doc: ext ? ext + " document" : "Document", code: ext ? ext + " source" : "Source",
            archive: ext + " archive", book: ext + " book", app: "Program"
        })[item.kind] || (ext ? ext + " file" : "File");
        return name + " · " + humanSize(item.size);
    }

    // A line in the voice of the game's item descriptions
    function flavor(item) {
        if (inTrashRoot) return "Discarded, but not gone yet. It can still be restored.";
        return ({
            dir: "A sturdy chest. Open it to see what's stored inside.",
            image: "A picture, kept safe so it can be admired again.",
            video: "A captured memory. Play it to relive the moment.",
            audio: "A melody waiting to be played.",
            pdf: "A bound tome. Its pages are full of knowledge.",
            doc: "A scroll covered in handwritten notes.",
            code: "Sheikah instructions. A Slate knows how to read them.",
            archive: "A crate packed tight. Unpack it to reach what's inside.",
            book: "A well-worn book with a bookmark still in it.",
            app: "A curious device. Who knows what it does when run?"
        })[item.kind] || "Something picked up along the way. Its use is unclear.";
    }

    // Label/value pairs for the description card
    function facts(item, origin, discarded, perms, dirSize) {
        if (inTrashRoot) {
            var f = ["Was in", origin || "Unknown", "Discarded", discarded || "Unknown"];
            if (!item.isDir) f.push("Size", humanSize(item.size));
            return f;
        }
        var out = ["Modified", formatDate(item.modified)];
        if (item.isDir) {
            if (dirSize !== "") out.push("Size", dirSize === "…" ? "Counting…" : dirSize);
        } else {
            out.push("Size", humanSize(item.size));
        }
        out.push("Location", prettyPath(parentOf(item.path)));
        if (perms !== "") out.push("Access", perms);
        return out;
    }

    function humanSize(bytes) {
        if (bytes < 1024) return bytes + " B";
        var units = ["KB", "MB", "GB", "TB"];
        var v = bytes;
        var u = -1;
        do {
            v /= 1024;
            u++;
        } while (v >= 1024 && u < units.length - 1);
        return v.toFixed(v < 10 ? 1 : 0) + " " + units[u];
    }

    function formatDate(d) {
        if (!d || isNaN(d.getTime())) return "Unknown";
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        var day = new Date(d.getTime());
        day.setHours(0, 0, 0, 0);
        var diff = Math.round((today - day) / 86400000);
        var time = Qt.formatTime(d, "HH:mm");
        if (diff === 0) return "Today, " + time;
        if (diff === 1) return "Yesterday, " + time;
        return Qt.formatDate(d, "d MMM yyyy") + ", " + time;
    }

    function prettyPath(p) {
        return p === home || p.indexOf(home + "/") === 0 ? "~" + p.slice(home.length) : p;
    }

    function parentOf(p) {
        return p.replace(/\/[^\/]*$/, "") || "/";
    }

    function baseName(p) {
        return p.replace(/^.*\//, "");
    }

    function fileUrl(p) {
        return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    function dragUris(item) {
        var list = marked[item.path] ? targets() : [item];
        return list.map(it => fileUrl(it.path)).join("\r\n") + "\r\n";
    }

    // Open a folder, or the folder a file is in with that file selected
    function reveal(target, isFile) {
        if (!isFile) {
            go(target);
            return;
        }
        pendingSelect = target;
        go(parentOf(target));
        restoreSelection();
    }

    function openItem(item) {
        if (!item) return;
        if (item.isDir) {
            go(item.path);
            return;
        }
        Quickshell.execDetached(["xdg-open", item.path]);
        toast("Opening " + item.name);
    }

    // ---- Thumbnails -------------------------------------------------------

    property var thumbs: ({})           // file name in thumbDir -> "ready" | "none" | "pending"
    property int thumbsRev: 0
    property bool thumbsReady: false
    property var thumbQueue: []

    function thumbName(item) {
        return Qt.md5(item.path + "|" + item.modified.getTime() + "|" + item.size) + ".png";
    }

    function thumbState(name) {
        thumbsRev;
        if (!thumbsReady) return "wait";
        return thumbs[name] || "missing";
    }

    function requestThumb(item, name) {
        if (!thumbsReady || thumbs[name] !== undefined) return;
        thumbs[name] = "pending";
        thumbQueue.push({ src: item.path, name: name, kind: item.kind });
        pumpThumbs();
    }

    function pumpThumbs() {
        for (var i = 0; i < thumbWorkers.count; i++) {
            var w = thumbWorkers.objectAt(i);
            // Newest first: those are the slots on screen now
            if (w && !w.running && thumbQueue.length > 0) w.start(thumbQueue.pop());
        }
    }

    function thumbDone(name, ok) {
        thumbs[name] = ok ? "ready" : "none";
        thumbsRev++;
        pumpThumbs();
    }

    Process {
        id: thumbIndex
        running: true
        command: ["sh", "-c", "mkdir -p \"$1\" && ls -1 \"$1\"", "sh", inv.thumbDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var map = {};
                text.split("\n").forEach(l => {
                    if (l.endsWith(".png.none")) map[l.slice(0, -5)] = "none";
                    else if (l.endsWith(".png")) map[l] = "ready";
                });
                inv.thumbs = map;
                inv.thumbsReady = true;
                inv.thumbsRev++;
            }
        }
    }

    Instantiator {
        id: thumbWorkers
        model: 3

        Process {
            property var job: null

            function start(j) {
                job = j;
                command = [inv.ops, "thumb", j.src, inv.thumbDir + "/" + j.name, j.kind];
                running = true;
            }

            onExited: (code) => {
                var done = job;
                job = null;
                if (done) Qt.callLater(() => inv.thumbDone(done.name, code === 0));
            }
        }
    }

    // ---- File operations --------------------------------------------------

    property var opQueue: []
    property var clip: ({ mode: "", paths: [] })

    // args go to inventory-ops.sh; success is the message to show; after(stdout) runs on success
    function runOp(args, success, after) {
        opQueue = opQueue.concat([{ args: args, success: success, after: after }]);
        if (!opProc.running && opProc.job === null) nextOp();
    }

    function nextOp() {
        if (opQueue.length === 0) return;
        opProc.job = opQueue[0];
        opQueue = opQueue.slice(1);
        opProc.command = [ops].concat(opProc.job.args);
        opProc.running = true;
    }

    Process {
        id: opProc
        property var job: null
        stdout: StdioCollector { id: opOut }
        stderr: StdioCollector { id: opErr }

        onExited: (code) => {
            var job = opProc.job;
            Qt.callLater(() => {
                // Partial results still count (and can be undone)
                if (job.after && (code === 0 || opOut.text.trim() !== "")) job.after(opOut.text);
                if (code === 0) {
                    if (job.success) inv.toast(job.success);
                } else {
                    var lines = opErr.text.trim().split("\n");
                    inv.toast(lines[lines.length - 1] || "That didn't work", true);
                }
                inv.refreshSpace();
                opProc.job = null;
                inv.nextOp();
            });
        }
    }

    function outLines(out) {
        return out.split("\n").filter(l => l !== "");
    }

    // ---- Undo (Ctrl+Z) ----------------------------------------------------

    property var undoStack: []          // [{ label, run }]

    function pushUndo(label, run) {
        undoStack = undoStack.concat([{ label: label, run: run }]).slice(-40);
    }

    function undo() {
        if (undoStack.length === 0) {
            toast("Nothing to undo");
            return;
        }
        var last = undoStack[undoStack.length - 1];
        undoStack = undoStack.slice(0, -1);
        last.run();
    }

    // Lines of "mode<tab>src<tab>target" from paste and rename-many
    function rememberTransfer(out, label) {
        var moves = [];
        var made = [];
        outLines(out).forEach(l => {
            var f = l.split("\t");
            if (f.length < 3) return;
            if (f[0] === "move") moves.push(f[2] + "\t" + f[1]);
            else made.push(f[2]);
        });
        if (moves.length > 0) pushUndo(label, () => runOp(["move-back"].concat(moves), "Put back " + (moves.length === 1 ? baseName(moves[0].split("\t")[1]) : moves.length + " items")));
        if (made.length > 0) rememberMade(made, label);
        var first = outLines(out)[0];
        if (first && first.split("\t").length >= 3) pendingSelect = first.split("\t")[2];
    }

    // Undoing a copy, a new folder, an extraction... moves what was made to the Trash
    function rememberMade(paths, label) {
        pushUndo(label, () => runOp(["trash"].concat(paths), "Undone: " + (paths.length === 1 ? baseName(paths[0]) : paths.length + " items") + " went to the Trash"));
    }

    // ---- Copy, move, trash, rename ---------------------------------------

    function transfer(mode, dir, paths) {
        var verb = ({ move: "Moved", copy: "Copied", link: "Linked" })[mode];
        var what = paths.length === 1 ? baseName(paths[0]) : paths.length + " items";
        var where = dir === path ? "here" : "to " + baseName(dir);
        runOp(["paste", mode, dir].concat(paths), verb + " " + what + " " + where,
            (out) => rememberTransfer(out, verb.toLowerCase() + " " + what));
    }

    function copyTargets(cut) {
        var list = targets();
        if (list.length === 0) return;
        var uris = list.map(it => fileUrl(it.path)).join("\r\n") + "\r\n";
        Quickshell.execDetached(["wl-copy", "--type", "text/uri-list", uris]);
        clip = { mode: cut ? "move" : "copy", paths: list.map(it => it.path) };
        toast((cut ? "Cut " : "Copied ") + countLabel(list));
    }

    function copyPath() {
        var list = targets();
        if (list.length === 0) return;
        Quickshell.execDetached(["wl-copy", list.map(it => it.path).join("\n")]);
        toast("Copied the path" + (list.length > 1 ? "s" : ""));
    }

    function paste() {
        if (inTrash) return;
        if (clip.mode === "move" && clip.paths.length > 0) {
            var paths = clip.paths;
            clip = { mode: "", paths: [] };
            transfer("move", path, paths);
        } else {
            runOp(["paste-clipboard", path], "Pasted", (out) => rememberTransfer(out, "paste"));
        }
    }

    function duplicate() {
        var list = targets();
        if (list.length === 0 || inTrash) return;
        // Each copy lands next to its original, even in search results
        var byDir = {};
        list.forEach(it => {
            var d = parentOf(it.path);
            (byDir[d] = byDir[d] || []).push(it.path);
        });
        for (var d in byDir) {
            runOp(["paste", "copy", d].concat(byDir[d]), "Duplicated " + countLabel(list),
                (out) => rememberTransfer(out, "duplicate"));
        }
    }

    function trashPaths(paths, noUndo) {
        if (paths.length === 0) return;
        var what = paths.length === 1 ? baseName(paths[0]) : paths.length + " items";
        runOp(["trash"].concat(paths), "Moved " + what + " to the Trash", (out) => {
            marked = ({});
            var names = outLines(out);
            if (names.length > 0 && !noUndo) pushUndo("trash " + what, () => runOp(["restore"].concat(names), "Restored " + what));
        });
    }

    function trashTargets() {
        var list = targets();
        if (list.length === 0) return;
        if (inTrashRoot) {
            purgeTargets();
            return;
        }
        if (inTrash) return;
        trashPaths(list.map(it => it.path));
    }

    function restoreTargets() {
        var list = targets();
        if (!inTrashRoot || list.length === 0) return;
        runOp(["restore"].concat(list.map(it => it.name)), "Restored " + countLabel(list), (out) => {
            marked = ({});
            var back = outLines(out);
            if (back.length > 0) pushUndo("restore", () => trashPaths(back, true));
        });
    }

    function purgeTargets() {
        var list = targets();
        if (!inTrashRoot || list.length === 0) return;
        dialog.ask({
            title: "Delete Forever",
            message: (list.length === 1 ? list[0].name + " is" : list.length + " items are") + " gone for good after this.",
            acceptLabel: "Delete",
            danger: true,
            accept: () => runOp(["purge"].concat(list.map(it => it.name)), "Deleted " + countLabel(list), () => marked = ({}))
        });
    }

    function emptyTrash() {
        dialog.ask({
            title: "Empty Trash",
            message: "Everything in the Trash is gone for good after this.",
            acceptLabel: "Empty",
            danger: true,
            accept: () => runOp(["empty-trash"], "The Trash is empty")
        });
    }

    function rename() {
        if (inTrash) return;
        if (markedCount > 1) {
            renameMany();
            return;
        }
        var item = selectedItem;
        if (!item) return;
        var dot = item.isDir ? -1 : item.name.lastIndexOf(".");
        dialog.ask({
            title: "Rename",
            text: item.name,
            select: dot > 0 ? dot : item.name.length,
            acceptLabel: "Rename",
            accept: (name) => {
                if (name === item.name) return;
                runOp(["rename", item.path, name], "Renamed to " + name, (out) => {
                    var renamed = out.trim();
                    pendingSelect = renamed;
                    pushUndo("rename", () => runOp(["move-back", renamed + "\t" + item.path], "Named " + item.name + " again"));
                });
            }
        });
    }

    // Several at once: "#" becomes 1, 2, 3... in the order they're shown
    function renameMany() {
        var list = targets();
        dialog.ask({
            title: "Rename " + list.length + " Items",
            message: "# becomes 1, 2, 3… Each file keeps its extension.",
            text: "Item #",
            select: 4,
            acceptLabel: "Rename",
            accept: (pattern) => runOp(["rename-many", pattern].concat(list.map(it => it.path)), "Renamed " + list.length + " items",
                (out) => rememberTransfer(out, "rename"))
        });
    }

    function newFolder() {
        if (inTrash) return;
        dialog.ask({
            title: "New Folder",
            text: "New folder",
            acceptLabel: "Create",
            accept: (name) => runOp(["mkdir", path, name], "Made " + name, (out) => {
                pendingSelect = out.trim();
                rememberMade([out.trim()], "new folder");
            })
        });
    }

    function newFile() {
        if (inTrash) return;
        dialog.ask({
            title: "New File",
            text: "New file.txt",
            select: 8,
            acceptLabel: "Create",
            accept: (name) => runOp(["touch", path, name], "Made " + name, (out) => {
                pendingSelect = out.trim();
                rememberMade([out.trim()], "new file");
            })
        });
    }

    // ---- Archives ---------------------------------------------------------

    function canExtract(item) {
        return item && !item.isDir && extractable.indexOf(item.suffix) >= 0;
    }

    function extractTargets() {
        var list = targets().filter(it => canExtract(it));
        if (list.length === 0 || inTrash) return;
        toast("Unpacking " + countLabel(list) + "…");
        var dir = parentOf(list[0].path);
        runOp(["extract", dir].concat(list.map(it => it.path)), "Unpacked " + countLabel(list), (out) => {
            var made = outLines(out);
            if (made.length === 0) return;
            pendingSelect = made[0];
            rememberMade(made, "extract");
        });
    }

    function compressTargets(fmt) {
        var list = targets();
        if (list.length === 0 || inTrash) return;
        toast("Packing " + countLabel(list) + "…");
        runOp(["compress", fmt, path].concat(list.map(it => it.path)), "", (out) => {
            var made = out.trim();
            if (made === "") return;
            toast("Packed into " + baseName(made));
            pendingSelect = made;
            rememberMade([made], "compress");
        });
    }

    // ---- Open with --------------------------------------------------------

    function launchWith(id, paths) {
        if (!id.endsWith(".desktop")) id += ".desktop";
        Quickshell.execDetached([ops, "launch", id].concat(paths));
    }

    function entryFor(id) {
        return DesktopEntries.byId(id) || DesktopEntries.byId(id.replace(/\.desktop$/, ""));
    }

    function openWithMenu(x, y) {
        var list = targets().filter(it => !it.isDir);
        if (list.length === 0) return;
        appsProc.paths = list.map(it => it.path);
        appsProc.at = Qt.point(x, y);
        appsProc.exec([ops, "apps", list[0].path]);
    }

    function pickApp(paths) {
        picker.ask(paths.length === 1 ? baseName(paths[0]) : paths.length + " files", (app) => launchWith(app.id, paths));
    }

    Process {
        id: appsProc
        property var paths: []
        property point at
        stdout: StdioCollector {
            onStreamFinished: {
                var paths = appsProc.paths;
                var list = [];
                inv.outLines(text).forEach(l => {
                    var f = l.split("\t");
                    var entry = inv.entryFor(f[1]);
                    list.push({
                        title: entry ? entry.name : f[1].replace(/\.desktop$/, ""),
                        iconSource: entry ? Quickshell.iconPath(entry.icon, "application-x-executable") : "",
                        glyph: "apps",
                        hint: f[0] === "D" ? "Default" : "",
                        action: () => inv.launchWith(f[1], paths)
                    });
                });
                if (list.length > 0) list.push({ separator: true });
                list.push({ title: "Other Application…", glyph: "apps", hint: "", action: () => inv.pickApp(paths) });
                menu.show(list, appsProc.at.x, appsProc.at.y);
            }
        }
    }

    // ---- Drag and drop ----------------------------------------------------

    function urlsToPaths(urls) {
        var out = [];
        for (var i = 0; i < urls.length; i++) {
            var s = urls[i].toString();
            if (s.indexOf("file://") !== 0) continue;
            var raw = s.slice(7);
            try {
                out.push(decodeURIComponent(raw));
            } catch (e) {
                out.push(raw);
            }
        }
        return out;
    }

    // Dropping a folder into itself, or things where they already are, does nothing
    function droppable(dir, paths) {
        return paths.filter(p => p !== dir && dir.indexOf(p + "/") !== 0 && parentOf(p) !== dir);
    }

    function canDropInto(dir, drag) {
        if (!drag.hasUrls) return false;
        if (dir !== trashDir && dir.indexOf(trashDir) === 0) return false;
        return droppable(dir, urlsToPaths(drag.urls)).length > 0;
    }

    // From inside the Inventory a drop moves (Ctrl: copies, Ctrl+Shift: links);
    // from other apps it asks, as Dolphin does
    function dropInto(dir, drop, x, y) {
        var paths = droppable(dir, urlsToPaths(drop.urls));
        if (paths.length === 0) return;
        if (dir === trashDir) {
            drop.accept(Qt.MoveAction);
            trashPaths(paths.filter(p => !inTrashPath(p)));
            return;
        }
        if (paths.some(p => inTrashPath(p))) {
            drop.accept(Qt.CopyAction);
            transfer("copy", dir, paths);
            return;
        }
        if (drop.source) {
            var mode = drop.proposedAction === Qt.CopyAction ? "copy" : (drop.proposedAction === Qt.LinkAction ? "link" : "move");
            drop.accept(mode === "copy" ? Qt.CopyAction : (mode === "link" ? Qt.LinkAction : Qt.MoveAction));
            transfer(mode, dir, paths);
            return;
        }
        drop.accept(Qt.CopyAction);
        menu.show([
            { title: "Move Here", glyph: "cut", hint: "", action: () => transfer("move", dir, paths) },
            { title: "Copy Here", glyph: "copy", hint: "", action: () => transfer("copy", dir, paths) },
            { title: "Link Here", glyph: "link", hint: "", action: () => transfer("link", dir, paths) },
            { separator: true },
            { title: "Cancel", glyph: "chevron-left", hint: "Esc", action: () => {} }
        ], x, y);
    }

    function inTrashPath(p) {
        return p === trashDir || p.indexOf(trashDir + "/") === 0;
    }

    // ---- Everything else ---------------------------------------------------

    function terminalHere(item) {
        var dir = item && item.isDir ? item.path : path;
        Quickshell.execDetached(["kitty", "--directory", dir]);
    }

    function dolphinHere(item) {
        if (item && !item.isDir) Quickshell.execDetached(["dolphin", "--select", item.path]);
        else Quickshell.execDetached(["dolphin", item ? item.path : path]);
    }

    function eject(place) {
        if (path === place.path || path.indexOf(place.path + "/") === 0) go(home);
        runOp(["eject", place.path], place.name + " can be removed now");
    }

    // ---- Free space (the rupee counter) -----------------------------------

    property real spaceTotal: 0
    property real spaceFree: 0

    function refreshSpace() {
        dfProc.command = [ops, "df", path];
        dfProc.running = true;
    }

    Process {
        id: dfProc
        stdout: StdioCollector {
            onStreamFinished: {
                var f = text.trim().split(/\s+/);
                if (f.length === 2) {
                    inv.spaceTotal = Number(f[0]);
                    inv.spaceFree = Number(f[1]);
                }
            }
        }
    }

    // ---- Messages ---------------------------------------------------------

    property string toastText: ""
    property bool toastError: false

    function toast(text, error) {
        toastText = text;
        toastError = error === true;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 3500
        onTriggered: inv.toastText = ""
    }

    // ---- Menus ------------------------------------------------------------

    function itemMenu(item, x, y) {
        var list = [];
        var many = markedCount > 1;
        if (inTrashRoot) {
            list.push({ title: "Restore", glyph: "restore", hint: "R", action: () => restoreTargets() });
            list.push({ separator: true });
            list.push({ title: "Delete Forever", glyph: "trash", hint: "Del", danger: true, action: () => purgeTargets() });
            menu.show(list, x, y);
            return;
        }
        list.push({ title: "Open", glyph: "open", hint: "⏎", action: () => openItem(item) });
        if (!item.isDir) list.push({ title: "Open With…", glyph: "apps", hint: "", action: () => openWithMenu(x, y) });
        if (!inTrash && targets().some(it => canExtract(it)))
            list.push({ title: "Extract Here", glyph: "unbox", hint: "", action: () => extractTargets() });
        list.push({ separator: true });
        list.push({ title: "Copy", glyph: "copy", hint: "Ctrl+C", action: () => copyTargets(false) });
        if (!inTrash) {
            list.push({ title: "Cut", glyph: "cut", hint: "Ctrl+X", action: () => copyTargets(true) });
            list.push({ title: "Duplicate", glyph: "copy", hint: "Ctrl+D", action: () => duplicate() });
            list.push({ title: many ? "Rename " + markedCount + " Items" : "Rename", glyph: "pen", hint: "F2", action: () => rename() });
            list.push({ title: "Compress…", glyph: "box", hint: "", action: () => menu.show([
                { title: "As .zip", glyph: "box", hint: "", action: () => compressTargets("zip") },
                { title: "As .tar.gz", glyph: "box", hint: "", action: () => compressTargets("tar.gz") }
            ], x, y) });
        }
        list.push({ title: "Copy Path", glyph: "link", hint: "", action: () => copyPath() });
        list.push({ separator: true });
        list.push({ title: "Terminal Here", glyph: "terminal", hint: "F4", action: () => terminalHere(item) });
        list.push({ title: "Open in Dolphin", glyph: "folder", hint: "D", action: () => dolphinHere(item) });
        if (!inTrash) {
            list.push({ separator: true });
            list.push({ title: "Move to Trash", glyph: "trash", hint: "Del", danger: true, action: () => trashTargets() });
        }
        menu.show(list, x, y);
    }

    function folderMenu(x, y) {
        var list = [];
        if (inTrashRoot) {
            list.push({ title: "Empty Trash", glyph: "trash", hint: "", danger: true, action: () => emptyTrash() });
        } else if (!inTrash) {
            list.push({ title: "New Folder", glyph: "folder-plus", hint: "Ctrl+Shift+N", action: () => newFolder() });
            list.push({ title: "New File", glyph: "file-plus", hint: "", action: () => newFile() });
            list.push({ title: "Paste", glyph: "paste", hint: "Ctrl+V", action: () => paste() });
        }
        if (undoStack.length > 0)
            list.push({ title: "Undo " + undoStack[undoStack.length - 1].label, glyph: "undo", hint: "Ctrl+Z", action: () => undo() });
        list.push({ separator: true });
        list.push({ title: "Select All", glyph: "select-all", hint: "Ctrl+A", action: () => markAll() });
        list.push({ title: showHidden ? "Hide Hidden Files" : "Show Hidden Files", glyph: "eye", hint: "H", action: () => showHidden = !showHidden });
        list.push({ title: "Go To…", glyph: "goto", hint: "Ctrl+L", action: () => goToPrompt() });
        list.push({ separator: true });
        list.push({ title: "Terminal Here", glyph: "terminal", hint: "F4", action: () => terminalHere(null) });
        list.push({ title: "Open in Dolphin", glyph: "folder", hint: "D", action: () => dolphinHere(null) });
        menu.show(list, x, y);
    }

    function tabMenu(index, x, y) {
        var place = places[index];
        var list = [{ title: "Open", glyph: "open", hint: "", action: () => go(place.path) }];
        if (place.drive) list.push({ title: "Eject " + place.name, glyph: "eject", hint: "", action: () => eject(place) });
        if (place.path === trashDir) list.push({ title: "Empty Trash", glyph: "trash", hint: "", danger: true, action: () => emptyTrash() });
        list.push({ title: "Open in Dolphin", glyph: "folder", hint: "", action: () => Quickshell.execDetached(["dolphin", place.path]) });
        menu.show(list, x, y);
    }

    // ---- Keys -------------------------------------------------------------

    focus: true

    Keys.onPressed: (event) => {
        var ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        var shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        var alt = (event.modifiers & Qt.AltModifier) !== 0;
        event.accepted = true;

        if (menu.open) {
            if (event.key === Qt.Key_Up) menu.move(-1);
            else if (event.key === Qt.Key_Down) menu.move(1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) menu.activate(menu.hovered);
            else menu.close();
            return;
        }

        if (alt && event.key === Qt.Key_Left) back();
        else if (alt && event.key === Qt.Key_Right) forward();
        else if (alt && event.key === Qt.Key_Up) up();
        else if (ctrl && shift && event.key === Qt.Key_N) newFolder();
        else if (ctrl && event.key === Qt.Key_Z) undo();
        else if (ctrl && event.key === Qt.Key_C) copyTargets(false);
        else if (ctrl && event.key === Qt.Key_X) copyTargets(true);
        else if (ctrl && event.key === Qt.Key_V) paste();
        else if (ctrl && event.key === Qt.Key_D) duplicate();
        else if (ctrl && event.key === Qt.Key_A) markAll();
        else if (ctrl && event.key === Qt.Key_H) showHidden = !showHidden;
        else if (ctrl && event.key === Qt.Key_F) openSearch();
        else if (ctrl && event.key === Qt.Key_L) goToPrompt();
        else if (ctrl && (event.key === Qt.Key_Equal || event.key === Qt.Key_Plus)) zoomBy(1);
        else if (ctrl && event.key === Qt.Key_Minus) zoomBy(-1);
        else if (ctrl && event.key === Qt.Key_0) zoom = 1;
        else if (ctrl && (event.key === Qt.Key_W || event.key === Qt.Key_Q)) inv.closeRequested();
        else if (ctrl && event.key === Qt.Key_PageUp) stepPlace(-1);
        else if (ctrl && event.key === Qt.Key_PageDown) stepPlace(1);
        else if (ctrl || alt) event.accepted = false;
        else if (event.key === Qt.Key_Left) moveSelection(-1, shift);
        else if (event.key === Qt.Key_Right) moveSelection(1, shift);
        else if (event.key === Qt.Key_Up) moveSelection(-grid.columns, shift);
        else if (event.key === Qt.Key_Down) moveSelection(grid.columns, shift);
        else if (event.key === Qt.Key_Home) select(0);
        else if (event.key === Qt.Key_End) select(items.length - 1);
        else if (event.key === Qt.Key_PageUp) moveSelection(-grid.columns * grid.visibleRows, shift);
        else if (event.key === Qt.Key_PageDown) select(Math.min(items.length - 1, selectedIndex + grid.columns * grid.visibleRows));
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) openItem(selectedItem);
        else if (event.key === Qt.Key_Backspace) up();
        else if (event.key === Qt.Key_Space) toggleMark(selectedItem);
        else if (event.key === Qt.Key_Delete && shift) { if (inTrashRoot) purgeTargets(); }
        else if (event.key === Qt.Key_Delete) trashTargets();
        else if (event.key === Qt.Key_F2) rename();
        else if (event.key === Qt.Key_F4) terminalHere(null);
        else if (event.key === Qt.Key_F5) { rebuild(); refreshSpace(); }
        else if (event.key === Qt.Key_Q) stepPlace(-1);
        else if (event.key === Qt.Key_E) stepPlace(1);
        else if (event.key === Qt.Key_H) showHidden = !showHidden;
        else if (event.key === Qt.Key_R) restoreTargets();
        else if (event.key === Qt.Key_T) terminalHere(null);
        else if (event.key === Qt.Key_D) dolphinHere(null);
        else if (event.key === Qt.Key_Slash) openSearch();
        else if (event.key === Qt.Key_Menu || (shift && event.key === Qt.Key_F10)) {
            var cell = grid.itemAtIndex(selectedIndex);
            if (selectedItem && cell) {
                var at = cell.mapToItem(inv, cell.width / 2, cell.height / 2);
                itemMenu(selectedItem, at.x, at.y);
            } else {
                folderMenu(gridArea.x + 40, gridArea.y + 40);
            }
        }
        else if (event.key === Qt.Key_Escape) {
            if (query !== "" || searchOpen || deepQuery !== "") closeSearch();
            else if (markedCount > 0) marked = ({});
            else inv.closeRequested();
        }
        else event.accepted = false;
    }

    function openSearch() {
        searchOpen = true;
        searchField.forceActiveFocus();
        searchField.selectAll();
    }

    function closeSearch() {
        endDeepSearch();
        query = "";
        searchOpen = false;
        rebuild();
        inv.forceActiveFocus();
    }

    // Mouse back/forward buttons
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onPressed: (mouse) => {
            if (mouse.button === Qt.BackButton) inv.back();
            else inv.forward();
        }
    }

    Component.onCompleted: refreshSpace()

    // ---- Layout -----------------------------------------------------------

    // The window tiles like any other, so the layout follows its size: the
    // details pane goes first when it gets narrow, then tabs shrink and the
    // less important prompts drop out
    readonly property int pad: width < 700 ? 18 : 28
    readonly property bool showDetails: width >= 900
    readonly property int detailsWidth: showDetails ? Math.round(Math.max(320, Math.min(420, width * 0.3))) : 0
    readonly property bool narrow: width < 820
    readonly property int promptRoom: Math.max(2, Math.min(6, Math.floor((width - 230) / 105)))
    readonly property real wheelRows: 1.5   // how far one wheel notch scrolls, in rows of slots

    Rectangle {
        anchors.fill: parent
        color: Theme.invBackdrop
    }

    // Darker toward top and bottom, as the game dims the world behind its menu
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#66000000" }
            GradientStop { position: 0.25; color: "#00000000" }
            GradientStop { position: 0.75; color: "#00000000" }
            GradientStop { position: 1.0; color: "#73000000" }
        }
    }

    InvTabs {
        id: tabs
        x: inv.pad
        y: 12
        places: inv.places
        current: inv.placeIndex
        view: inv
        tabSize: inv.narrow ? 32 : 40
        tabGap: inv.narrow ? 5 : 10
        onPicked: (i) => inv.go(inv.places[i].path)
        onStep: (d) => inv.stepPlace(d)
        onMenuRequested: (i, x, y) => inv.tabMenu(i, x + tabs.x, y + tabs.y)
    }

    // Rupee counter: free space where we are
    Row {
        anchors.right: parent.right
        anchors.rightMargin: inv.pad + 4
        y: tabs.y + tabs.bubbleHeight + 8 + 9
        spacing: 8
        visible: inv.spaceTotal > 0 && inv.width - tabs.width - inv.pad * 2 > 190

        ItemArt {
            width: 30
            height: 30
            kind: "rupee"
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: inv.humanSize(inv.spaceFree)
                font.family: Theme.fontDisplay
                font.pixelSize: 20
                font.bold: true
                color: Theme.hudText
                style: Text.Outline
                styleColor: "#99000000"
            }

            Text {
                text: "free of " + inv.humanSize(inv.spaceTotal)
                font.family: Theme.fontUi
                font.pixelSize: 10
                color: Theme.hudTextDim
            }
        }
    }

    // Where we are, and the search box
    Item {
        id: locationRow
        x: inv.pad
        y: tabs.y + tabs.height + 14
        width: gridArea.width
        height: 30

        Row {
            id: crumbRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            width: Math.min(implicitWidth, parent.width - infoRow.width - (searchBox.visible ? searchBox.width + 16 : 0) - 16)
            clip: true

            Repeater {
                // Deep paths keep their last few folders behind a "…"
                model: inv.crumbs.length > 5
                    ? [{ label: "…", path: inv.crumbs[inv.crumbs.length - 5].path }].concat(inv.crumbs.slice(-4))
                    : inv.crumbs

                Row {
                    id: crumb
                    required property var modelData
                    required property int index
                    readonly property bool last: index === Math.min(inv.crumbs.length, 5) - 1
                    spacing: 8

                    Glyph {
                        visible: crumb.index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron-right"
                        size: 11
                        color: Theme.hudTextDim
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: crumb.modelData.label
                        font.family: Theme.fontDisplay
                        font.pixelSize: crumb.last ? 18 : 15
                        font.bold: crumb.last
                        color: crumbDrop.containsDrag ? Theme.sheikah
                            : crumb.last ? Theme.hudText : (crumbArea.containsMouse ? Theme.hudText : Theme.hudTextDim)
                        style: Text.Raised
                        styleColor: "#80000000"

                        MouseArea {
                            id: crumbArea
                            anchors.fill: parent
                            enabled: !crumb.last || inv.deepQuery !== ""
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: inv.go(crumb.modelData.path)
                        }

                        // Drop on a parent folder's name to move things up into it
                        DropArea {
                            id: crumbDrop
                            anchors.fill: parent
                            anchors.margins: -4
                            onEntered: (drag) => {
                                if (!inv.canDropInto(crumb.modelData.path, drag)) drag.accepted = false;
                            }
                            onDropped: (drop) => {
                                var at = crumbDrop.mapToItem(inv, drop.x, drop.y);
                                inv.dropInto(crumb.modelData.path, drop, at.x, at.y);
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: infoRow
            anchors.right: searchBox.visible ? searchBox.left : parent.right
            anchors.rightMargin: searchBox.visible ? 16 : 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var parts = [];
                    if (inv.searching) parts.push("Searching subfolders…");
                    else if (inv.deepQuery !== "") parts.push((inv.items.length >= 2000 ? "2000+" : inv.items.length) + " found below");
                    else parts.push(inv.items.length === 1 ? "1 item" : inv.items.length + " items");
                    if (inv.markedCount > 0) parts.push(inv.markedCount + " marked");
                    if (inv.showHidden) parts.push("hidden shown");
                    return parts.join("  ·  ");
                }
                font.family: Theme.fontUi
                font.pixelSize: 11
                color: Theme.hudTextDim
            }

            // Sort toggle: by name, or newest first
            Rectangle {
                id: sortButton
                readonly property bool byTime: inv.sortMode === 1
                readonly property bool hot: sortArea.containsMouse

                anchors.verticalCenter: parent.verticalCenter
                width: sortRow.implicitWidth + 24
                height: 26
                radius: height / 2
                color: hot ? "#f21c1d19" : Theme.invSlot
                border.width: 1
                border.color: hot ? Theme.invGold : Theme.invSlotBorder
                Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                Row {
                    id: sortRow
                    anchors.centerIn: parent
                    spacing: 7

                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        name: sortButton.byTime ? "clock" : "sort-az"
                        size: 14
                        color: sortButton.hot ? Theme.invGold : Theme.hudText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: sortButton.byTime ? "Newest" : "Name"
                        font.family: Theme.fontDisplay
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.hudText
                    }
                }

                MouseArea {
                    id: sortArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: inv.toggleSort()
                }
            }
        }

        Rectangle {
            id: searchBox
            visible: inv.searchOpen || inv.query !== "" || inv.deepQuery !== ""
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(280, parent.width * 0.4)
            height: 30
            radius: 15
            color: Theme.invSlot
            border.width: searchField.activeFocus || inv.deepQuery !== "" ? 2 : 1
            border.color: inv.deepQuery !== "" ? Theme.sheikah : (searchField.activeFocus ? Theme.invGold : Theme.invSlotBorder)

            Glyph {
                id: searchGlyph
                anchors.left: parent.left
                anchors.leftMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                size: 14
                color: inv.deepQuery !== "" ? Theme.sheikah : Theme.hudTextDim
            }

            TextInput {
                id: searchField
                anchors.left: searchGlyph.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                font.family: Theme.fontDisplay
                font.pixelSize: 14
                color: Theme.hudText
                selectionColor: "#664fd2ff"
                text: inv.query
                // Typing filters this folder; ⏎ searches everything below it
                onTextEdited: {
                    inv.endDeepSearch();
                    inv.query = text;
                }
                Keys.onEscapePressed: inv.closeSearch()
                Keys.onReturnPressed: {
                    inv.deepSearch();
                    inv.forceActiveFocus();
                }
                Keys.onEnterPressed: {
                    inv.deepSearch();
                    inv.forceActiveFocus();
                }
                Keys.onDownPressed: inv.forceActiveFocus()

                Text {
                    visible: searchField.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    elide: Text.ElideRight
                    text: "Filter · ⏎ searches subfolders"
                    font: searchField.font
                    color: Theme.hudTextDim
                    opacity: 0.6
                }
            }
        }
    }

    // The slot grid
    Item {
        id: gridArea
        x: inv.pad - 8
        y: locationRow.y + locationRow.height + 8
        width: parent.width - inv.pad * 2 + 8 - (inv.showDetails ? inv.detailsWidth + 28 : 0)
        height: band.y - y - 16

        function scrollBy(dy, animate) {
            var maxY = grid.originY + Math.max(0, grid.contentHeight - grid.height);
            var from = scrollAnim.running ? scrollAnim.to : grid.contentY;
            var to = Math.max(grid.originY, Math.min(maxY, from + dy));
            scrollAnim.stop();
            if (animate) {
                scrollAnim.from = grid.contentY;
                scrollAnim.to = to;
                scrollAnim.start();
            } else {
                grid.contentY = to;
            }
        }

        NumberAnimation {
            id: scrollAnim
            target: grid
            property: "contentY"
            duration: 180
            easing.type: Easing.OutCubic
        }

        // Empty space: click clears the marks, drag draws a selection box,
        // right-click opens the folder menu. It also takes the wheel for the
        // whole grid, as the slots let it through: wheel scrolls, Ctrl+wheel
        // zooms. (A WheelHandler would miss wheels Qt doesn't class as a mouse.)
        MouseArea {
            id: bandArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property point start                // in grid content coordinates
            property bool banding: false
            property var baseMarks: ({})
            property real lastX: 0
            property real lastY: 0
            property real zoomAccum: 0

            onWheel: (wheel) => {
                if (wheel.modifiers & Qt.ControlModifier) {
                    zoomAccum += wheel.angleDelta.y;
                    if (Math.abs(zoomAccum) >= 120) {
                        inv.zoomBy(zoomAccum > 0 ? 1 : -1);
                        zoomAccum = 0;
                    }
                } else {
                    // 120 is one notch; touchpads and smooth wheels send less, and follow directly
                    var notches = wheel.angleDelta.y / 120;
                    gridArea.scrollBy(-notches * grid.cellHeight * inv.wheelRows, Math.abs(notches) >= 1);
                }
            }

            function contentPoint(x, y) {
                return Qt.point(x - grid.x + grid.contentX, y - grid.y + grid.contentY);
            }

            function updateBand() {
                var now = contentPoint(lastX, lastY);
                var x1 = Math.min(start.x, now.x), x2 = Math.max(start.x, now.x);
                var y1 = Math.min(start.y, now.y), y2 = Math.max(start.y, now.y);
                var m = Object.assign({}, baseMarks);
                var box = grid.cellWidth - 14;
                for (var i = 0; i < inv.items.length; i++) {
                    var cx = (i % grid.columns) * grid.cellWidth + 7;
                    var cy = Math.floor(i / grid.columns) * grid.cellHeight + 4;
                    if (cx < x2 && cx + box > x1 && cy < y2 && cy + box > y1) m[inv.items[i].path] = true;
                }
                inv.marked = m;
            }

            onPressed: (mouse) => {
                inv.forceActiveFocus();
                if (mouse.button === Qt.RightButton) {
                    inv.folderMenu(mouse.x + gridArea.x, mouse.y + gridArea.y);
                    return;
                }
                start = contentPoint(mouse.x, mouse.y);
                lastX = mouse.x;
                lastY = mouse.y;
                banding = false;
                baseMarks = (mouse.modifiers & Qt.ControlModifier) ? Object.assign({}, inv.marked) : ({});
            }

            onPositionChanged: (mouse) => {
                lastX = mouse.x;
                lastY = mouse.y;
                if (!banding) {
                    var p = contentPoint(mouse.x, mouse.y);
                    if (Math.abs(p.x - start.x) + Math.abs(p.y - start.y) < 6) return;
                    banding = true;
                }
                updateBand();
            }

            onReleased: (mouse) => {
                if (!banding && mouse.button === Qt.LeftButton && !(mouse.modifiers & Qt.ControlModifier)) inv.marked = ({});
                banding = false;
            }

            // Keep going past the edge
            Timer {
                interval: 16
                repeat: true
                running: bandArea.banding && (bandArea.lastY < grid.y + 12 || bandArea.lastY > grid.y + grid.height - 12)
                onTriggered: {
                    gridArea.scrollBy(bandArea.lastY < grid.y + 12 ? -14 : 14, false);
                    bandArea.updateBand();
                }
            }
        }

        // Files dropped on empty space land in this folder
        DropArea {
            anchors.fill: parent
            onEntered: (drag) => {
                if (inv.deepQuery !== "" || !inv.canDropInto(inv.path, drag)) drag.accepted = false;
            }
            onDropped: (drop) => {
                inv.dropInto(inv.path, drop, drop.x + gridArea.x, drop.y + gridArea.y);
            }
        }

        GridView {
            id: grid
            anchors.fill: parent
            anchors.topMargin: 10
            anchors.rightMargin: 12
            clip: true
            focus: false
            // Scrolling is ours (see bandArea), so presses on empty space reach the selection box
            interactive: false
            keyNavigationEnabled: false
            cacheBuffer: 400

            readonly property int columns: Math.max(3, Math.floor(width / (128 * inv.zoom)))
            readonly property int visibleRows: Math.max(1, Math.floor(height / cellHeight))
            cellWidth: Math.floor(width / columns)
            cellHeight: cellWidth + 22

            // Pad with empty slots to fill the view and finish the last row, as the game does
            model: {
                if (cellHeight <= 0) return 0;
                var rows = Math.max(Math.ceil(inv.items.length / columns), Math.ceil(height / cellHeight));
                return rows * columns;
            }

            delegate: InvSlot {
                id: slotDelegate
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight
                view: inv
                item: index < inv.items.length ? inv.items[index] : null
                selected: filled && index === inv.selectedIndex
                marked: filled && inv.marked[item.path] === true
                cut: filled && inv.clip.mode === "move" && inv.clip.paths.indexOf(item.path) >= 0

                onPressed: (mouse) => {
                    inv.forceActiveFocus();
                    var ctrl = (mouse.modifiers & Qt.ControlModifier) !== 0;
                    var shift = (mouse.modifiers & Qt.ShiftModifier) !== 0;
                    if (mouse.button === Qt.RightButton) {
                        if (!marked) inv.marked = ({});
                        inv.select(index);
                        var at = slotDelegate.mapToItem(inv, mouse.x + 7, mouse.y + 4);
                        inv.itemMenu(item, at.x, at.y);
                    } else if (ctrl) {
                        inv.toggleMark(item);
                        inv.select(index);
                    } else if (shift && inv.selectedIndex >= 0) {
                        inv.markRange(inv.selectedIndex, index);
                        inv.select(index);
                    } else {
                        if (!marked) inv.marked = ({});
                        inv.anchorIndex = -1;
                        inv.select(index);
                    }
                }
                onDoubleClicked: inv.openItem(item)
            }
        }

        // Selection box
        Rectangle {
            visible: bandArea.banding
            readonly property point from: Qt.point(bandArea.start.x - grid.contentX + grid.x, bandArea.start.y - grid.contentY + grid.y)
            x: Math.min(from.x, bandArea.lastX)
            y: Math.min(from.y, bandArea.lastY)
            width: Math.abs(bandArea.lastX - from.x)
            height: Math.abs(bandArea.lastY - from.y)
            color: "#264fd2ff"
            border.width: 1
            border.color: Theme.sheikah
            radius: 2
        }

        // While dragging, holding near the top or bottom edge scrolls
        Repeater {
            model: [-1, 1]

            DropArea {
                id: edge
                required property int modelData
                anchors.left: parent.left
                anchors.right: parent.right
                y: modelData < 0 ? grid.y - 18 : grid.y + grid.height - 6
                height: 22
                onEntered: (drag) => {
                    if (!drag.hasUrls) drag.accepted = false;
                }
                onDropped: (drop) => {
                    if (inv.deepQuery === "" && inv.canDropInto(inv.path, drop)) inv.dropInto(inv.path, drop, drop.x + gridArea.x, edge.y + drop.y + gridArea.y);
                }

                Timer {
                    interval: 16
                    repeat: true
                    running: edge.containsDrag
                    onTriggered: gridArea.scrollBy(edge.modelData * 12, false)
                }
            }
        }

        // Scroll marker, a thin cream rail like the game's
        Rectangle {
            visible: Math.ceil(inv.items.length / grid.columns) * grid.cellHeight > grid.height + 1
            anchors.right: parent.right
            anchors.rightMargin: 2
            y: grid.y
            width: 3
            height: grid.height
            radius: 1.5
            color: "#26f3efe0"

            Rectangle {
                width: parent.width
                radius: 1.5
                color: Theme.invCream
                height: Math.max(30, parent.height * grid.visibleArea.heightRatio)
                y: grid.visibleArea.yPosition * (parent.height - height) / Math.max(0.0001, 1 - grid.visibleArea.heightRatio)
            }
        }

        Text {
            visible: inv.items.length === 0 && !inv.searching && (inv.deepQuery !== "" || folderModel.status === FolderListModel.Ready)
            anchors.centerIn: grid
            text: inv.deepQuery !== "" ? "Nothing below here matches “" + inv.deepQuery + "”"
                : inv.query !== "" ? "Nothing here matches “" + inv.query + "”  ·  ⏎ to look in subfolders"
                : (inv.inTrashRoot ? "The Trash is empty" : "Nothing stored here yet")
            font.family: Theme.fontDisplay
            font.pixelSize: 17
            font.italic: true
            color: Theme.hudText
            style: Text.Outline
            styleColor: "#cc000000"
        }
    }

    InvDetails {
        id: detailsPane
        anchors.right: parent.right
        anchors.rightMargin: inv.pad
        y: locationRow.y
        visible: inv.showDetails
        width: inv.detailsWidth
        height: band.y - y - 18
        item: inv.selectedItem
        view: inv
    }

    // Bottom strip with the button prompts
    InvBand {
        id: band
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: inv.width < 700 ? 10 : 16
        height: 44

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - prompts.width - 60
            elide: Text.ElideRight
            text: inv.toastText !== "" ? inv.toastText
                : (inv.markedCount > 0 ? inv.markedCount + " marked  ·  Esc to clear" : "Right-click for more")
            font.family: Theme.fontDisplay
            font.pixelSize: 13
            font.bold: inv.toastText !== ""
            font.italic: inv.toastText === ""
            color: inv.toastError ? "#b3202e" : (inv.toastText !== "" ? Theme.invInk : Theme.invInkSoft)
        }

        Row {
            id: prompts
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22

            Repeater {
                model: inv.inTrashRoot ? [
                    { key: "R", label: "Restore", rank: 0, act: () => inv.restoreTargets() },
                    { key: "Del", label: "Delete", rank: 2, act: () => inv.purgeTargets() },
                    { key: "/", label: "Search", rank: 3, act: () => inv.openSearch() },
                    { key: "Space", label: "Mark", rank: 4, act: () => inv.toggleMark(inv.selectedItem) },
                    { key: "⌫", label: "Back", rank: 1, act: () => inv.up() }
                ] : [
                    { key: "⏎", label: "Open", rank: 0, act: () => inv.openItem(inv.selectedItem) },
                    { key: "F2", label: "Rename", rank: 3, act: () => inv.rename() },
                    { key: "/", label: "Search", rank: 2, act: () => inv.openSearch() },
                    { key: "Space", label: "Mark", rank: 4, act: () => inv.toggleMark(inv.selectedItem) },
                    { key: "⌫", label: "Back", rank: 1, act: () => inv.up() }
                ]

                InvPrompt {
                    required property var modelData
                    visible: modelData.rank < inv.promptRoom
                    key: modelData.key
                    label: modelData.label
                    onClicked: modelData.act()
                }
            }
        }
    }

    InvMenu {
        id: menu
        anchors.fill: parent
    }

    InvDialog {
        id: dialog
        anchors.fill: parent
        onClosed: inv.forceActiveFocus()
    }

    InvPicker {
        id: picker
        anchors.fill: parent
        onClosed: inv.forceActiveFocus()
    }
}
