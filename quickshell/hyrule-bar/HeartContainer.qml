import QtQuick

// A single heart container. `fill` runs 0..1 and drains like a pie, one
// quarter at a time, emptying from the right like the row of hearts does.
Canvas {
    id: heart
    property real fill: 1.0
    property bool pulsing: false

    implicitWidth: 15
    implicitHeight: 14
    width: implicitWidth
    height: implicitHeight

    Behavior on fill { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
    onFillChanged: requestPaint()

    // Low-health throb on the last heart standing
    SequentialAnimation on scale {
        running: heart.pulsing
        loops: Animation.Infinite
        NumberAnimation { to: 1.25; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { to: 1.0; duration: 380; easing.type: Easing.InQuad }
        PauseAnimation { duration: 300 }
    }
    onPulsingChanged: if (!pulsing) scale = 1.0

    function trace(ctx) {
        var w = width, h = height;
        ctx.beginPath();
        ctx.moveTo(w * 0.5, h * 0.93);
        ctx.bezierCurveTo(w * 0.36, h * 0.82, w * 0.05, h * 0.6, w * 0.05, h * 0.33);
        ctx.bezierCurveTo(w * 0.05, h * 0.15, w * 0.17, h * 0.06, w * 0.29, h * 0.06);
        ctx.bezierCurveTo(w * 0.39, h * 0.06, w * 0.46, h * 0.12, w * 0.5, h * 0.21);
        ctx.bezierCurveTo(w * 0.54, h * 0.12, w * 0.61, h * 0.06, w * 0.71, h * 0.06);
        ctx.bezierCurveTo(w * 0.83, h * 0.06, w * 0.95, h * 0.15, w * 0.95, h * 0.33);
        ctx.bezierCurveTo(w * 0.95, h * 0.6, w * 0.64, h * 0.82, w * 0.5, h * 0.93);
        ctx.closePath();
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        // Empty container
        trace(ctx);
        ctx.fillStyle = Theme.heartEmpty;
        ctx.fill();

        // Remaining quarters as a pie wedge clipped to the heart
        if (fill > 0.005) {
            var cx = width / 2, cy = height / 2;
            ctx.save();
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.arc(cx, cy, width, -Math.PI / 2, -Math.PI / 2 - fill * Math.PI * 2, true);
            ctx.closePath();
            ctx.clip();

            trace(ctx);
            var grad = ctx.createLinearGradient(0, 0, 0, height);
            grad.addColorStop(0, Theme.heartLight);
            grad.addColorStop(0.55, Theme.heartRed);
            ctx.fillStyle = grad;
            ctx.fill();

            ctx.beginPath();
            ctx.ellipse(width * 0.17, height * 0.17, width * 0.2, height * 0.16);
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.55);
            ctx.fill();
            ctx.restore();
        }

        trace(ctx);
        ctx.lineWidth = 1;
        ctx.strokeStyle = fill > 0.005 ? Theme.heartRim : Theme.heartEmptyRim;
        ctx.stroke();
    }
}
