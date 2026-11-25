import QtQuick

// Desktop panel with GPU and RAM cards, each with a one-minute history.
// CPU already lives in the bar as heart containers.
GlassPanel {
    id: systemWidget
    implicitWidth: 580
    implicitHeight: 196
    fill: Theme.widgetFill

    Row {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        StatCard {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "gpu"
            label: "GPU"
            value: SystemStats.gpu
            history: SystemStats.gpuHistory
            detail: SystemStats.gpuAsleep ? "Resting" : (SystemStats.gpuTemp > 0 ? Math.round(SystemStats.gpuTemp) + "°C" : "")
            detailIcon: SystemStats.gpuAsleep ? "moon" : "thermo"
            note: SystemStats.gpuMemTotalGb > 0 ? "VRAM " + SystemStats.gpuMemUsedGb.toFixed(1) + " / " + Math.round(SystemStats.gpuMemTotalGb) + " GB" : ""
        }

        StatCard {
            width: (parent.width - parent.spacing) / 2
            height: parent.height
            icon: "memory"
            label: "RAM"
            value: SystemStats.mem
            history: SystemStats.memHistory
            detail: SystemStats.memUsedGb.toFixed(1) + " / " + Math.round(SystemStats.memTotalGb) + " GB"
        }
    }
}
