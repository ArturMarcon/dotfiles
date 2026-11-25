pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// One sampler for CPU, GPU and memory, shared by the bar's hearts and the
// desktop widgets so everything is read once rather than once per monitor.
Singleton {
    id: stats

    readonly property int historyLength: 60
    property real cpu: 0.0

    property real memUsedGb: 0
    property real memTotalGb: 0
    readonly property real mem: memTotalGb > 0 ? memUsedGb / memTotalGb : 0
    property var memHistory: []

    // NVIDIA dGPU. Not polled while runtime-suspended, since nvidia-smi would wake it.
    property string gpuDevice: ""
    property bool gpuAsleep: false
    property real gpu: 0.0
    property real gpuTemp: 0
    property real gpuMemUsedGb: 0
    property real gpuMemTotalGb: 0
    property var gpuHistory: []

    property var lastCpu: null

    FileView {
        id: procStat
        path: "/proc/stat"
        blockLoading: true
    }

    FileView {
        id: memInfo
        path: "/proc/meminfo"
        blockLoading: true
    }

    FileView {
        id: gpuPower
        path: stats.gpuDevice ? stats.gpuDevice + "/power/runtime_status" : ""
        blockLoading: true
    }

    // Find the NVIDIA display controller (vendor 0x10de, class 0x03xxxx)
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/bus/pci/devices/*; do [ \"$(cat $d/vendor)\" = 0x10de ] && case \"$(cat $d/class)\" in 0x03*) echo $d; break;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: stats.gpuDevice = text.trim()
        }
    }

    Process {
        id: gpuQuery
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = text.trim().split("\n")[0].split(",").map(Number);
                if (v.length < 4 || v.some(isNaN)) return;
                stats.gpu = Math.max(0, Math.min(1, v[0] / 100));
                stats.gpuTemp = v[1];
                stats.gpuMemUsedGb = v[2] / 1024;
                stats.gpuMemTotalGb = v[3] / 1024;
                stats.gpuHistory = stats.remember(stats.gpuHistory, stats.gpu);
            }
        }
    }

    function remember(list, value) {
        var next = list.slice(-(historyLength - 1));
        next.push(value);
        return next;
    }

    function sample() {
        procStat.reload();
        var m = procStat.text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (m) {
            var v = m.slice(1).map(Number);
            var idle = v[3] + v[4];
            var total = v.reduce(function (a, b) { return a + b; }, 0);
            if (lastCpu && total > lastCpu.total)
                cpu = Math.max(0, Math.min(1, 1 - (idle - lastCpu.idle) / (total - lastCpu.total)));
            lastCpu = { idle: idle, total: total };
        }

        memInfo.reload();
        var info = memInfo.text();
        var totalKb = Number((info.match(/^MemTotal:\s+(\d+)/m) || [0, 0])[1]);
        var availKb = Number((info.match(/^MemAvailable:\s+(\d+)/m) || [0, 0])[1]);
        if (totalKb > 0) {
            memTotalGb = totalKb / 1048576;
            memUsedGb = (totalKb - availKb) / 1048576;
            memHistory = remember(memHistory, mem);
        }

        if (gpuDevice) {
            gpuPower.reload();
            gpuAsleep = gpuPower.text().trim() === "suspended";
            if (gpuAsleep) {
                gpu = 0;
                gpuHistory = remember(gpuHistory, 0);
            } else if (!gpuQuery.running) {
                gpuQuery.running = true;
            }
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: stats.sample()
    }
}
