import QtQuick

// Small area chart of recent values (0..1), newest on the right.
Canvas {
    id: spark
    property var values: []
    property int capacity: 60
    property color color: Theme.leaf

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        // Faint guides at 50% and 100%
        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.12);
        ctx.fillRect(0, 0, width, 1);
        ctx.fillRect(0, Math.round(height / 2), width, 1);

        var n = values.length;
        if (n < 2) return;

        var step = width / (capacity - 1);
        var x0 = width - (n - 1) * step;
        ctx.beginPath();
        for (var i = 0; i < n; i++) {
            var x = x0 + i * step;
            var y = height - 1 - values[i] * (height - 2);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "round";
        ctx.strokeStyle = color;
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(x0, height);
        ctx.closePath();
        var grad = ctx.createLinearGradient(0, 0, 0, height);
        grad.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.35));
        grad.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0.0));
        ctx.fillStyle = grad;
        ctx.fill();
    }
}
