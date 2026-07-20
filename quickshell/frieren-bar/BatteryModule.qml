import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
    id: batteryRoot
    property var device: UPower.displayDevice
    property bool hasBattery: device !== null && device.isPresent
    
    visible: hasBattery
    implicitWidth: width
    implicitHeight: height
    width: hasBattery ? batPill.width : 0
    height: Theme.pillHeight

    property double pct: device ? device.percentage : 1.0
    property int pctNum: Math.round(pct * 100)
    property bool isCharging: device && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
    property bool isLow: pctNum <= 20 && !isCharging

    property color manaColor: {
        if (isCharging) return Theme.emeraldGreen;
        if (pctNum > 50) return Theme.zoltraakGold;
        if (pctNum > 20) return Theme.arcaneViolet;
        return Theme.starkRed;
    }

    Rectangle {
        id: batPill
        implicitWidth: width
        implicitHeight: height
        width: batRow.implicitWidth + 24
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: batArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget
        border.width: batteryRoot.isLow ? 2 : 1
        border.color: batArea.containsMouse ? batteryRoot.manaColor : (batteryRoot.isLow ? Theme.starkRed : Theme.borderSubtle)

        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Pulsing danger glow when mana < 20%
        SequentialAnimation on border.color {
            loops: Animation.Infinite
            running: batteryRoot.isLow && !batArea.containsMouse
            ColorAnimation { to: Theme.starkRed; duration: 600 }
            ColorAnimation { to: Theme.bgWidget; duration: 600 }
        }

        // Mana gauge background pill at bottom
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            anchors.left: parent.left
            anchors.leftMargin: 6
            width: Math.max(0, (parent.width - 12) * batteryRoot.pct)
            height: 2
            radius: 1
            color: batteryRoot.manaColor
            opacity: 0.85
            Behavior on width { NumberAnimation { duration: Theme.animDurationNormal } }
        }

        RowLayout {
            id: batRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: {
                    if (batteryRoot.isCharging) return "\uf0e7";
                    if (batteryRoot.pctNum > 80) return "\uf240";
                    if (batteryRoot.pctNum > 60) return "\uf241";
                    if (batteryRoot.pctNum > 40) return "\uf242";
                    if (batteryRoot.pctNum > 20) return "\uf243";
                    return "\uf244";
                }
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: batteryRoot.manaColor
            }

            Text {
                text: batteryRoot.pctNum + "%"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: batteryRoot.isLow ? Theme.starkRed : Theme.textPrimary
            }
        }

        MouseArea {
            id: batArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
