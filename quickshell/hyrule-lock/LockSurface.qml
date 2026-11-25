import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Services.UPower
import "."

// Everything drawn on one monitor while locked. All state lives in `lock`
// (LockScreen.qml), so every monitor shows the same hearts and password.
Item {
    id: surface
    property var lock: null

    readonly property bool portrait: height > width
    readonly property real ui: Math.max(0.7, Math.min(width, height) / 1080)
    readonly property string wallDir: Quickshell.env("HOME") + "/wallpapers/"

    readonly property string message: {
        if (!lock) return "";
        if (lock.unlocking) return "Welcome back. The path is open.";
        if (lock.lockoutRemaining > 0) {
            var s = lock.lockoutRemaining;
            return "You're out of hearts. Rest a while and try again in "
                + Math.floor(s / 60) + ":" + (s % 60).toString().padStart(2, '0') + ".";
        }
        if (lock.authenticating) return "Checking…";
        if (lock.failed) {
            var left = lock.heartsShown;
            return "That's not it. You took damage — " + left + (left === 1 ? " heart" : " hearts") + " left.";
        }
        return "The way ahead is sealed. Enter your password to continue.";
    }

    // ---------------------------------------------------------------------
    // Backdrop: the forest, blurred and dimmed like a paused game
    // ---------------------------------------------------------------------
    Item {
        anchors.fill: parent
        clip: true

        Image {
            id: bgImage
            anchors.fill: parent
            source: "file://" + surface.wallDir + (surface.portrait ? "botw-vertical.jpg" : "botw-lock.jpg")
            fillMode: Image.PreserveAspectCrop
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: bgImage
            blurEnabled: true
            blurMax: 48
            blur: 0.5
            brightness: -0.26
            saturation: 0.05

            // Slow camera drift
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.05; to: 1.12; duration: 30000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.12; to: 1.05; duration: 30000; easing.type: Easing.InOutSine }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#80050e0c" }
            GradientStop { position: 0.4; color: "#4d050e0c" }
            GradientStop { position: 1.0; color: "#e6050e0c" }
        }
    }

    // Vignette
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: surface.width / 2
                centerY: surface.height * 0.45
                centerRadius: Math.max(surface.width, surface.height) * 0.75
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0.4; color: "#00020807" }
                GradientStop { position: 1.0; color: "#b3020807" }
            }
            startX: 0; startY: 0
            PathLine { x: surface.width; y: 0 }
            PathLine { x: surface.width; y: surface.height }
            PathLine { x: 0; y: surface.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Fireflies {
        anchors.fill: parent
        count: surface.portrait ? 26 : 34
    }

    // ---------------------------------------------------------------------
    // HUD: heart containers (attempts left before faillock), top-left
    // ---------------------------------------------------------------------
    Row {
        id: heartsRow
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 44 * surface.ui
        spacing: 7 * surface.ui

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#cc020807"
            shadowBlur: 0.6
            shadowVerticalOffset: 2
        }

        Repeater {
            model: surface.lock ? surface.lock.maxHearts : 3

            HeartContainer {
                implicitWidth: 34 * surface.ui
                implicitHeight: 31 * surface.ui
                rimWidth: 1.5
                fill: surface.lock && index < surface.lock.heartsShown ? 1 : 0
                pulsing: surface.lock && surface.lock.heartsShown === 1 && index === 0
            }
        }
    }

    // ---------------------------------------------------------------------
    // HUD: time of day & stamina (battery), top-right
    // ---------------------------------------------------------------------
    Row {
        id: statusRow
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 44 * surface.ui
        spacing: 22 * surface.ui

        property var device: UPower.displayDevice
        property bool hasBattery: device !== null && device.isPresent
        property real pct: device ? device.percentage : 1.0
        property bool charging: device && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#cc020807"
            shadowBlur: 0.6
            shadowVerticalOffset: 2
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10 * surface.ui

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                name: surface.lock && !surface.lock.isDaytime ? "moon" : "sun"
                size: 24 * surface.ui
                color: surface.lock && !surface.lock.isDaytime ? Theme.shrineTeal : Theme.amber
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: surface.lock ? surface.lock.dateStr : ""
                font.family: Theme.fontDisplay
                font.pixelSize: 18 * surface.ui
                color: Theme.sunbeam
            }
        }

        // Stamina wheel
        Item {
            visible: statusRow.hasBattery
            anchors.verticalCenter: parent.verticalCenter
            width: 36 * surface.ui
            height: width

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Theme.staminaTrack
                    strokeWidth: 6 * surface.ui
                    PathAngleArc {
                        centerX: 18 * surface.ui; centerY: 18 * surface.ui
                        radiusX: 14 * surface.ui; radiusY: 14 * surface.ui
                        startAngle: 0
                        sweepAngle: 360
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: statusRow.charging ? Theme.sunlit : (statusRow.pct <= 0.2 ? Theme.crimson : Theme.stamina)
                    strokeWidth: 6 * surface.ui
                    capStyle: ShapePath.FlatCap
                    PathAngleArc {
                        centerX: 18 * surface.ui; centerY: 18 * surface.ui
                        radiusX: 14 * surface.ui; radiusY: 14 * surface.ui
                        startAngle: -90
                        sweepAngle: 360 * Math.max(0, Math.min(1, statusRow.pct))
                    }
                }
            }

            Glyph {
                anchors.centerIn: parent
                name: "bolt"
                size: 14 * surface.ui
                color: Theme.sunbeam
                visible: statusRow.charging
            }
        }
    }

    // ---------------------------------------------------------------------
    // Area title: the time, revealed like entering a new region
    // ---------------------------------------------------------------------
    Column {
        id: titleBlock
        anchors.horizontalCenter: parent.horizontalCenter
        y: surface.height * (surface.portrait ? 0.24 : 0.2)
        spacing: 4 * surface.ui
        opacity: 0

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#e6020807"
            shadowBlur: 1.0
            shadowVerticalOffset: 3
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: surface.lock ? surface.lock.timeStr : ""
            font.family: Theme.fontDisplay
            font.pixelSize: 132 * surface.ui
            color: Theme.sunbeam
        }

        // Rule with a center diamond
        Item {
            id: rule
            anchors.horizontalCenter: parent.horizontalCenter
            width: 0
            height: 14 * surface.ui

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Theme.sunlit }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 8 * surface.ui
                height: width
                rotation: 45
                color: Theme.abyss
                border.width: 1
                border.color: Theme.sunlit
            }
        }

        Text {
            id: subtitle
            anchors.horizontalCenter: parent.horizontalCenter
            text: surface.lock ? surface.lock.dateStr.toUpperCase() : ""
            font.family: Theme.fontDisplay
            font.pixelSize: 17 * surface.ui
            font.letterSpacing: 16 * surface.ui
            color: Theme.sunlit
        }
    }

    ParallelAnimation {
        running: true
        NumberAnimation { target: titleBlock; property: "opacity"; to: 1; duration: 1400; easing.type: Easing.OutCubic }
        NumberAnimation { target: rule; property: "width"; to: 560 * surface.ui; duration: 1800; easing.type: Easing.OutCubic }
        NumberAnimation { target: subtitle; property: "font.letterSpacing"; to: 6 * surface.ui; duration: 1800; easing.type: Easing.OutCubic }
    }

    // ---------------------------------------------------------------------
    // Dialogue box with the password prompt
    // ---------------------------------------------------------------------
    Item {
        id: dialogue
        width: Math.min(780 * surface.ui, surface.width - 64 * surface.ui)
        height: dialogueColumn.implicitHeight + 52 * surface.ui
        x: (surface.width - width) / 2 + shakeOffset
        y: surface.height * (surface.portrait ? 0.6 : 0.6)

        property real shakeOffset: 0

        SequentialAnimation {
            id: shake
            NumberAnimation { target: dialogue; property: "shakeOffset"; to: -16; duration: 45 }
            NumberAnimation { target: dialogue; property: "shakeOffset"; to: 14; duration: 70 }
            NumberAnimation { target: dialogue; property: "shakeOffset"; to: -9; duration: 60 }
            NumberAnimation { target: dialogue; property: "shakeOffset"; to: 5; duration: 50 }
            NumberAnimation { target: dialogue; property: "shakeOffset"; to: 0; duration: 45 }
        }

        Connections {
            target: surface.lock
            function onDamaged() { shake.restart(); }
        }

        Rectangle {
            anchors.fill: parent
            radius: 24 * surface.ui
            color: "#bf040b0a"
            border.width: 1
            border.color: "#33eef3d6"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5 * surface.ui
                radius: parent.radius - 5 * surface.ui
                color: "transparent"
                border.width: 1
                border.color: surface.lock && surface.lock.failed ? "#99e0404f" : "#1aeef3d6"
                Behavior on border.color { ColorAnimation { duration: Theme.animDurationNormal } }
            }
        }

        Column {
            id: dialogueColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 34 * surface.ui
            anchors.rightMargin: 34 * surface.ui
            anchors.topMargin: 24 * surface.ui
            spacing: 12 * surface.ui

            // Speaker
            Text {
                text: surface.lock ? surface.lock.user : ""
                font.family: Theme.fontDisplay
                font.pixelSize: 17 * surface.ui
                font.bold: true
                color: Theme.amber
            }

            Text {
                width: parent.width
                text: surface.message
                wrapMode: Text.WordWrap
                font.family: Theme.fontDisplay
                font.pixelSize: 21 * surface.ui
                color: surface.lock && (surface.lock.failed || surface.lock.lockoutRemaining > 0) ? Theme.heartLight : Theme.sunbeam
                Behavior on color { ColorAnimation { duration: Theme.animDurationNormal } }
            }

            // Password, one diamond per character
            Item {
                width: parent.width
                height: 26 * surface.ui

                Row {
                    id: diamonds
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6 * surface.ui

                    Repeater {
                        model: surface.lock ? Math.min(surface.lock.buffer.length, 36) : 0
                        Glyph {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "diamond"
                            size: 15 * surface.ui
                            color: Theme.sunlit
                        }
                    }

                    // Caret
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 20 * surface.ui
                        color: Theme.sunlit
                        visible: surface.lock && !surface.lock.authenticating && !surface.lock.unlocking

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 530; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1; duration: 530; easing.type: Easing.InOutQuad }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * surface.ui
                    text: "Type your password…"
                    font.family: Theme.fontDisplay
                    font.pixelSize: 17 * surface.ui
                    font.italic: true
                    color: Theme.textMuted
                    visible: surface.lock && surface.lock.buffer.length === 0 && !surface.lock.authenticating && !surface.lock.unlocking
                }
            }
        }

        // "Continue" arrow, bobbing like an in-game dialogue
        Glyph {
            id: nextArrow
            anchors.right: parent.right
            anchors.rightMargin: 26 * surface.ui
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20 * surface.ui
            name: "play"
            rotation: 90
            size: 16 * surface.ui
            color: Theme.sunbeam
            visible: surface.lock && surface.lock.buffer.length > 0 && !surface.lock.authenticating

            SequentialAnimation on anchors.bottomMargin {
                loops: Animation.Infinite
                running: nextArrow.visible
                NumberAnimation { to: 14 * surface.ui; duration: 420; easing.type: Easing.InOutSine }
                NumberAnimation { to: 20 * surface.ui; duration: 420; easing.type: Easing.InOutSine }
            }
        }

        // Spinner while PAM is checking
        Glyph {
            anchors.right: parent.right
            anchors.rightMargin: 24 * surface.ui
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18 * surface.ui
            name: "slate"
            size: 22 * surface.ui
            weight: 1.6
            color: Theme.shrineTeal
            visible: surface.lock && surface.lock.authenticating

            RotationAnimation on rotation {
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1600
                running: surface.lock && surface.lock.authenticating
            }
        }
    }

    // ---------------------------------------------------------------------
    // Loading-screen tips, bottom-left
    // ---------------------------------------------------------------------
    Row {
        id: tipRow
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 44 * surface.ui
        spacing: 12 * surface.ui

        property var tips: [
            "Super + Space opens the app launcher.",
            "Super + Return opens a terminal. Add Shift for a floating one.",
            "Super + E opens the file manager, Super + B opens Firefox.",
            "Super + F toggles fullscreen. Super + V lets a window float.",
            "Print captures the screen. Shift + Print grabs a region, Alt + Print a window.",
            "Super + Q closes the focused window.",
            "Hover the hearts on the bar to see the exact CPU load.",
            "A wrong password costs a heart. Lose all three and you must rest for 10 minutes."
        ]
        property int tipIndex: Math.floor(Math.random() * tips.length)

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: "diamond"
            size: 12 * surface.ui
            color: Theme.amber
        }

        Text {
            id: tipText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, surface.width - prompts.width - 150 * surface.ui)
            text: tipRow.tips[tipRow.tipIndex]
            elide: Text.ElideRight
            font.family: Theme.fontDisplay
            font.pixelSize: 16 * surface.ui
            font.italic: true
            color: Theme.textSecondary
        }

        Timer {
            interval: 8000
            running: true
            repeat: true
            onTriggered: tipSwap.restart()
        }

        SequentialAnimation {
            id: tipSwap
            NumberAnimation { target: tipText; property: "opacity"; to: 0; duration: 350 }
            ScriptAction { script: tipRow.tipIndex = (tipRow.tipIndex + 1) % tipRow.tips.length }
            NumberAnimation { target: tipText; property: "opacity"; to: 1; duration: 350 }
        }
    }

    // ---------------------------------------------------------------------
    // Button prompts, bottom-right
    // ---------------------------------------------------------------------
    Row {
        id: prompts
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 44 * surface.ui
        spacing: 22 * surface.ui

        Repeater {
            model: [
                { key: "Enter", label: "Unlock" },
                { key: "Esc", label: "Clear" }
            ]

            Row {
                spacing: 8 * surface.ui

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: keyText.implicitWidth + 16 * surface.ui
                    height: 26 * surface.ui
                    radius: height / 2
                    color: "#26eef3d6"
                    border.width: 1
                    border.color: "#99eef3d6"

                    Text {
                        id: keyText
                        anchors.centerIn: parent
                        text: modelData.key
                        font.family: Theme.fontUi
                        font.pixelSize: 12 * surface.ui
                        font.bold: true
                        color: Theme.sunbeam
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    font.family: Theme.fontDisplay
                    font.pixelSize: 16 * surface.ui
                    color: Theme.textSecondary
                }
            }
        }
    }

    // Warp-out flash on success
    Rectangle {
        anchors.fill: parent
        color: Theme.sunbeam
        opacity: surface.lock && surface.lock.unlocking ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InQuad } }
    }

    // ---------------------------------------------------------------------
    // Keyboard input (hidden; the diamonds above are the visible field)
    // ---------------------------------------------------------------------
    TextInput {
        id: input
        width: 1
        height: 1
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        readOnly: surface.lock ? (surface.lock.authenticating || surface.lock.unlocking) : false

        onTextEdited: if (surface.lock) surface.lock.buffer = text
        Keys.onReturnPressed: if (surface.lock) surface.lock.submit()
        Keys.onEnterPressed: if (surface.lock) surface.lock.submit()
        Keys.onEscapePressed: if (surface.lock) surface.lock.buffer = ""

        Connections {
            target: surface.lock
            function onBufferChanged() {
                if (input.text !== surface.lock.buffer) input.text = surface.lock.buffer;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }

    Component.onCompleted: input.forceActiveFocus()
}
