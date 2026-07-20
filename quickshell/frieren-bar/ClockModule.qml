import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell._Window
import Quickshell.Hyprland

Item {
    id: clockRoot
    implicitWidth: width
    implicitHeight: height
    width: clockPill.width
    height: Theme.pillHeight

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

    property int displayYear: 2026
    property int displayMonth: 0
    property var calendarDays: []

    function updateTime() {
        var d = new Date();
        var hours = d.getHours().toString().padStart(2, '0');
        var mins = d.getMinutes().toString().padStart(2, '0');
        timeStr = hours + ":" + mins;
        
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

    // Clock Capsule Pill
    Rectangle {
        id: clockPill
        implicitWidth: width
        implicitHeight: height
        width: clockRow.implicitWidth + 24
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: clockRoot.calendarOpen ? Theme.bgWidgetActive : (clockArea.containsMouse ? Theme.bgWidgetHover : Theme.bgWidget)
        border.width: 1
        border.color: clockRoot.calendarOpen ? Theme.arcaneViolet : (clockArea.containsMouse ? Theme.borderActive : Theme.borderSubtle)

        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Glow aura
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.arcaneViolet
            opacity: clockRoot.calendarOpen ? 0.45 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
        }

        RowLayout {
            id: clockRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "\uf017" // nf-fa-clock
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
                color: Theme.arcaneViolet
            }

            Text {
                text: clockRoot.timeStr
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                color: Theme.textPrimary
            }

            Rectangle {
                width: 3
                height: 3
                radius: 1.5
                color: Theme.zoltraakGold
            }

            Text {
                text: clockRoot.dateStr
                font.family: Theme.fontFamily
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

    // Interactive Month Calendar Popup
    PopupWindow {
        id: calPopup
        visible: clockRoot.calendarOpen
        color: "transparent"
        implicitWidth: 320
        implicitHeight: 370
        anchor.window: clockRoot.barWindow
        anchor.rect.x: clockRoot.mapToItem(null, 0, 0).x - (320 - clockPill.width) / 2
        anchor.rect.y: Theme.barHeight + 4

        onClosed: {
            clockRoot.lastCloseTime = Date.now();
            clockRoot.calendarOpen = false;
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.bgPanelTranslucent
            border.width: 1
            border.color: Theme.arcaneViolet

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 12
                color: "transparent"
                border.width: 1
                border.color: Theme.borderSubtle
                opacity: 0.6
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Top Time & Date Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "\uf133" // nf-fa-calendar
                        font.family: Theme.fontFamily
                        font.pixelSize: 22
                        color: Theme.zoltraakGold
                    }
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: clockRoot.timeStr
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: clockRoot.fullDateStr
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.arcaneViolet
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderSubtle
                }

                // Month & Year Navigation Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Previous Month Arrow Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: prevBtnArea.containsMouse ? Theme.bgWidgetHover : "transparent"
                        border.width: 1
                        border.color: prevBtnArea.containsMouse ? Theme.borderActive : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf053" // nf-fa-chevron_left
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: prevBtnArea.containsMouse ? Theme.zoltraakGold : Theme.textPrimary
                        }

                        MouseArea {
                            id: prevBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: clockRoot.prevMonth()
                        }
                    }

                    // Month and Year Title
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: clockRoot.getMonthName(clockRoot.displayMonth) + " " + clockRoot.displayYear
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.zoltraakGold
                    }

                    // Next Month Arrow Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: nextBtnArea.containsMouse ? Theme.bgWidgetHover : "transparent"
                        border.width: 1
                        border.color: nextBtnArea.containsMouse ? Theme.borderActive : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf054" // nf-fa-chevron_right
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: nextBtnArea.containsMouse ? Theme.zoltraakGold : Theme.textPrimary
                        }

                        MouseArea {
                            id: nextBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: clockRoot.nextMonth()
                        }
                    }
                }

                // Days of Week Header Row (Su Mo Tu We Th Fr Sa)
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
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.arcaneViolet
                            }
                        }
                    }
                }

                // 6x7 Month Grid (42 total day cells)
                Grid {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: clockRoot.calendarDays
                        delegate: Rectangle {
                            id: dayCell
                            width: 36
                            height: 30
                            radius: 6
                            color: {
                                if (modelData.isToday) return Theme.zoltraakGold;
                                if (dayArea.containsMouse) return Theme.bgWidgetHover;
                                return "transparent";
                            }
                            border.width: 1
                            border.color: {
                                if (modelData.isToday) return Theme.zoltraakGold;
                                if (dayArea.containsMouse) return Theme.borderActive;
                                return "transparent";
                            }

                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.dayNumber
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: modelData.isToday || modelData.isCurrentMonth
                                color: {
                                    if (modelData.isToday) return "#161f36"; // dark high contrast on golden cell
                                    if (!modelData.isCurrentMonth) return Theme.textMuted;
                                    return Theme.textPrimary;
                                }
                                opacity: modelData.isCurrentMonth ? 1.0 : 0.45
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
