import QtQuick

// What the inventory shows for a file: its real thumbnail when there is one
// (pictures, video frames, album covers, PDF first pages), otherwise painted
// item art (see ItemArt). Media thumbnails are rendered once into
// ~/.cache/hyrule-inventory by scripts/inventory-ops.sh, and only loaded once
// they exist, so missing ones never reach the Image.
Item {
    id: img
    property var item: null
    property var view: null
    property int pixelSize: 256
    property bool crop: true

    readonly property string kind: item ? item.kind : ""
    // Pictures load directly unless Qt can't read them (webp, heic, ... without
    // qt6-imageformats); then ffmpeg renders a copy like it does for videos
    readonly property var foreignFormats: ["webp", "avif", "heic", "heif", "jxl", "tif", "tiff"]
    readonly property string itemPath: item ? item.path : ""
    property bool undecodable: item !== null && foreignFormats.indexOf(item.suffix) >= 0
    readonly property bool rendered: kind === "video" || kind === "audio" || kind === "pdf" || undecodable
    readonly property string renderName: rendered && view ? view.thumbName(item) : ""
    readonly property string renderState: renderName === "" ? "none" : view.thumbState(renderName)
    readonly property string thumbFile: kind === "image" && !undecodable ? item.path
        : (renderState === "ready" ? view.thumbDir + "/" + renderName : "")
    readonly property bool hasThumb: thumbFile !== "" && thumb.status === Image.Ready

    onItemPathChanged: undecodable = Qt.binding(() => item !== null && foreignFormats.indexOf(item.suffix) >= 0)

    onRenderStateChanged: {
        if (renderState === "missing") view.requestThumb(item, renderName);
    }

    Component.onCompleted: {
        if (renderState === "missing") view.requestThumb(item, renderName);
    }

    Image {
        id: thumb
        anchors.fill: parent
        source: img.thumbFile !== "" ? img.view.fileUrl(img.thumbFile) : ""
        sourceSize: Qt.size(img.pixelSize, img.pixelSize)
        fillMode: img.crop ? Image.PreserveAspectCrop : Image.PreserveAspectFit
        asynchronous: true
        autoTransform: true
        visible: img.hasThumb

        onStatusChanged: {
            if (status === Image.Error && img.kind === "image" && !img.undecodable) img.undecodable = true;
        }
    }

    ItemArt {
        anchors.fill: parent
        kind: img.view ? img.view.artFor(img.item) : "pouch"
        visible: !img.hasThumb
    }
}
