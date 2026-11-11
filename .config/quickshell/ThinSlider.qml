import QtQuick

Item {
    id: s

    property real value: 0
    property bool enabled2: true

    signal moved(real v)

    height: 16
    opacity: enabled2 ? 1 : 0.4

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 2
        radius: 1
        color: Theme.line
        opacity: 0.6
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: track.width * s.value
        height: 2
        radius: 1
        color: Theme.accent
    }

    Rectangle {
        x: track.width * s.value - 5.5
        y: (parent.height - 11) / 2
        width: 11
        height: 11
        radius: 5.5
        color: Theme.accent
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: s.enabled2

        function setFrom(mx) {
            s.moved(Math.max(0, Math.min(1, mx / width)))
        }

        onPressed: (mouse) => setFrom(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed)
                setFrom(mouse.x)
        }
    }
}
