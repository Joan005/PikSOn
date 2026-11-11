import Quickshell
import Quickshell.Services.Mpris
import QtQuick

PopupWindow {
    id: panel

    property var player: null
    property var lyr: null
    property bool floating: false
    property real dragFrac: -1

    signal floatToggled()

    readonly property bool hasLength: player !== null && player.lengthSupported && player.length > 0
    readonly property real frac: dragFrac >= 0 ? dragFrac : (hasLength ? Math.min(1, Math.max(0, player.position / player.length)) : 0)
    readonly property bool loopOn: player !== null && player.loopSupported && player.loopState !== MprisLoopState.None
    readonly property bool hasArt: art.status === Image.Ready

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
        id: hold
        interval: 800
        onTriggered: panel.dragFrac = -1
    }

    Timer {
        id: applySeek
        interval: 120
        onTriggered: {
            if (panel.player && panel.player.canSeek && panel.hasLength)
                panel.player.position = panel.dragFrac * panel.player.length
        }
    }

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 32
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgPopup
        border.color: Theme.line
        border.width: 1

        Column {
            id: content
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Row {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 68
                    height: 68
                    radius: 4
                    color: "#241811"
                    border.color: Theme.accent
                    border.width: 1
                    clip: true

                    Image {
                        id: art
                        anchors.fill: parent
                        anchors.margins: 1
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
                            width: 48
                            height: 48
                            radius: 24
                            color: Theme.accent
                            border.color: "#a9803a"
                            border.width: 2

                            Rectangle {
                                anchors.centerIn: parent
                                width: 30
                                height: 30
                                radius: 15
                                color: "transparent"
                                border.color: "#a9803a"
                                border.width: 1
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 10
                                radius: 5
                                color: Theme.fgOnAccent
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - 68 - 12
                    spacing: 3

                    Text {
                        width: parent.width
                        text: panel.player ? (panel.player.trackTitle || "") : ""
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Theme.fg
                        font.family: Theme.fontUi
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: panel.player ? (panel.player.trackArtist || "") : ""
                        elide: Text.ElideRight
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                    }

                    Text {
                        width: parent.width
                        text: panel.player ? (panel.player.identity || "") : ""
                        elide: Text.ElideRight
                        color: Theme.fgMuted
                        opacity: 0.7
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                visible: panel.hasLength

                ThinSlider {
                    width: parent.width
                    value: panel.frac
                    onMoved: (v) => {
                        panel.dragFrac = v
                        hold.restart()
                        applySeek.restart()
                    }
                }

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: panel.fmt(panel.hasLength ? panel.frac * panel.player.length : 0)
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                    }

                    Text {
                        anchors.right: parent.right
                        text: panel.fmt(panel.hasLength ? panel.player.length : 0)
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                    }
                }
            }

            Item {
                width: parent.width
                height: 44

                Row {
                    anchors.centerIn: parent
                    spacing: 14

                    Item {
                        width: 34
                        height: 44

                        Text {
                            anchors.centerIn: parent
                            text: "\uf048"
                            color: prevArea.containsMouse ? Theme.accent : Theme.fg
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (panel.player) panel.player.previous()
                        }
                    }

                    Item {
                        width: 44
                        height: 44

                        Rectangle {
                            anchors.centerIn: parent
                            width: 38
                            height: 38
                            radius: 19
                            color: playArea.containsMouse ? "#22e2b564" : "transparent"
                            border.color: Theme.accent
                            border.width: 1
                        }

                        Text {
                            anchors.centerIn: parent
                            text: panel.player && panel.player.isPlaying ? "\uf04c" : "\uf04b"
                            color: Theme.accent
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (panel.player) panel.player.togglePlaying()
                        }
                    }

                    Item {
                        width: 34
                        height: 44

                        Text {
                            anchors.centerIn: parent
                            text: "\uf051"
                            color: nextArea.containsMouse ? Theme.accent : Theme.fg
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (panel.player) panel.player.next()
                        }
                    }

                    Item {
                        width: 34
                        height: 44

                        Text {
                            anchors.centerIn: parent
                            text: "\uf01e"
                            color: panel.loopOn || loopArea.containsMouse ? Theme.accent : Theme.fg
                            opacity: panel.player && panel.player.loopSupported ? 1 : 0.35
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 3
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            text: "1"
                            color: Theme.accent
                            font.family: Theme.fontUi
                            font.pixelSize: 9
                            font.bold: true
                            visible: panel.player !== null && panel.player.loopSupported && panel.player.loopState === MprisLoopState.Track
                        }

                        MouseArea {
                            id: loopArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: panel.nextLoop()
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.line
                opacity: 0.45
            }

            Item {
                width: parent.width
                height: 18

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Letra"
                    color: Theme.accent
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: panel.floating ? "\uf066" : "\uf08e"
                    color: floatArea.containsMouse ? Theme.accent : Theme.fgMuted
                    font.family: Theme.fontIcons
                    font.pixelSize: 13

                    MouseArea {
                        id: floatArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        onClicked: panel.floatToggled()
                    }
                }
            }

            Item {
                width: parent.width
                height: panel.floating ? 44 : 120

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 16
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: panel.floating || !panel.lyr || panel.lyr.status !== "ok"
                    text: panel.floating ? "La letra está en la ventana flotante." : (panel.lyr && panel.lyr.status === "loading" ? "Buscando la letra…" : "Sin letra para esta canción.")
                    color: Theme.fgMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                }

                ListView {
                    id: lv
                    anchors.fill: parent
                    clip: true
                    interactive: false
                    visible: !panel.floating && panel.lyr !== null && panel.lyr.status === "ok"
                    model: panel.lyr ? panel.lyr.lines : []
                    currentIndex: panel.lyr ? panel.lyr.curLine : 0
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: height / 2 - 12
                    preferredHighlightEnd: height / 2 + 12
                    highlightMoveDuration: 250

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: lv.width
                        height: 24

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: parent.modelData.text
                            color: panel.lyr && parent.index === panel.lyr.curLine ? Theme.accent : Theme.fgMuted
                            opacity: panel.lyr && parent.index === panel.lyr.curLine ? 1 : 0.65
                            font.family: Theme.fontUi
                            font.pixelSize: panel.lyr && parent.index === panel.lyr.curLine ? 12 : 11
                            font.bold: panel.lyr && parent.index === panel.lyr.curLine
                        }
                    }
                }
            }
        }
    }
}
