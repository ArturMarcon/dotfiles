import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "."

Scope {
    id: root

    // Shared state, read by the LockSurface on every monitor
    property string buffer: ""
    property bool authenticating: false
    property bool failed: false
    property bool unlocking: false
    property string pendingPassword: ""
    readonly property string user: Quickshell.env("USER")

    signal damaged()

    // Heart containers mirror pam_faillock (Arch defaults in /etc/security/faillock.conf):
    // 3 failures within 15 minutes lock the account for 10 minutes.
    readonly property int maxHearts: 3
    readonly property int lockoutSeconds: 600
    property int heartsLeft: maxHearts
    property double lockedUntil: 0
    property double now: Date.now()
    readonly property int lockoutRemaining: Math.max(0, Math.ceil((lockedUntil - now) / 1000))
    // Once the lockout has passed, faillock allows another try before the old failures expire
    readonly property int heartsShown: (heartsLeft === 0 && lockoutRemaining === 0) ? 1 : heartsLeft

    // Time of day
    property string timeStr: ""
    property string dateStr: ""
    property bool isDaytime: true

    function tick() {
        var d = new Date();
        now = d.getTime();
        timeStr = d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
        isDaytime = d.getHours() >= 6 && d.getHours() < 18;

        var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        dateStr = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    // Count recent failures straight from the faillock tally
    Process {
        id: faillockProc
        command: ["faillock", "--user", root.user]
        stdout: StdioCollector {
            onStreamFinished: root.parseFaillock(text)
        }
    }

    function parseFaillock(out) {
        var valid = 0, latest = 0;
        out.split("\n").forEach(function (line) {
            var m = line.match(/^(\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d)\s.*\s([VI])\s*$/);
            if (!m || m[3] !== "V") return;
            valid++;
            latest = Math.max(latest, new Date(m[1] + "T" + m[2]).getTime());
        });
        heartsLeft = Math.max(0, maxHearts - valid);
        lockedUntil = valid >= maxHearts ? latest + lockoutSeconds * 1000 : 0;
    }

    Component.onCompleted: faillockProc.running = true

    // PAM Context for Wayland session authentication
    PamContext {
        id: pam
        onPamMessage: (msg, isErr, respReq, respVis) => {
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
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.unlocking = true;
                unlockTimer.start();
            } else {
                root.takeDamage();
            }
        }
        onError: (error) => {
            root.authenticating = false;
            root.takeDamage();
        }
    }

    function submit() {
        if (unlocking || authenticating || buffer.length === 0 || lockoutRemaining > 0) return;
        failed = false;
        authenticating = true;
        pendingPassword = buffer;

        if (!pam.active) {
            pam.start();
        } else if (pam.responseRequired) {
            pam.respond(pendingPassword);
            pendingPassword = "";
        }
    }

    function takeDamage() {
        failed = true;
        buffer = "";
        damaged();
        faillockProc.running = true;
        failTimer.restart();
    }

    Timer {
        id: failTimer
        interval: 4000
        onTriggered: root.failed = false
    }

    Timer {
        id: unlockTimer
        interval: 520
        onTriggered: {
            sessionLock.locked = false;
            Qt.callLater(() => { Qt.quit(); });
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            color: "black"

            LockSurface {
                anchors.fill: parent
                lock: root
            }
        }
    }
}
