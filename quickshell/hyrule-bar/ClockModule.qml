import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell._Window
import Quickshell.Hyprland

Item {
    id: clockRoot
    implicitWidth: clockPanel.width
    implicitHeight: Theme.pillHeight
    width: implicitWidth
    height: implicitHeight

    property var barWindow: null
    property bool calendarOpen: false
    property double lastCloseTime: 0

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

    function updateTime() {
        var d = new Date();
        var hours = d.getHours().toString().padStart(2, '0');
        var mins = d.getMinutes().toString().padStart(2, '0');
        timeStr = hours + ":" + mins;
        isDaytime = d.getHours() >= 6 && d.getHours() < 18;

        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        dateStr = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
        fullDateStr = d.toLocaleDateString(Qt.locale(), Locale.LongFormat);
    }

    function updateCalendarGrid() {
        var days = [];
        var firstDay = new Date(displayYear, displayMonth, 1);
        var startDayOfWeek = firstDay.getDay(); // 0 (Sun) to 6 (Sat)
        var daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate();
        var daysInPrevMonth = new Date(displayYear, displayMonth, 0).getDate();

        // Previous month trailing days
        for (var i = startDayOfWeek - 1; i >= 0; i--) {
            days.push({ dayNumber: daysInPrevMonth - i, isCurrentMonth: false, isToday: false });
        }

        // Current month days
        var today = new Date();
        for (var d = 1; d <= daysInMonth; d++) {
            var isToday = (today.getFullYear() === displayYear && today.getMonth() === displayMonth && today.getDate() === d);
            days.push({ dayNumber: d, isCurrentMonth: true, isToday: isToday });
        }

        // Next month leading days to complete 6 rows of 7 days (42 cells total)
        var remaining = 42 - days.length;
        for (var n = 1; n <= remaining; n++) {
            days.push({ dayNumber: n, isCurrentMonth: false, isToday: false });
        }
        calendarDays = days;
    }

    function prevMonth() {
        if (displayMonth === 0) {
            displayMonth = 11;
            displayYear -= 1;
        } else {
            displayMonth -= 1;
        }
        updateCalendarGrid();
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0;
            displayYear += 1;
        } else {
            displayMonth += 1;
        }
        updateCalendarGrid();
    }

    function getMonthName(m) {
        var names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        return names[m] || "";
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

    // Time-of-Day Plate
    HudPanel {
        id: clockPanel
        width: clockRow.implicitWidth + 26
        height: Theme.pillHeight
        cut: 7
        fillColor: clockRoot.calendarOpen ? Theme.panelActive : (clockArea.containsMouse ? Theme.panelHover : Theme.panelFill)
        strokeColor: clockRoot.calendarOpen || clockArea.containsMouse ? Theme.sunlit : Theme.panelStroke

        RowLayout {
            id: clockRow
            anchors.centerIn: parent
            spacing: 8

            Glyph {
                name: clockRoot.isDaytime ? "sun" : "moon"
                size: 15
                color: clockRoot.isDaytime ? Theme.amber : Theme.shrineTeal
            }

            Text {
                text: clockRoot.timeStr
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: Theme.sunbeam
            }

            Glyph {
                name: "diamond"
                size: 6
                color: Theme.leaf
            }

            Text {
                text: clockRoot.dateStr
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
            }
        }

        MouseArea {
            id: clockArea
            anchors.fill: parent
            hoverEnabled: true
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
    }

    // Month Calendar Popup
    PopupWindow {
        id: calPopup
        visible: clockRoot.calendarOpen
        color: "transparent"
        implicitWidth: 320
        implicitHeight: 376
        anchor.window: clockRoot.barWindow
        anchor.rect.x: clockRoot.mapToItem(null, 0, 0).x - (320 - clockPanel.width) / 2
        anchor.rect.y: Theme.barHeight + 4

        onClosed: {
            clockRoot.lastCloseTime = Date.now();
            clockRoot.calendarOpen = false;
        }

        HudPanel {
            anchors.fill: parent
            cut: 12
            fillColor: Theme.popupFill
            strokeColor: Theme.popupStroke

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                // Time & Date Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Glyph {
                        name: clockRoot.isDaytime ? "sun" : "moon"
                        size: 26
                        color: clockRoot.isDaytime ? Theme.amber : Theme.shrineTeal
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: clockRoot.timeStr
                            font.family: Theme.fontDisplay
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.sunbeam
                        }
                        Text {
                            text: clockRoot.fullDateStr
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeSmall
                            font.italic: true
                            color: Theme.leaf
                        }
                    }
                }

                Flourish {
                    Layout.fillWidth: true
                }

                // Month & Year Navigation
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    HudPanel {
                        width: 28
                        height: 28
                        cut: 4
                        fillColor: prevBtnArea.containsMouse ? Theme.panelHover : "transparent"
                        strokeColor: prevBtnArea.containsMouse ? Theme.leaf : "transparent"

                        Glyph {
                            anchors.centerIn: parent
                            name: "chevron-left"
                            size: 13
                            color: prevBtnArea.containsMouse ? Theme.sunlit : Theme.textPrimary
                        }

                        MouseArea {
                            id: prevBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: clockRoot.prevMonth()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: clockRoot.getMonthName(clockRoot.displayMonth) + " " + clockRoot.displayYear
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.sunlit
                    }

                    HudPanel {
                        width: 28
                        height: 28
                        cut: 4
                        fillColor: nextBtnArea.containsMouse ? Theme.panelHover : "transparent"
                        strokeColor: nextBtnArea.containsMouse ? Theme.leaf : "transparent"

                        Glyph {
                            anchors.centerIn: parent
                            name: "chevron-right"
                            size: 13
                            color: nextBtnArea.containsMouse ? Theme.sunlit : Theme.textPrimary
                        }

                        MouseArea {
                            id: nextBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: clockRoot.nextMonth()
                        }
                    }
                }

                // Days of Week Header Row
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Repeater {
                        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                        delegate: Item {
                            width: 36
                            height: 20
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontDisplay
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.fern
                            }
                        }
                    }
                }

                // 6x7 Month Grid
                Grid {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: clockRoot.calendarDays
                        delegate: HudPanel {
                            id: dayCell
                            width: 36
                            height: 30
                            cut: 4
                            fillColor: {
                                if (modelData.isToday) return Theme.sunlit;
                                if (dayArea.containsMouse) return Theme.panelHover;
                                return "transparent";
                            }
                            strokeColor: {
                                if (modelData.isToday) return Theme.sunbeam;
                                if (dayArea.containsMouse) return Theme.leaf;
                                return "transparent";
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.dayNumber
                                font.family: Theme.fontDisplay
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: modelData.isToday || modelData.isCurrentMonth
                                color: {
                                    if (modelData.isToday) return Theme.abyss;
                                    if (!modelData.isCurrentMonth) return Theme.textMuted;
                                    return Theme.textPrimary;
                                }
                                opacity: modelData.isCurrentMonth ? 1.0 : 0.5
                            }

                            MouseArea {
                                id: dayArea
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
