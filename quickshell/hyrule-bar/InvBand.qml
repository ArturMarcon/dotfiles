import QtQuick

// The cream strip along the bottom of the inventory, printed with the game's
// faint swirl pattern.
Rectangle {
    id: band
    default property alias content: holder.data

    color: Theme.invCream
    radius: 6

    Canvas {
        id: swirls
        anchors.fill: parent
        opacity: 0.55
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = Theme.invCreamShade;
            ctx.lineWidth = 1.4;
            ctx.lineCap = "round";
            var step = 46;
            var cy = height / 2;
            for (var x = step / 2, n = 0; x < width + step; x += step, n++) {
                // An unwinding spiral, alternating turn so the row reads as waves
                var dir = n % 2 === 0 ? 1 : -1;
                var cyn = cy + (n % 2 === 0 ? -3 : 3);
                ctx.beginPath();
                for (var t = 0; t <= Math.PI * 3.2; t += 0.12) {
                    var r = 1.2 + t * 1.25;
                    var px = x + dir * Math.cos(t) * r;
                    var py = cyn + Math.sin(t) * r;
                    if (t === 0) ctx.moveTo(px, py);
                    else ctx.lineTo(px, py);
                }
                // Tail running into the next swirl
                ctx.quadraticCurveTo(x + step * 0.5, cyn + (n % 2 === 0 ? 14 : -14), x + step, cyn + (n % 2 === 0 ? 6 : -6));
                ctx.stroke();
            }
        }
    }

    Item {
        id: holder
        anchors.fill: parent
    }
}
