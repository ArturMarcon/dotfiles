import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: surfaceRoot
    anchors.fill: parent

    // Properties for configuration & state
    property bool isTestMode: false
    property var pamContext: null
    property string authString: "" // Optional: auth string if using standard password PAM instead of pam_permit
    property double unlockThreshold: 95.0 // Customizable unlock threshold percentage (default 95%)
    property bool enableIntruderCapture: true // Take photo on failed attempt and display as background
    property string cameraDevice: "/dev/video0" // Camera device path

    property var pendingCoords: []
    property bool evaluating: false
    property bool showingResult: false
    property double lastScore: 0.0
    property bool passed: false
    property string statusMessage: "Draw a Magic Circle to Unlock"
    property string subMessage: "Trace a continuous loop around the center rune"

    signal unlockTriggered()

    // Reset function
    function resetCanvas() {
        pendingCoords = [];
        evaluating = false;
        showingResult = false;
        lastScore = 0.0;
        passed = false;
        statusMessage = "Draw a Magic Circle to Unlock";
        subMessage = "Trace a continuous loop around the center rune";
        strokeCanvas.requestPaint();
    }

    function handleEvaluationResult(score) {
        lastScore = score;
        evaluating = false;
        showingResult = true;

        if (score >= unlockThreshold) {
            passed = true;
            statusMessage = "Score: " + score.toFixed(1) + "% — Arcane Seal Verified!";
            subMessage = isTestMode ? "[Test Mode] " + unlockThreshold.toFixed(0) + "% Threshold Met! System Unlock Triggered." : "Unlocking Wayland Session...";
            strokeCanvas.requestPaint();
            
            // Trigger unlock after brief visual confirmation (300ms so user sees the green glow)
            unlockTimer.start();
        } else {
            passed = false;
            statusMessage = "Score: " + score.toFixed(1) + "% — Imperfect Alignment";
            subMessage = "Requires ≥ " + unlockThreshold.toFixed(1) + "% symmetry and closure. Try again.";
            strokeCanvas.requestPaint();
            
            // Trigger silent camera capture if enabled
            if (enableIntruderCapture) {
                cameraCaptureProcess.running = true;
            }
            
            // Show score for 2 seconds then reset canvas
            retryTimer.start();
        }
    }

    Timer {
        id: unlockTimer
        interval: 350
        repeat: false
        onTriggered: {
            surfaceRoot.unlockTriggered();
            if (pamContext) {
                pamContext.start();
                if (authString !== "" && pamContext.responseRequired) {
                    pamContext.respond(authString);
                }
            } else if (isTestMode) {
                console.log("[Test Mode] PAM unlock hook would execute now.");
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!surfaceRoot.passed) {
                surfaceRoot.resetCanvas();
            }
        }
    }

    // Python Evaluator Process
    Process {
        id: evaluatorProcess
        command: ["python3", "/home/arturmarcon/.config/quickshell/evaluator.py"]
        stdinEnabled: true

        onStarted: {
            var jsonStr = JSON.stringify(surfaceRoot.pendingCoords);
            evaluatorProcess.write(jsonStr + "\n");
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var trimmed = data.trim();
                if (trimmed !== "") {
                    var score = parseFloat(trimmed);
                    if (!isNaN(score)) {
                        surfaceRoot.handleEvaluationResult(score);
                    } else {
                        console.log("Could not parse numeric score from output:", trimmed);
                        surfaceRoot.handleEvaluationResult(0.0);
                    }
                }
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                console.log("Evaluator Python stderr:", data);
            }
        }
    }

    // Camera Capture Process (takes 1 frame silently on failed attempt)
    Process {
        id: cameraCaptureProcess
        command: ["/usr/sbin/ffmpeg", "-y", "-f", "video4linux2", "-i", surfaceRoot.cameraDevice, "-vframes", "1", "/tmp/intruder_bg.jpg"]

        onExited: exitCode => {
            if (exitCode === 0) {
                console.log("[Camera] Intruder photo captured on failed attempt!");
                // Update the background photo for the next try
                bgPhoto.source = "file:///tmp/intruder_bg.jpg?t=" + Date.now();
            } else {
                console.log("[Camera] Capture failed with exit code:", exitCode);
            }
        }
    }

    // =========================================================================
    // Background & Runic Aesthetics
    // =========================================================================
    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#060911" // Deep obsidian obsidian/navy background

        // Dynamic Intruder Photo Background (visible on subsequent tries after a miss)
        Image {
            id: bgPhoto
            anchors.fill: parent
            source: ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            opacity: bgPhoto.status === Image.Ready ? 0.38 : 0.0
            Behavior on opacity { NumberAnimation { duration: 600 } }
        }

        // Radial gradient simulated via glowing center circle
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.95
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#1e293b"
            opacity: 0.6
        }

        // Arcane Compass Inner Runic Circles
        Item {
            anchors.centerIn: parent
            width: 480
            height: 480

            // Outer Guide Ring (Dashed/Arcane vibe)
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: surfaceRoot.showingResult ? (surfaceRoot.passed ? "#10b981" : "#ef4444") : "#38bdf8"
                opacity: surfaceRoot.showingResult ? 0.8 : 0.25
                Behavior on border.color { ColorAnimation { duration: 250 } }
                Behavior on opacity { NumberAnimation { duration: 250 } }

                // Continuous slow rotation for magical effect
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 40000
                    running: true
                }
            }

            // Mid Compass Ring
            Rectangle {
                anchors.centerIn: parent
                width: 320
                height: 320
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: surfaceRoot.showingResult ? (surfaceRoot.passed ? "#10b981" : "#ef4444") : "#0ea5e9"
                opacity: 0.2

                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 360
                    to: 0
                    duration: 30000
                    running: true
                }
            }

            // Core Runic Center Altar
            Rectangle {
                anchors.centerIn: parent
                width: 140
                height: 140
                radius: width / 2
                color: surfaceRoot.showingResult ? (surfaceRoot.passed ? "rgba(16, 185, 129, 0.12)" : "rgba(239, 68, 68, 0.12)") : "rgba(56, 189, 248, 0.08)"
                border.width: 1
                border.color: surfaceRoot.showingResult ? (surfaceRoot.passed ? "#10b981" : "#ef4444") : "#38bdf8"
                opacity: 0.9

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                Text {
                    anchors.centerIn: parent
                    text: surfaceRoot.showingResult ? surfaceRoot.lastScore.toFixed(0) + "%" : "✦"
                    font.pixelSize: surfaceRoot.showingResult ? 32 : 36
                    font.weight: Font.Bold
                    color: surfaceRoot.showingResult ? (surfaceRoot.passed ? "#34d399" : "#f87171") : "#7dd3fc"
                    font.family: "monospace"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
        }
    }

    // =========================================================================
    // Real-Time Stroke Canvas Renderer
    // =========================================================================
    Canvas {
        id: strokeCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            if (surfaceRoot.pendingCoords.length < 2) return;

            ctx.save();
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            // 1. Outer Neon Aura Glow
            ctx.lineWidth = 14;
            ctx.strokeStyle = surfaceRoot.showingResult ? 
                              (surfaceRoot.passed ? "rgba(16, 185, 129, 0.35)" : "rgba(239, 68, 68, 0.35)") : 
                              "rgba(56, 189, 248, 0.28)";
            ctx.beginPath();
            ctx.moveTo(surfaceRoot.pendingCoords[0].x, surfaceRoot.pendingCoords[0].y);
            for (var i = 1; i < surfaceRoot.pendingCoords.length; i++) {
                ctx.lineTo(surfaceRoot.pendingCoords[i].x, surfaceRoot.pendingCoords[i].y);
            }
            ctx.stroke();

            // 2. Inner Sharp Core Line
            ctx.lineWidth = 4;
            ctx.strokeStyle = surfaceRoot.showingResult ? 
                              (surfaceRoot.passed ? "#34d399" : "#f87171") : 
                              "#38bdf8";
            ctx.beginPath();
            ctx.moveTo(surfaceRoot.pendingCoords[0].x, surfaceRoot.pendingCoords[0].y);
            for (var j = 1; j < surfaceRoot.pendingCoords.length; j++) {
                ctx.lineTo(surfaceRoot.pendingCoords[j].x, surfaceRoot.pendingCoords[j].y);
            }
            ctx.stroke();

            ctx.restore();
        }
    }

    // =========================================================================
    // Header Display & Instructions
    // =========================================================================
    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: surfaceRoot.statusMessage
            color: surfaceRoot.showingResult ? (surfaceRoot.passed ? "#34d399" : "#f87171") : "#f8fafc"
            font.pixelSize: 28
            font.weight: Font.DemiBold
            font.family: "sans-serif"
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: surfaceRoot.subMessage
            color: surfaceRoot.showingResult ? (surfaceRoot.passed ? "#a7f3d0" : "#fecaca") : "#94a3b8"
            font.pixelSize: 15
            font.family: "sans-serif"
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    // =========================================================================
    // Pointer / Stylus Tracking Area
    // =========================================================================
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: false

        onPressed: mouse => {
            if (surfaceRoot.evaluating || surfaceRoot.showingResult) {
                // If showing previous result, click immediately resets
                surfaceRoot.resetCanvas();
            }
            surfaceRoot.pendingCoords = [{x: mouse.x, y: mouse.y}];
            strokeCanvas.requestPaint();
        }

        onPositionChanged: mouse => {
            if (surfaceRoot.evaluating) return;
            surfaceRoot.pendingCoords.push({x: mouse.x, y: mouse.y});
            strokeCanvas.requestPaint();
        }

        onReleased: {
            if (surfaceRoot.evaluating) return;
            if (surfaceRoot.pendingCoords.length < 15) {
                surfaceRoot.handleEvaluationResult(0.0);
                return;
            }

            surfaceRoot.evaluating = true;
            surfaceRoot.statusMessage = "Evaluating Arcane Alignment...";
            surfaceRoot.subMessage = "Analyzing vector geometry against ideal circular radius...";
            
            // Trigger Python evaluation process
            evaluatorProcess.running = true;
        }
    }
}
