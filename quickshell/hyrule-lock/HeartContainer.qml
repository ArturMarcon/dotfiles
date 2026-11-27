import QtQuick

// A single heart container. `fill` runs 0..1 and drains like a pie, one
// quarter at a time, emptying from the right like the row of hearts does.
// Losing fill plays the game's damage hit: the heart kicks and blinks white,
// its quarters tick away one by one and shards burst off it. Gaining fill
// ticks the quarters back in with a warm glow.
Canvas {
    id: heart
    property real fill: 1.0
    property bool pulsing: false
    property real rimWidth: 1
    property bool animated: true   // false jumps straight to `fill`
    property int healDelay: 0      // ms, so a row can refill left to right

    // What is drawn; steps toward `fill` a quarter at a time
    property real shown: 1.0
    property real flash: 0
    property real glow: 0
    property real pop: 1
    property real burst: 0

    implicitWidth: 15
    implicitHeight: 14
    width: implicitWidth
    height: implicitHeight

    onShownChanged: requestPaint()
    onFlashChanged: requestPaint()
    onGlowChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    Component.onCompleted: shown = fill

    onFillChanged: {
        hurt.stop();
        heal.stop();
        stepper.stop();
        flash = 0;
        glow = 0;
        pop = 1;
        burst = 0;
        if (!animated) shown = fill;
        else if (fill < shown) hurt.start();
        else if (fill > shown) heal.start();
    }

    // One quarter per tick, toward `fill`
    Timer {
        id: stepper
        interval: 85
        repeat: true
        onTriggered: {
            heart.shown = heart.fill < heart.shown
                ? Math.max(heart.fill, heart.shown - 0.25)
                : Math.min(heart.fill, heart.shown + 0.25);
            if (heart.shown === heart.fill) stop();
        }
    }

    ParallelAnimation {
        id: hurt

        SequentialAnimation {
            PauseAnimation { duration: 110 }
            ScriptAction { script: stepper.start() }
        }

        // Blink white, like the game's hit flicker
        SequentialAnimation {
            loops: 3
            PropertyAction { target: heart; property: "flash"; value: 1 }
            PauseAnimation { duration: 70 }
            PropertyAction { target: heart; property: "flash"; value: 0 }
            PauseAnimation { duration: 70 }
        }

        SequentialAnimation {
            NumberAnimation { target: heart; property: "pop"; to: 1.45; duration: 70; easing.type: Easing.OutQuad }
            NumberAnimation { target: heart; property: "pop"; to: 1; duration: 420; easing.type: Easing.OutBack }
        }

        SequentialAnimation {
            NumberAnimation { target: heart; property: "burst"; from: 0; to: 1; duration: 560; easing.type: Easing.OutCubic }
            PropertyAction { target: heart; property: "burst"; value: 0 }
        }
    }

    SequentialAnimation {
        id: heal
        PauseAnimation { duration: heart.healDelay }
        ScriptAction { script: stepper.start() }

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: heart; property: "glow"; to: 1; duration: 160; easing.type: Easing.OutQuad }
                NumberAnimation { target: heart; property: "glow"; to: 0; duration: 520; easing.type: Easing.InQuad }
            }
            SequentialAnimation {
                NumberAnimation { target: heart; property: "pop"; to: 1.25; duration: 140; easing.type: Easing.OutQuad }
                NumberAnimation { target: heart; property: "pop"; to: 1; duration: 360; easing.type: Easing.OutBack }
            }
        }
    }

    // Kept apart from `scale`, which the low-health throb drives
    transform: Scale {
        origin.x: heart.width / 2
        origin.y: heart.height / 2
        xScale: heart.pop
        yScale: heart.pop
    }

    // Low-health throb on the last heart standing
    SequentialAnimation on scale {
        running: heart.pulsing
        loops: Animation.Infinite
        NumberAnimation { to: 1.25; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { to: 1.0; duration: 380; easing.type: Easing.InQuad }
        PauseAnimation { duration: 300 }
    }
    onPulsingChanged: if (!pulsing) scale = 1.0

    // Shards knocked off by a hit
    Repeater {
        model: 7

        Rectangle {
            readonly property real angle: -Math.PI / 2 + index * Math.PI * 2 / 7 + 0.3
            readonly property real reach: heart.width * (1.0 + (index % 3) * 0.25)
            width: Math.max(3, heart.width * 0.16)
            height: width
            rotation: 45 + index * 20
            x: heart.width / 2 - width / 2 + Math.cos(angle) * reach * heart.burst
            y: heart.height / 2 - height / 2 + Math.sin(angle) * reach * heart.burst + heart.height * 0.4 * heart.burst * heart.burst
            color: index % 2 === 0 ? Theme.heartLight : Theme.heartRed
            opacity: 1 - heart.burst
            visible: heart.burst > 0
        }
    }

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
        if (shown > 0.005) {
            var cx = width / 2, cy = height / 2;
            ctx.save();
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.arc(cx, cy, width, -Math.PI / 2, -Math.PI / 2 - shown * Math.PI * 2, true);
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

            // Healing light on the quarters that came back
            if (glow > 0) {
                trace(ctx);
                ctx.fillStyle = Qt.rgba(1, 0.92, 0.72, 0.55 * glow);
                ctx.fill();
            }
            ctx.restore();
        }

        // Hit flicker over the whole container
        if (flash > 0) {
            trace(ctx);
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.85 * flash);
            ctx.fill();
        }

        trace(ctx);
        ctx.lineWidth = rimWidth;
        ctx.strokeStyle = flash > 0 ? "#ffffff" : (shown > 0.005 ? Theme.heartRim : Theme.heartEmptyRim);
        ctx.stroke();
    }
}
