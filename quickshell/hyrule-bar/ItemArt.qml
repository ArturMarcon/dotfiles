import QtQuick

// Painted item icons for files without a thumbnail, in the spirit of the
// game's inventory art: a chest for folders, a scroll for documents, a Sheikah
// Slate for code, a crate for archives, an ocarina for music, and so on.
// Each piece is a stack of SVG paths on a 64x64 grid: [path, fill, stroke, width].
Canvas {
    id: art
    property string kind: "pouch"

    readonly property var pieces: ({
        "chest": [
            ["M9 30h46v22a3 3 0 0 1-3 3H12a3 3 0 0 1-3-3z", "#8b5a2b"],
            ["M9 44h46v8a3 3 0 0 1-3 3H12a3 3 0 0 1-3-3z", "#74481f"],
            ["M9 30v-6c0-6 4.5-11 10.5-11h25C50.5 13 55 18 55 24v6z", "#a5692f"],
            ["M13.5 23c0-3.6 2.8-6 6.3-6h24.4c3.5 0 6.3 2.4 6.3 6", "", "#f3cf8e", 1.6],
            ["M8 28h48v5H8z", "#d9a93c"],
            ["M15 14v41h5V13.2z M44 13.2V55h5V14z", "#c89634"],
            ["M27 27h10v11a2 2 0 0 1-2 2h-6a2 2 0 0 1-2-2z", "#f2cd60"],
            ["M32 30.2a2.1 2.1 0 1 1 0 4.2a2.1 2.1 0 1 1 0-4.2z M31.1 33.6h1.8l.7 3.6h-3.2z", "#3a2410"]
        ],
        "scroll": [
            ["M16 12h32v40H16z", "#ead9ae"],
            ["M21 21h22 M21 27h22 M21 33h17 M21 39h20", "", "#9c7a45", 2],
            ["M12 7.5h40a4.5 4.5 0 0 1 0 9H12a4.5 4.5 0 0 1 0-9z", "#c9a96a"],
            ["M12 47.5h40a4.5 4.5 0 0 1 0 9H12a4.5 4.5 0 0 1 0-9z", "#c9a96a"],
            ["M12 10h40 M12 50h40", "", "#f2e2b8", 1.4],
            ["M41.5 41a5.5 5.5 0 1 0 11 0a5.5 5.5 0 1 0-11 0", "#b8423a"],
            ["M45 41l2-2.5 2 2.5-2 2.5z", "#e88a7f"]
        ],
        "slate": [
            ["M13 7h38a5 5 0 0 1 5 5v40a5 5 0 0 1-5 5H13a5 5 0 0 1-5-5V12a5 5 0 0 1 5-5z", "#3b3f47", "#e0954a", 1.6],
            ["M14 13h36v31H14z", "#0b2f3a"],
            ["M18.5 19h13 M18.5 25h21 M22.5 31h15 M18.5 37h9", "", "#4fd2ff", 2.4],
            ["M25.5 50.5c3.6-3.4 9.4-3.4 13 0c-3.6 3.4-9.4 3.4-13 0z", "#4fd2ff"],
            ["M30.4 50.5a1.6 1.6 0 1 0 3.2 0a1.6 1.6 0 1 0-3.2 0", "#0b2f3a"]
        ],
        "crate": [
            ["M10 13h44v41H10z", "#a8743a"],
            ["M10 26.6h44 M10 40.3h44", "", "#7a5226", 2],
            ["M15 49L49 18", "", "#8a5c2a", 5],
            ["M10 13h44v41H10z", "", "#6b4520", 3],
            ["M8.5 11.5h8v3h-5v5h-3z M55.5 11.5h-8v3h5v5h3z M8.5 55.5h8v-3h-5v-5h-3z M55.5 55.5h-8v-3h5v-5h3z", "#c3c6cc"]
        ],
        "ocarina": [
            ["M44 21l10-7 3.5 5-9.5 7z", "#3d5f8f"],
            ["M12 35c0-10.5 10.5-19 23-19c10.5 0 17 6.5 17 13.5c0 10.5-12.5 19.5-25 19.5c-8.5 0-15-5-15-14z", "#4f78b0"],
            ["M19 31c2-6.5 8.5-10.5 16-10.5", "", "#bcd3f0", 2.4],
            ["M23 37.5a2.3 2.3 0 1 0 4.6 0a2.3 2.3 0 1 0-4.6 0 M30.5 34a2.3 2.3 0 1 0 4.6 0a2.3 2.3 0 1 0-4.6 0 M38 31.5a2.3 2.3 0 1 0 4.6 0a2.3 2.3 0 1 0-4.6 0 M28.5 42.5a2 2 0 1 0 4 0a2 2 0 1 0-4 0", "#1d2f47"],
            ["M38 44l3.2-5.4 3.2 5.4z", "#e6c25a"]
        ],
        "film": [
            ["M8 13h48v38H8z", "#24262b"],
            ["M11 16h4v3h-4z M19 16h4v3h-4z M27 16h4v3h-4z M35 16h4v3h-4z M43 16h4v3h-4z M51 16h3v3h-3z M11 45h4v3h-4z M19 45h4v3h-4z M27 45h4v3h-4z M35 45h4v3h-4z M43 45h4v3h-4z M51 45h3v3h-3z", "#d8d4c4"],
            ["M12 23h40v18H12z", "#3a7bd5"],
            ["M12 41l10-10 7 6 6-5 17 9z", "#2a5f9e"],
            ["M42 27.5a3 3 0 1 0 6 0a3 3 0 1 0-6 0", "#f3d36b"]
        ],
        "picture": [
            ["M8 12h48v40H8z", "#d4a64a"],
            ["M13 17h38v30H13z", "#6fb5e8"],
            ["M13 47l12-14 8 8 6-5 12 11z", "#4f9a4f"],
            ["M40 25a4 4 0 1 0 8 0a4 4 0 1 0-8 0", "#fff1a8"]
        ],
        "book": [
            ["M15 8h33a3 3 0 0 1 3 3v42a3 3 0 0 1-3 3H15z", "#9b2d2d"],
            ["M15 8h6v48h-6z", "#741f1f"],
            ["M24 14h22 M24 50h22", "", "#e6c25a", 1.6],
            ["M35 21l9 15.5H26z", "#e6c25a"],
            ["M35 30.5l3.5 6h-7z", "#9b2d2d"]
        ],
        "rupee": [
            ["M32 6l14 12v28L32 58 18 46V18z", "#2fb56a"],
            ["M32 6L18 18v28l14 12z", "#239055"],
            ["M32 14l8 8v20l-8 8-8-8V22z", "#5fd68f"],
            ["M32 14l8 8H24z", "#b4f3cd"]
        ],
        "pouch": [
            ["M20 26c-6.5 6-9.5 14-7.5 22c2 6.5 8.5 8.5 19.5 8.5s17.5-2 19.5-8.5c2-8-1-16-7.5-22z", "#a7814f"],
            ["M24 17h16l-4 9H28z", "#8c6a3e"],
            ["M21.5 24h21v4.5h-21z", "#c94c3b"],
            ["M18.5 40c.5-5 2.5-9 5.5-12", "", "#d9bd8c", 2.2]
        ]
    })

    onKindChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var layers = pieces[kind] || pieces["pouch"];
        var s = Math.min(width, height) / 64;
        ctx.save();
        ctx.translate((width - 64 * s) / 2, (height - 64 * s) / 2);
        ctx.scale(s, s);

        // Soft shadow on the slot floor
        ctx.beginPath();
        ctx.ellipse(12, 53, 40, 7);
        ctx.fillStyle = "rgba(0, 0, 0, 0.35)";
        ctx.fill();

        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        for (var i = 0; i < layers.length; i++) {
            var l = layers[i];
            ctx.path = l[0];
            if (l[1]) {
                ctx.fillStyle = l[1];
                ctx.fill();
            }
            if (l.length > 2 && l[2]) {
                ctx.strokeStyle = l[2];
                ctx.lineWidth = l[3];
                ctx.stroke();
            }
        }
        ctx.restore();
    }
}
