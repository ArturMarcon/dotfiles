import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell._Window
import Quickshell.Hyprland

// Time set like one of the game's area titles: serif between fading rules.
// Clicking opens the month in the pause-menu style.
Item {
    id: clockRoot
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.slotSize
    width: implicitWidth
    height: implicitHeight

    property var barWindow: null
    property bool compact: false
    property bool calendarOpen: false
    property double lastCloseTime: 0
    readonly property bool lit: calendarOpen || hover.hovered

    HyprlandFocusGrab {
        active: clockRoot.calendarOpen
        windows: [ calPopup ]
        onCleared: {
            clockRoot.calendarOpen = false;
        }
    }

    property string timeStr: ""
    property string dateStr: ""
    property string fullDateStr: ""
    property bool isDaytime: true

    property int displayYear: 2026
    property int displayMonth: 0
    property var calendarDays: []

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    function updateTime() {
        var d = new Date();
        timeStr = d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
        isDaytime = d.getHours() >= 6 && d.getHours() < 18;

        var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        dateStr = days[d.getDay()] + "  " + d.getDate() + " " + monthNames[d.getMonth()].slice(0, 3).toUpperCase();
        fullDateStr = d.toLocaleDateString(Qt.locale(), Locale.LongFormat);
    }

    // Monday-first 6x7 grid, padded with the neighbouring months
    function updateCalendarGrid() {
        var days = [];
        var lead = (new Date(displayYear, displayMonth, 1).getDay() + 6) % 7;
        var daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate();
        var daysInPrevMonth = new Date(displayYear, displayMonth, 0).getDate();
        var today = new Date();

        for (var i = lead - 1; i >= 0; i--)
            days.push({ dayNumber: daysInPrevMonth - i, isCurrentMonth: false, isToday: false });
        for (var d = 1; d <= daysInMonth; d++) {
            var isToday = today.getFullYear() === displayYear && today.getMonth() === displayMonth && today.getDate() === d;
            days.push({ dayNumber: d, isCurrentMonth: true, isToday: isToday });
        }
        for (var n = 1; days.length < 42; n++)
            days.push({ dayNumber: n, isCurrentMonth: false, isToday: false });
        calendarDays = days;
    }

    function shiftMonth(step) {
        var m = displayMonth + step;
        displayYear += Math.floor(m / 12);
        displayMonth = ((m % 12) + 12) % 12;
        updateCalendarGrid();
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: clockRoot.updateTime()
    }

    Component.onCompleted: {
        var now = new Date();
        displayYear = now.getFullYear();
        displayMonth = now.getMonth();
        updateTime();
        updateCalendarGrid();
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Rule {
            anchors.verticalCenter: parent.verticalCenter
            width: clockRoot.compact ? 26 : 70
            fadeLeft: true
            opacity: clockRoot.lit ? 1 : 0.8
        }

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: clockRoot.isDaytime ? "sun" : "moon"
            size: 15
            color: clockRoot.isDaytime ? Theme.amber : Theme.sheikah
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: clockRoot.timeStr
            font.family: Theme.fontDisplay
            font.pixelSize: 17
            font.bold: true
            color: clockRoot.lit ? "#ffffff" : Theme.hudText
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            text: clockRoot.dateStr
            font.family: Theme.fontUi
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1.5
            color: Theme.hudTextDim
        }

        Rule {
            anchors.verticalCenter: parent.verticalCenter
            width: clockRoot.compact ? 26 : 70
            opacity: clockRoot.lit ? 1 : 0.8
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (Date.now() - clockRoot.lastCloseTime < 200) return;
            if (!clockRoot.calendarOpen) {
                var now = new Date();
                clockRoot.displayYear = now.getFullYear();
                clockRoot.displayMonth = now.getMonth();
                clockRoot.updateCalendarGrid();
            }
            clockRoot.calendarOpen = !clockRoot.calendarOpen;
        }
    }

    PopupWindow {
        id: calPopup
        visible: clockRoot.calendarOpen
        color: "transparent"
        implicitWidth: 310
        implicitHeight: calMenu.implicitHeight
        anchor.item: clockRoot
        anchor.rect.x: (clockRoot.width - 310) / 2
        anchor.rect.y: clockRoot.height + (Theme.barHeight - clockRoot.height) / 2 + 4

        onClosed: {
            clockRoot.lastCloseTime = Date.now();
            clockRoot.calendarOpen = false;
        }

        MenuFrame {
            id: calMenu
            anchors.fill: parent
            title: clockRoot.timeStr
            subtitle: clockRoot.fullDateStr

            // Month navigation
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6

                ItemSlot {
                    Glyph {
                        anchors.centerIn: parent
                        name: "chevron-left"
                        size: 12
                        color: Theme.hudText
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: clockRoot.shiftMonth(-1)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: clockRoot.monthNames[clockRoot.displayMonth].toUpperCase() + "  " + clockRoot.displayYear
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    font.letterSpacing: 2.5
                    color: Theme.hudText
                }

                ItemSlot {
                    Glyph {
                        anchors.centerIn: parent
                        name: "chevron-right"
                        size: 12
                        color: Theme.hudText
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: clockRoot.shiftMonth(1)
                    }
                }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                    Text {
                        width: 36
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                        font.bold: true
                        color: index >= 5 ? Theme.textMuted : Theme.hudTextDim
                    }
                }
            }

            Grid {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
                columns: 7
                rowSpacing: 3
                columnSpacing: 2

                Repeater {
                    model: clockRoot.calendarDays

                    Item {
                        width: 36
                        height: 28

                        // Today is the selected slot; others show a frame on hover
                        ItemSlot {
                            anchors.centerIn: parent
                            width: 28
                            height: 24
                            active: modelData.isToday
                            visible: modelData.isToday || dayHover.hovered
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.dayNumber
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: modelData.isToday
                            color: modelData.isToday ? "#ffffff" : Theme.hudText
                            opacity: modelData.isCurrentMonth ? 1.0 : 0.3
                        }

                        HoverHandler {
                            id: dayHover
                        }
                    }
                }
            }
        }
    }
}
