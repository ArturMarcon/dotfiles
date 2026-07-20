import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    // =========================================================================
    // Native Wayland Session Lock (ext-session-lock-v1)
    // =========================================================================
    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"

            // PAM Authentication Context for Keyboard Password Verification
            PamContext {
                id: pam
                config: "login" // Uses /etc/pam.d/login for standard user password check

                onCompleted: result => {
                    if (result === PamResult.Success) {
                        console.log("[PAM] Authentication successful. Unlocking session lock...");
                        lockContent.triggerUnlock();
                    } else {
                        console.log("[PAM] Authentication failed or rejected.");
                        lockContent.authFailed = true;
                    }
                }
            }

            FantasyLockSurface {
                id: lockContent
                anchors.fill: parent
                isTestMode: false
                pamContext: pam

                onUnlockTriggered: {
                    sessionLock.locked = false;
                }
            }
        }
    }
}
