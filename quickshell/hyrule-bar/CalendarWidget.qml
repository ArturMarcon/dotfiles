import QtQuick
import Quickshell
import Quickshell.Io

// Desktop calendar: today, upcoming events from iCal feeds, and the month grid.
// Feeds come from scripts/calendar_events.py (see ~/.local/share/hyrule-bar/calendars.txt).
GlassPanel {
    id: calendar
    implicitWidth: 580
    implicitHeight: 276
    fill: Theme.widgetFill

    property var events: []
    property bool configured: true
    property string error: ""
    property var today: new Date()

    readonly property var feedColors: [Theme.sheikah, Theme.amber, Theme.heartLight, Theme.leaf]
    readonly property var dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    // ----------------------------------------------------------------- data

    Process {
        id: fetcher
        command: [Quickshell.shellDir + "/scripts/calendar_events.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text);
                    calendar.events = data.events;
                    calendar.configured = data.configured;
                    calendar.error = data.errors.length > 0 ? data.errors[0] : "";
                } catch (e) {
                    calendar.error = "Could not read calendar data";
                }
            }
        }
    }

    // Refetch every 15 minutes
    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetcher.running = true
    }

    // Roll over at midnight
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            if (now.getDate() !== calendar.today.getDate()) {
                calendar.today = now;
                fetcher.running = true;
            }
        }
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function clock(d) {
        return d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
    }

    function whenLabel(ev) {
        var start = new Date(ev.start), end = new Date(ev.end);
        var time = ev.allDay ? "All day" : clock(start) + " – " + clock(end);
        if (sameDay(start, today)) return time;
        var tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
        if (sameDay(start, tomorrow)) return "Tomorrow · " + time;
        var month = start.getMonth() !== today.getMonth() ? " " + monthNames[start.getMonth()].slice(0, 3) : "";
        return dayNames[start.getDay()].slice(0, 3) + " " + start.getDate() + month + " · " + time;
    }

    // Events that haven't ended yet, soonest first (three fit under the date)
    readonly property var upcoming: {
        var now = new Date();
        return events.filter(function (ev) { return new Date(ev.end) > now; }).slice(0, 3);
    }

    // Day numbers in this month that have at least one event
    readonly property var busyDays: {
        var days = {};
        var first = new Date(today.getFullYear(), today.getMonth(), 1);
        var next = new Date(today.getFullYear(), today.getMonth() + 1, 1);
        events.forEach(function (ev) {
            var d = new Date(ev.start);
            var end = new Date(ev.end);
            if (ev.allDay) end = new Date(end.getTime() - 1);
            for (d = new Date(d.getFullYear(), d.getMonth(), d.getDate()); d <= end; d.setDate(d.getDate() + 1)) {
                if (d >= first && d < next) days[d.getDate()] = true;
            }
        });
        return days;
    }

    // Monday-first grid; null pads the first week
    readonly property var cells: {
        var first = new Date(today.getFullYear(), today.getMonth(), 1);
        var count = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
        var list = [];
        for (var i = 0; i < (first.getDay() + 6) % 7; i++) list.push(null);
        for (var d = 1; d <= count; d++) list.push(d);
        return list;
    }

    // ------------------------------------------------------------- left side

    Item {
        id: leftSide
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 22
        width: 218

        Text {
            id: weekday
            text: calendar.dayNames[calendar.today.getDay()].toUpperCase()
            font.family: Theme.fontUi
            font.pixelSize: Theme.fontSizeSmall
            font.bold: true
            font.letterSpacing: 3
            color: Theme.hudTextDim
        }

        Text {
            id: dayNumber
            anchors.top: weekday.bottom
            anchors.topMargin: -4
            text: calendar.today.getDate()
            font.family: Theme.fontDisplay
            font.pixelSize: 58
            font.bold: true
            color: Theme.hudText
        }

        Column {
            anchors.top: dayNumber.bottom
            anchors.topMargin: 6
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            Repeater {
                model: calendar.upcoming

                Row {
                    spacing: 10
                    width: parent.width

                    // Diamond marker in the calendar's colour
                    Rectangle {
                        y: 5
                        width: 6
                        height: 6
                        rotation: 45
                        color: calendar.feedColors[modelData.feed % calendar.feedColors.length]
                    }

                    Column {
                        width: parent.width - 16

                        Text {
                            width: parent.width
                            text: modelData.title
                            elide: Text.ElideRight
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            color: Theme.hudText
                        }

                        Text {
                            text: calendar.whenLabel(modelData)
                            font.family: Theme.fontUi
                            font.pixelSize: 10
                            color: Theme.hudTextDim
                        }
                    }
                }
            }

            Text {
                visible: calendar.upcoming.length === 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: calendar.error !== "" ? calendar.error
                    : (calendar.configured ? "Nothing planned. The wilds await." : "Add a calendar link to ~/.local/share/hyrule-bar/calendars.txt")
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                color: calendar.error !== "" ? Theme.heartLight : Theme.hudTextDim
            }
        }
    }

    // Divider, fading out at both ends
    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 26
        x: Math.round((leftSide.x + leftSide.width + monthGrid.x) / 2)
        width: 1
        opacity: 0.45
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.hudText }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ------------------------------------------------------------ month grid

    Column {
        id: monthGrid
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 6

        // Month set like an area title between fading rules
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Rule {
                anchors.verticalCenter: parent.verticalCenter
                width: 54
                fadeLeft: true
            }

            Text {
                text: calendar.monthNames[calendar.today.getMonth()].toUpperCase()
                font.family: Theme.fontUi
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                font.letterSpacing: 3
                color: Theme.hudText
            }

            Rule {
                anchors.verticalCenter: parent.verticalCenter
                width: 54
            }
        }

        Grid {
            columns: 7
            columnSpacing: 2
            rowSpacing: 1

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                Text {
                    width: 38
                    height: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: Theme.fontUi
                    font.pixelSize: 10
                    font.bold: true
                    color: index >= 5 ? Theme.textMuted : Theme.hudTextDim
                }
            }

            Repeater {
                model: calendar.cells

                Item {
                    width: 38
                    height: 30
                    readonly property bool isToday: modelData === calendar.today.getDate()

                    // Today is the selected slot
                    ItemSlot {
                        anchors.centerIn: parent
                        width: 30
                        height: 25
                        active: true
                        visible: parent.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: modelData === null ? "" : modelData
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: parent.isToday
                        color: parent.isToday ? "#ffffff" : Theme.hudText
                        opacity: modelData !== null && modelData < calendar.today.getDate() ? 0.4 : 1.0
                    }

                    // Marker for days with events
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        width: 4
                        height: 4
                        rotation: 45
                        color: Theme.amber
                        visible: modelData !== null && !parent.isToday && calendar.busyDays[modelData] === true
                    }
                }
            }
        }
    }

    // Open Google Calendar on click
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: openCalendar.running = true
    }

    Process {
        id: openCalendar
        command: ["xdg-open", "https://calendar.google.com/calendar/r"]
    }
}
