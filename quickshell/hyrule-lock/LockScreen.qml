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

    // Heart containers mirror pam_faillock and read its limits from
    // /etc/security/faillock.conf: `deny` wrong passwords within
    // `fail_interval` lock the account for `unlock_time` seconds.
    FileView {
        id: faillockConf
        path: "/etc/security/faillock.conf"
        blockLoading: true
    }

    function confValue(key, fallback) {
        var m = faillockConf.text().match(new RegExp("^\\s*" + key + "\\s*=\\s*(\\d+)", "m"));
        return m ? parseInt(m[1]) : fallback;
    }

    readonly property int maxHearts: Math.max(1, confValue("deny", 3))
    readonly property int lockoutSeconds: confValue("unlock_time", 600)
    readonly property int failInterval: confValue("fail_interval", 900)

    // Valid failures in the tally (epoch ms); hearts don't animate until it's first read
    property var failureTimes: []
    property bool tallyLoaded: false
    property double now: Date.now()

    readonly property double latestFailure: failureTimes.length > 0 ? Math.max.apply(null, failureTimes) : 0
    // Locked once `deny` failures fall within fail_interval of the newest one
    readonly property bool tallyFull: failureTimes.filter(t => latestFailure - t < failInterval * 1000).length >= maxHearts
    // The lock runs from the newest failure; one spare second as faillock keeps whole seconds
    readonly property double lockedUntil: tallyFull ? latestFailure + (lockoutSeconds + 1) * 1000 : 0
    readonly property int lockoutRemaining: Math.max(0, Math.ceil((lockedUntil - now) / 1000))
    // Once the lock expires, the next failure wipes the old tally, so every heart comes back
    readonly property int heartsShown: lockoutRemaining > 0 ? 0
        : (tallyFull ? maxHearts : Math.max(0, maxHearts - failureTimes.filter(t => now - t < failInterval * 1000).length))

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
        var times = [];
        out.split("\n").forEach(function (line) {
            var m = line.match(/^(\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d)\s.*\s([VI])\s*$/);
            if (m && m[3] === "V") times.push(new Date(m[1] + "T" + m[2]).getTime());
        });
        failureTimes = times;
        tallyLoaded = true;
    }

    Component.onCompleted: faillockProc.running = true

    // PAM Context for Wayland session authentication
    // Own PAM service (pam/hyrule-lock): the system stack without the fail delay
    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "hyrule-lock"
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
                root.failed = false;
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
        // Count the hit at once, the way faillock records it; the tally re-read confirms it
        var t = Date.now();
        now = t;
        failureTimes = (tallyFull && lockoutRemaining === 0) ? [t]
            : failureTimes.filter(x => t - x < failInterval * 1000).concat([t]);
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
