import QtQuick

// Glowing motes drifting up through the forest light
Item {
    id: field
    property int count: 32

    Repeater {
        model: field.count

        delegate: Item {
            id: mote
            width: 1
            height: 1
            opacity: 0

            property real size: 2 + Math.random() * 3
            property real peak: 0.45 + Math.random() * 0.5
            property int lifetime: 10000

            Rectangle {
                anchors.centerIn: parent
                width: mote.size * 6
                height: width
                radius: width / 2
                color: Theme.sunlit
                opacity: 0.12
            }

            Rectangle {
                anchors.centerIn: parent
                width: mote.size * 2.5
                height: width
                radius: width / 2
                color: Theme.sunlit
                opacity: 0.3
            }

            Rectangle {
                anchors.centerIn: parent
                width: mote.size
                height: width
                radius: width / 2
                color: Theme.sunbeam
            }

            function respawn() {
                lifetime = 7000 + Math.random() * 9000;
                x = Math.random() * field.width;
                y = field.height * (0.25 + Math.random() * 0.8);
                rise.to = y - (120 + Math.random() * 260);
                sway.to = x + (Math.random() - 0.5) * 160;
                anim.restart();
            }

            ParallelAnimation {
                id: anim
                NumberAnimation { id: rise; target: mote; property: "y"; duration: mote.lifetime }
                NumberAnimation { id: sway; target: mote; property: "x"; duration: mote.lifetime; easing.type: Easing.InOutSine }
                SequentialAnimation {
                    NumberAnimation { target: mote; property: "opacity"; to: mote.peak; duration: mote.lifetime * 0.3; easing.type: Easing.InOutSine }
                    PauseAnimation { duration: mote.lifetime * 0.4 }
                    NumberAnimation { target: mote; property: "opacity"; to: 0; duration: mote.lifetime * 0.3; easing.type: Easing.InOutSine }
                }
                onFinished: mote.respawn()
            }

            // Stagger the first appearance so they don't all bloom at once
            Timer {
                interval: Math.random() * 6000
                running: true
                onTriggered: mote.respawn()
            }
        }
    }
}
