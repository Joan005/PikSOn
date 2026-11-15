import Quickshell.Services.Mpris
import QtQuick

Rectangle {
    id: chip

    property bool opened: false

    function pickPlayer() {
        var list = Mpris.players.values
        var pick = null
        for (var i = 0; i < list.length; i++) {
            var p = list[i]
            if (p.identity === "Spotify")
                return p
            if (pick === null || (p.isPlaying && !pick.isPlaying))
                pick = p
        }
        return pick
    }

    function shortText() {
        if (!chip.player)
            return "Nada suena"
        var t = chip.player.trackTitle || ""
        var a = chip.player.trackArtist || ""
        var i1 = t.indexOf("(")
        if (i1 > 0)
            t = t.substring(0, i1).trim()
        if (t === "")
            return "Sin tÃtulo"
        if (a !== "" && t.indexOf(" - ") < 0)
            return t + " - " + a
        return t
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    function timeText() {
        if (!chip.player)
            return "--:-- / --:--"
        var pos = fmt(chip.player.position)
        if (chip.player.lengthSupported && chip.player.length > 0)
            return pos + " / " + fmt(chip.player.length)
        return pos
    }

    readonly property var player: pickPlayer()
    onPlayerChanged: if (!player) opened = false

    height: 32
    width: 258
    color: "transparent"

    Timer {
        interval: 1000
        repeat: true
        running: chip.player !== null && chip.player.isPlaying
        onTriggered: if (chip.player) chip.player.positionChanged()
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 8

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            opacity: chip.player ? 1.0 : 0.35

            Item {
                width: 22
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: "\uf048"
                    color: Theme.fg
                    font.family: Theme.fontIcons
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: if (chip.player) chip.player.previous()
                }
            }

            Item {
                width: 22
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: chip.player && chip.player.isPlaying ? "\uf04c" : "\uf04b"
                    color: Theme.fg
                    font.family: Theme.fontIcons
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: if (chip.player) chip.player.togglePlaying()
                }
            }

            Item {
                width: 22
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: "\uf051"
                    color: Theme.fg
                    font.family: Theme.fontIcons
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: if (chip.player) chip.player.next()
                }
            }
        }

        Rectangle {
            id: thumb
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: 4
            color: "transparent"
            border.color: Theme.accent
            border.width: 1
            clip: true
            opacity: chip.player ? 1.0 : 0.45

            Image {
                id: art
                anchors.fill: parent
                anchors.margins: 1
                source: chip.player && chip.player.trackArtUrl ? chip.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            Rectangle {
                anchors.centerIn: parent
                width: 16
                height: 16
                radius: 8
                color: Theme.accent
                visible: art.status !== Image.Ready

                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.fgOnAccent
                }
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 150
            height: 30

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 1

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: chip.shortText()
                    color: !chip.player ? Theme.fgMuted : (hover.containsMouse ? Theme.accent : Theme.fg)
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: chip.timeText()
                    color: Theme.fgMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 10
                    opacity: chip.player ? 1.0 : 0.5
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: if (chip.player) chip.opened = !chip.opened
            }
        }
    }
}
