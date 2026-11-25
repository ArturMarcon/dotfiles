import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "."

Scope {
    id: root

    property bool authenticating: false
    property bool authFailed: false
    property bool unlocking: false
    property string statusMessage: "Incantation Required to Dispel Barrier"
    property string errorMessage: ""
    property string pendingPassword: ""

    // PAM Context for Wayland session authentication
    PamContext {
        id: pam
        onPamMessage: (msg, isErr, respReq, respVis) => {
            if (msg && !isErr) root.statusMessage = msg;
            if (respReq && root.pendingPassword !== "") {
                pam.respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }
        onResponseRequiredChanged: {
            if (pam.responseRequired && root.pendingPassword !== "") {
                pam.respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }
        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.authenticating = false;
                root.authFailed = false;
                root.unlocking = true;
                root.statusMessage = "Incantation verified. Shattering barrier...";
                unlockTimer.start();
            } else {
                root.authenticating = false;
                root.authFailed = true;
                root.errorMessage = (result === PamResult.MaxTries)
                    ? "Mana depleted: Maximum spell attempts exceeded"
                    : "Spell rejected: Invalid incantation signature";
                failTimer.start();
            }
        }
        onError: (error) => {
            root.authenticating = false;
            root.authFailed = true;
            root.errorMessage = "Arcane barrier error: " + PamError.toString(error);
            failTimer.start();
        }
    }

    Timer {
        id: unlockTimer
        interval: 480
        repeat: false
        onTriggered: {
            sessionLock.locked = false;
            Qt.callLater(() => { Qt.quit(); });
        }
    }

    Timer {
        id: failTimer
        interval: 3500
        repeat: false
        onTriggered: {
            root.authFailed = false;
            root.errorMessage = "";
            root.statusMessage = "Incantation Required to Dispel Barrier";
        }
    }

    // Digital Clock & Date Tracker
    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateClock()
    }

    property string timeString: "12:00"
    property string dateString: "Wednesday, July 15"

    function updateClock() {
        var d = new Date();
        var h = d.getHours().toString().padStart(2, '0');
        var m = d.getMinutes().toString().padStart(2, '0');
        root.timeString = h + ":" + m;

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        root.dateString = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
    }

    function submitIncantation(passwordText) {
        if (root.unlocking || root.authenticating) return;
        if (!passwordText || passwordText.length === 0) return;

        root.authFailed = false;
        root.errorMessage = "";
        root.authenticating = true;
        root.statusMessage = "Weaving incantation... Verifying mana signature...";
        root.pendingPassword = passwordText;

        if (!pam.active) {
            pam.start();
        } else if (pam.responseRequired) {
            pam.respond(root.pendingPassword);
            root.pendingPassword = "";
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: lockSurface

            // Ensure typing clicks focus the password field
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    incantationInput.forceActiveFocus();
                }
            }

            // Deep Obsidian Night & Starfield Background
            Rectangle {
                anchors.fill: parent
                color: "#070a14"
            }

            // Center Mystical Mana Aura Gradient Halo
            Rectangle {
                width: Math.min(parent.width, parent.height) * 1.3
                height: width
                radius: width / 2
                anchors.centerIn: parent
                color: "transparent"
                opacity: root.unlocking ? 0.8 : (root.authenticating ? 0.5 : 0.25)
                Behavior on opacity { NumberAnimation { duration: 400 } }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.mainColor
                    opacity: 0.05
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.7
                    height: width
                    radius: width / 2
                    color: Theme.himmelBlue
                    opacity: 0.04
                }
            }

            // Floating Starfield & Mana Particles
            Item {
                anchors.fill: parent
                Repeater {
                    model: 45
                    delegate: Item {
                        x: ((index * 173 + 89) % (parent.width || 1920))
                        y: ((index * 269 + 43) % (parent.height || 1080))
                        width: (index % 3) + 2
                        height: width
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: (index % 4 === 0) ? Theme.zoltraakGold : ((index % 3 === 0) ? Theme.himmelBlue : Theme.textPrimary)
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: 0.15
                                to: 0.85
                                duration: 1200 + (index % 5) * 600
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: 0.85
                                to: 0.15
                                duration: 1200 + (index % 5) * 600
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }

            // Massive Rotating Arcane Spell Circle (Background Centerpiece)
            Item {
                width: Math.min(parent.width, parent.height) * 0.75
                height: width
                anchors.centerIn: parent
                opacity: root.unlocking ? 1.0 : 0.45
                Behavior on opacity { NumberAnimation { duration: 500 } }

                // Outer Runic Ring
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.authFailed ? Theme.starkRed : (root.authenticating ? Theme.zoltraakGold : Theme.arcaneViolet)
                    opacity: 0.6
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: root.authenticating || root.unlocking ? 8000 : 45000
                        loops: Animation.Infinite
                    }

                    Repeater {
                        model: ["◈", "✧", "❖", "✦", "◈", "✧", "❖", "✦"]
                        delegate: Text {
                            text: modelData
                            font.pixelSize: 16
                            color: root.authenticating ? Theme.zoltraakGold : Theme.textSecondary
                            x: (parent.width / 2) + (parent.width / 2 - 14) * Math.cos(index * Math.PI / 4) - width / 2
                            y: (parent.height / 2) + (parent.height / 2 - 14) * Math.sin(index * Math.PI / 4) - height / 2
                        }
                    }
                }

                // Counter-Rotating Geometric Hexagram / Square Seal
                Rectangle {
                    width: parent.width * 0.72
                    height: width
                    anchors.centerIn: parent
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.himmelBlue
                    opacity: 0.4
                    rotation: 45

                    RotationAnimation on rotation {
                        from: 360
                        to: 0
                        duration: root.authenticating || root.unlocking ? 6000 : 35000
                        loops: Animation.Infinite
                    }
                }

                // Second Geometric Square Rotated 0 Deg
                Rectangle {
                    width: parent.width * 0.72
                    height: width
                    anchors.centerIn: parent
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.zoltraakGold
                    opacity: 0.35

                    RotationAnimation on rotation {
                        from: 0
                        to: -360
                        duration: root.authenticating || root.unlocking ? 6000 : 35000
                        loops: Animation.Infinite
                    }
                }

                // Inner Concentric Circle
                Rectangle {
                    width: parent.width * 0.48
                    height: width
                    radius: width / 2
                    anchors.centerIn: parent
                    color: "transparent"
                    border.width: 2
                    border.color: root.authenticating ? Theme.zoltraakGold : Theme.borderActive
                    opacity: 0.5
                }
            }

            // Top Section: Celestial Timepiece & Date
            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: Math.max(40, parent.height * 0.08)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                opacity: root.unlocking ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 220 } }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.timeString
                    font.family: Theme.fontFamily
                    font.pixelSize: 84
                    font.weight: Font.ExtraBold
                    color: Theme.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.dateString
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                    font.letterSpacing: 1
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    height: 28
                    width: eraText.implicitWidth + 28
                    radius: 14
                    color: root.authFailed ? "#25ef4444" : "#1a161f36"
                    border.width: 1
                    border.color: root.authFailed ? Theme.starkRed : Theme.borderSubtle
                    Behavior on color { ColorAnimation { duration: 250 } }
                    Behavior on border.color { ColorAnimation { duration: 250 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: root.authFailed ? "⚠" : (root.authenticating ? "❖" : "✧")
                            font.pixelSize: 14
                            color: root.authFailed ? Theme.starkRed : (root.authenticating ? Theme.zoltraakGold : Theme.himmelBlue)
                        }
                        Text {
                            id: eraText
                            text: root.authFailed ? "Arcane Barrier Disturbed • Unauthorized Mana Signature" :
                                  (root.authenticating ? "Authenticating Spell Signature..." : "Arcane Defense Barrier Active • Frieren Grimoire")
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.authFailed ? Theme.starkRed : (root.authenticating ? Theme.zoltraakGold : Theme.textSecondary)
                        }
                    }
                }
            }

            // Center Section: The Incantation Seal (Login Box)
            Rectangle {
                id: loginCard
                width: 440
                height: 430
                radius: 24
                anchors.centerIn: parent
                color: Theme.bgPanelTranslucent
                opacity: root.unlocking ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                border.width: 1
                border.color: root.authFailed ? Theme.starkRed :
                              (root.authenticating ? Theme.zoltraakGold :
                              (incantationInput.activeFocus ? Theme.borderActive : Theme.borderSubtle))

                Behavior on border.color { ColorAnimation { duration: 200 } }

                // Subtle inner glow when authenticating
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: "transparent"
                    border.width: root.authenticating ? 2 : 0
                    border.color: Theme.arcaneViolet
                    opacity: root.authenticating ? 0.6 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 64
                    spacing: 18

                    // Mage Avatar Seal Ring
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        width: 104
                        height: 104

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: incantationInput.activeFocus || root.authenticating ? Theme.zoltraakGold : Theme.borderSubtle
                            opacity: incantationInput.activeFocus || root.authenticating ? 0.8 : 0.3

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: root.authenticating ? 2000 : (incantationInput.activeFocus ? 6000 : 20000)
                                loops: Animation.Infinite
                            }
                        }

                        Rectangle {
                            width: 84
                            height: 84
                            radius: width / 2
                            anchors.centerIn: parent
                            color: Theme.bgWidget
                            border.width: 2
                            border.color: root.authFailed ? Theme.starkRed : (root.authenticating ? Theme.zoltraakGold : Theme.arcaneViolet)
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            Text {
                                anchors.centerIn: parent
                                text: "🜲"
                                font.pixelSize: 40
                                color: root.authFailed ? Theme.starkRed : (root.authenticating ? Theme.zoltraakGold : Theme.textPrimary)
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: pam.user !== "" ? pam.user : "First-Class Mage"
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Arcane Seal Authentication"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.textSecondary
                        }
                    }

                    // Incantation Input Field Box
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 12
                        color: incantationInput.activeFocus ? "#30161f36" : "#20161f36"
                        border.width: incantationInput.activeFocus || root.authenticating ? 2 : 1
                        border.color: root.authFailed ? Theme.starkRed :
                                      (root.authenticating ? Theme.zoltraakGold :
                                      (incantationInput.activeFocus ? Theme.borderActive : Theme.borderSubtle))

                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                text: root.authenticating ? "❖" : "✧"
                                font.pixelSize: 18
                                color: root.authFailed ? Theme.starkRed : (incantationInput.activeFocus || root.authenticating ? Theme.zoltraakGold : Theme.textMuted)

                                RotationAnimation on rotation {
                                    running: root.authenticating
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }
                            }

                            TextInput {
                                id: incantationInput
                                objectName: "incantationInput"
                                Layout.fillWidth: true
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: Theme.textPrimary
                                echoMode: TextInput.Password
                                passwordCharacter: "◈"
                                focus: true
                                enabled: !root.authenticating && !root.unlocking

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Enter secret incantation..."
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    color: Theme.textMuted
                                    visible: incantationInput.text.length === 0 && !incantationInput.preeditText
                                }

                                Keys.onReturnPressed: root.submitIncantation(incantationInput.text)
                                Keys.onEnterPressed: root.submitIncantation(incantationInput.text)
                                Keys.onEscapePressed: {
                                    incantationInput.text = "";
                                    root.authFailed = false;
                                    root.errorMessage = "";
                                }
                                onTextChanged: {
                                    if (root.authFailed) {
                                        root.authFailed = false;
                                        root.errorMessage = "";
                                    }
                                }
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: submitArea.containsMouse ? Theme.bgWidgetHover : "transparent"
                                visible: incantationInput.text.length > 0
                                Text {
                                    anchors.centerIn: parent
                                    text: "✦"
                                    font.pixelSize: 16
                                    color: Theme.zoltraakGold
                                }
                                MouseArea {
                                    id: submitArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.submitIncantation(incantationInput.text)
                                }
                            }
                        }
                    }

                    // Message Box
                    Item {
                        Layout.fillWidth: true
                        height: 32
                        Text {
                            anchors.centerIn: parent
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.authFailed ? root.errorMessage :
                                  (root.authenticating ? root.statusMessage :
                                  "Press [Enter] to weave spell or [Esc] to clear")
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: root.authFailed ? Font.Bold : Font.Normal
                            color: root.authFailed ? Theme.starkRed :
                                   (root.authenticating ? Theme.zoltraakGold : Theme.textMuted)
                        }
                    }

                    // Action Buttons Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            id: dispelBtn
                            Layout.fillWidth: true
                            height: 42
                            radius: 10
                            color: dispelArea.containsMouse ? Theme.bgWidgetHover : Theme.arcaneViolet
                            border.width: 1
                            border.color: dispelArea.containsMouse ? Theme.zoltraakGold : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "✦"
                                    font.pixelSize: 14
                                    color: Theme.textPrimary
                                }
                                Text {
                                    text: "Dispel Barrier"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: Theme.textPrimary
                                }
                            }
                            MouseArea {
                                id: dispelArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.submitIncantation(incantationInput.text)
                            }
                        }

                        Rectangle {
                            id: clearBtn
                            width: 76
                            height: 42
                            radius: 10
                            color: clearArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget
                            border.width: 1
                            border.color: clearArea.containsMouse ? Theme.borderActive : Theme.borderSubtle
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Clear"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Theme.textSecondary
                            }
                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    incantationInput.text = "";
                                    incantationInput.forceActiveFocus();
                                    root.authFailed = false;
                                    root.errorMessage = "";
                                }
                            }
                        }

                        Rectangle {
                            id: suspendBtn
                            width: 42
                            height: 42
                            radius: 10
                            color: suspendArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget
                            border.width: 1
                            border.color: suspendArea.containsMouse ? Theme.arcaneViolet : Theme.borderSubtle
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "\uf186"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                color: suspendArea.containsMouse ? Theme.zoltraakGold : Theme.textSecondary
                            }
                            MouseArea {
                                id: suspendArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    Quickshell.execDetached(["systemctl", "suspend"]);
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Indicators Footer
            RowLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 28

                RowLayout {
                    spacing: 6
                    Text {
                        text: "◈"
                        font.pixelSize: 14
                        color: Theme.arcaneViolet
                    }
                    Text {
                        text: "Wayland SessionLock Active"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.borderSubtle
                }

                RowLayout {
                    spacing: 6
                    Text {
                        text: "❖"
                        font.pixelSize: 14
                        color: Theme.emeraldGreen
                    }
                    Text {
                        text: "Mana Flow & Defense Matrix: Stable"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.borderSubtle
                }

                RowLayout {
                    spacing: 6
                    Text {
                        text: "✧"
                        font.pixelSize: 14
                        color: Theme.zoltraakGold
                    }
                    Text {
                        text: "Quickshell Arcane Engine v0.3"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }
                }
            }

            // Zoltraak Shatter Dispel Effect on Unlock
            Rectangle {
                id: dispelWave
                width: root.unlocking ? Math.max(parent.width, parent.height) * 2.5 : 0
                height: width
                radius: width / 2
                anchors.centerIn: parent
                color: Theme.zoltraakGold
                opacity: root.unlocking ? 1.0 : 0.0

                Behavior on width {
                    NumberAnimation { duration: 480; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
            }
        }
    }
}
