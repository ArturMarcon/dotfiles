import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.UPower

// Battery as a stamina wheel.
Item {
    id: staminaRoot
    property var device: UPower.displayDevice
    property bool hasBattery: device !== null && device.isPresent

    visible: hasBattery
    implicitWidth: hasBattery ? panel.width : 0
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

    property double pct: device ? device.percentage : 1.0
    property int pctNum: Math.round(pct * 100)
    property bool isCharging: device && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
    property bool isLow: pctNum <= 20 && !isCharging

    property color wheelColor: {
        if (isCharging) return Theme.sunlit;
        if (isLow) return Theme.crimson;
        if (pctNum <= 40) return Theme.amber;
        return Theme.stamina;
    }

    HudPanel {
        id: panel
        width: row.implicitWidth + 18
        height: Theme.pillHeight
        fillColor: area.containsMouse ? Theme.panelHover : Theme.panelFill
        strokeColor: area.containsMouse ? staminaRoot.wheelColor : (staminaRoot.isLow ? Theme.crimson : Theme.panelStroke)

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6

            Item {
                id: wheel
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                // Exhausted: the wheel flashes
                SequentialAnimation on opacity {
                    running: staminaRoot.isLow
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                    onStopped: wheel.opacity = 1.0
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Theme.staminaTrack
                        strokeWidth: 3.5
                        PathAngleArc {
                            centerX: 9; centerY: 9
                            radiusX: 7; radiusY: 7
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: staminaRoot.wheelColor
                        strokeWidth: 3.5
                        capStyle: ShapePath.FlatCap
                        PathAngleArc {
                            centerX: 9; centerY: 9
                            radiusX: 7; radiusY: 7
                            startAngle: -90
                            sweepAngle: 360 * Math.max(0, Math.min(1, staminaRoot.pct))
                            Behavior on sweepAngle { NumberAnimation { duration: Theme.animDurationSlow; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                Glyph {
                    anchors.centerIn: parent
                    name: "bolt"
                    size: 9
                    color: Theme.sunbeam
                    visible: staminaRoot.isCharging
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: staminaRoot.pctNum + "%"
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: staminaRoot.isLow ? Theme.heartLight : Theme.textPrimary
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
