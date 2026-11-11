import Quickshell
import Quickshell.Services.Mpris
import QtQuick

PopupWindow {
    id: panel

    property var player: null
    property real dragFrac: -1

    readonly property bool hasArt: art.status === Image.Ready
    readonly property bool wide: hasArt && art.implicitWidth / Math.max(1, art.implicitHeight) > 1.3
    readonly property bool hasLength: player !== null && player.lengthSupported && player.length > 0
    readonly property real frac: dragFrac >= 0 ? dragFrac : (hasLength ? Math.min(1, Math.max(0, player.position / player.length)) : 0)
    readonly property bool loopOn: player !== null && player.loopSupported && player.loopState !== MprisLoopState.None

    function sourceIcon() {
        if (!panel.player)
            return "\uf001"
        var n = panel.player.identity || ""
        if (n === "Spotify")
            return "\uf1bc"
        if (n.indexOf("Brave") >= 0 || n.indexOf("Chrom") >= 0 || n.indexOf("Firefox") >= 0)
            return "\uf16a"
        return "\uf001"
    }

    function fmt(s) {
        var t = Math.max(0, Math.floor(s))
        var r = t % 60
        return Math.floor(t / 60) + ":" + (r < 10 ? "0" : "") + r
    }

    function nextLoop() {
        if (!panel.player || !panel.player.loopSupported)
            return
        var s = panel.player.loopState
        if (s === MprisLoopState.None)
            panel.player.loopState = MprisLoopState.Track
        else if (s === MprisLoopState.Track)
            panel.player.loopState = MprisLoopState.Playlist
        else
            panel.player.loopState = MprisLoopState.None
    }

    Timer {
        interval: 500
        repeat: true
        running: panel.visible && panel.player !== null && panel.player.isPlaying
        onTriggered: panel.player.positionChanged()
    }

    implicitWidth: 300
    implicitHeight: col.implicitHeight + 28
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgPopup
        border.color: Theme.line
        border.width: 1

        Column {
            id: col
            anchors.top: parent.top
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Rectangle {
                id: frame
                anchors.horizontalCenter: parent.horizontalCenter
                width: panel.wide ? 272 : 232
                height: panel.wide ? 166 : 232
                radius: 4
                color: panel.wide ? "#b8913f" : Theme.wood
                border.color: panel.wide ? "#e9c978" : "#4a3322"
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: panel.wide ? 8 : 12
                    color: panel.wide ? "#2a1d12" : "#ece0c4"
                    border.color: "#55000000"
                    border.width: 1

                    Item {
                        id: artBox
                        anchors.fill: parent
                        anchors.margins: panel.wide ? 3 : 10
                        clip: true

                        Image {
                            id: art
                            anchors.fill: parent
                            source: panel.player ? panel.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Item {
                            anchors.fill: parent
                            visible: !panel.hasArt

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 16
                                height: width
                                radius: width / 2
                                color: Theme.accent
                                border.color: "#a9803a"
                                border.width: 3

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.62
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: "#a9803a"
                                    border.width: 1
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.2
                                    height: width
                                    radius: width / 2
                                    color: Theme.fgOnAccent
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: panel.wide ? 4 : 0

                    delegate: Rectangle {
                        required property int index

                        x: index % 2 === 1 ? frame.width - 9 : 3
                        y: index > 1 ? frame.height - 9 : 3
                        width: 6
                        height: 6
                        radius: 3
                        color: "#7a5a1f"
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: frame.width
                height: plateCol.implicitHeight + 24
                radius: 4
                border.color: "#7a5a1f"
                border.width: 1

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#f0d08a" }
                    GradientStop { position: 1.0; color: "#b98d3f" }
                }

                Column {
                    id: plateCol
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Item {
                        width: parent.width
                        height: textCol.implicitHeight

                        Column {
                            id: textCol
                            anchors.left: parent.left
                            anchors.right: srcIcon.left
                            anchors.rightMargin: 8
                            spacing: 2

                            Text {
                                width: parent.width
                                text: panel.player ? (panel.player.trackTitle || "") : ""
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                color: Theme.fgOnAccent
                                font.family: Theme.fontSerif
                                font.pixelSize: 17
                                font.bold: true
                                font.capitalization: Font.SmallCaps
                            }

                            Text {
                                width: parent.width
                                text: panel.player ? (panel.player.trackArtist || "") : ""
                                elide: Text.ElideRight
                                color: "#5a3d1c"
                                font.family: Theme.fontSerif
                                font.pixelSize: 14
                                font.italic: true
                            }
                        }

                        Text {
                            id: srcIcon
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: panel.sourceIcon()
                            color: Theme.fgOnAccent
                            font.family: Theme.fontIcons
                            font.pixelSize: 20
                        }
                    }

                    Item {
                        width: parent.width
                        height: 30
                        visible: panel.hasLength

                        Rectangle {
                            id: groove
                            anchors.left: parent.left
                            anchors.right: parent.right
                            y: 6
                            height: 6
                            radius: 3
                            color: "#c99d4a"
                            border.color: "#7a5a1f"
                            border.width: 1

                            Rectangle {
                                width: groove.width * panel.frac
                                height: parent.height
                                radius: 3
                                color: "#5a3d1c"
                            }
                        }

                        Rectangle {
                            x: groove.width * panel.frac - 7
                            y: 2
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.fgOnAccent
                            border.color: "#f0d08a"
                            border.width: 2
                        }

                        Text {
                            anchors.left: parent.left
                            y: 17
                            text: panel.fmt(panel.hasLength ? panel.frac * panel.player.length : 0)
                            color: "#5a3d1c"
                            font.family: Theme.fontUi
                            font.pixelSize: 10
                        }

                        Text {
                            anchors.right: parent.right
                            y: 17
                            text: panel.fmt(panel.hasLength ? panel.player.length : 0)
                            color: "#5a3d1c"
                            font.family: Theme.fontUi
                            font.pixelSize: 10
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: (mouse) => panel.dragFrac = Math.min(1, Math.max(0, mouse.x / width))
                            onPositionChanged: (mouse) => {
                                if (pressed)
                                    panel.dragFrac = Math.min(1, Math.max(0, mouse.x / width))
                            }
                            onReleased: {
                                if (panel.player && panel.player.canSeek && panel.dragFrac >= 0)
                                    panel.player.position = panel.dragFrac * panel.player.length
                                panel.dragFrac = -1
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 40

                        Row {
                            anchors.centerIn: parent
                            spacing: 12

                            Item {
                                width: 32
                                height: 40

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf048"
                                    color: Theme.fgOnAccent
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (panel.player) panel.player.previous()
                                }
                            }

                            Item {
                                width: 40
                                height: 40

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 36
                                    height: 36
                                    radius: 18
                                    color: Theme.fgOnAccent
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: panel.player && panel.player.isPlaying ? "\uf04c" : "\uf04b"
                                    color: "#f0d08a"
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (panel.player) panel.player.togglePlaying()
                                }
                            }

                            Item {
                                width: 32
                                height: 40

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf051"
                                    color: Theme.fgOnAccent
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (panel.player) panel.player.next()
                                }
                            }

                            Item {
                                width: 32
                                height: 40

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: "#5a3d1c"
                                    visible: panel.loopOn
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf01e"
                                    color: panel.loopOn ? "#f0d08a" : Theme.fgOnAccent
                                    opacity: panel.player && panel.player.loopSupported ? 1 : 0.35
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 14
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 6
                                    text: "1"
                                    color: "#f0d08a"
                                    font.pixelSize: 9
                                    font.bold: true
                                    visible: panel.player !== null && panel.player.loopSupported && panel.player.loopState === MprisLoopState.Track
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: panel.nextLoop()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
