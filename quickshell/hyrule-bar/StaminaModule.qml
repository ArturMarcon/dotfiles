import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery as the stamina wheel: green, amber when tiring, flashing red when
// nearly spent, lime while charging.
LitWheel {
    id: staminaRoot
    property var device: UPower.displayDevice
    property bool hasBattery: device !== null && device.isPresent

    property double pct: device ? device.percentage : 1.0
    property int pctNum: Math.round(pct * 100)
    property bool isCharging: device && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
    property bool isLow: pctNum <= 20 && !isCharging

    visible: hasBattery
    implicitWidth: hasBattery ? Theme.wheelSize : 0

    accent: {
        if (isCharging) return Theme.sunlit;
        if (isLow) return Theme.crimson;
        if (pctNum <= 40) return Theme.amber;
        return Theme.stamina;
    }
    value: pct
    glyph: isCharging ? "bolt" : "stamina"
    label: pctNum.toString()
    flashing: isLow

    onClicked: flare()
}
