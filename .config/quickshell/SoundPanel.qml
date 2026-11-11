import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: panel

    signal closeRequested()
    signal changed()

    property real outVol: 0
    property bool outMuted: false
    property real inVol: 0
    property bool inMuted: false
    property bool hasIn: false
    property var sinks: []
    property string defSink: ""

    readonly property string outName: nameOf(sinks, defSink)

    function nameOf(list, def) {
        for (var i = 0; i < list.length; i++) {
            if (list[i].name === def)
                return list[i].description
        }
        return list.length > 0 ? list[0].description : "Sin dispositivo"
    }

    function parseVol(text) {
        var t = text.trim()
        if (t.indexOf("Volume:") !== 0)
            return null
        return { v: parseFloat(t.split(" ")[1]), m: t.indexOf("MUTED") >= 0 }
    }

    function refresh() {
        outProc.running = true
        inProc.running = true
        sinksProc.running = true
        defProc.running = true
    }

    function send(target, v) {
        Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", target, Math.round(v * 100) + "%"])
    }

    onVisibleChanged: {
        if (visible)
            refresh()
    }

    Timer {
        interval: 1000
        running: panel.visible
        repeat: true
        onTriggered: panel.refresh()
    }

    Timer {
        id: holdOut
        interval: 800
    }

    Timer {
        id: holdIn
        interval: 800
    }

    Timer {
        id: applyOut
        interval: 60
        onTriggered: {
            panel.send("@DEFAULT_AUDIO_SINK@", panel.outVol)
            panel.changed()
        }
    }

    Timer {
        id: applyIn
        interval: 60
        onTriggered: panel.send("@DEFAULT_AUDIO_SOURCE@", panel.inVol)
    }

    Timer {
        id: later
        interval: 400
        onTriggered: panel.refresh()
    }

    Process {
        id: outProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var r = panel.parseVol(this.text)
                if (r === null)
                    return
                if (!holdOut.running)
                    panel.outVol = Math.min(1, r.v)
                panel.outMuted = r.m
            }
        }
    }

    Process {
        id: inProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var r = panel.parseVol(this.text)
                if (r === null) {
                    panel.hasIn = false
                    return
                }
                panel.hasIn = true
                if (!holdIn.running)
                    panel.inVol = Math.min(1, r.v)
                panel.inMuted = r.m
            }
        }
    }

    Process {
        id: sinksProc
        command: ["pactl", "--format=json", "list", "sinks"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var a = JSON.parse(this.text)
                    var out = []
                    for (var i = 0; i < a.length; i++)
                        out.push({ name: a[i].name, description: a[i].description })
                    panel.sinks = out
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: defProc
        command: ["pactl", "get-default-sink"]
        stdout: StdioCollector {
            onStreamFinished: panel.defSink = this.text.trim()
        }
    }

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 32
    color: "transparent"

    HyprlandFocusGrab {
        windows: [panel]
        active: panel.visible
        onCleared: panel.closeRequested()
    }

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
            spacing: 12

            Row {
                width: parent.width
                spacing: 18

                Column {
                    width: (parent.width - 18) / 2
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 18

                        Row {
                            spacing: 6

                            Text {
                                text: panel.outMuted ? "\uf026" : "\uf028"
                                color: Theme.fg
                                font.family: Theme.fontIcons
                                font.pixelSize: 13
                            }

                            Text {
                                text: "Salida"
                                color: Theme.fg
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            text: panel.outMuted ? "mute" : Math.round(panel.outVol * 100) + "%"
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Text {
                        width: parent.width
                        text: panel.outName
                        elide: Text.ElideRight
                        color: Theme.fgMuted
                        font.family: Theme.fontSerif
                        font.pixelSize: 14
                        font.italic: true
                    }

                    ThinSlider {
                        width: parent.width
                        value: panel.outVol
                        onMoved: (v) => {
                            panel.outVol = v
                            holdOut.restart()
                            applyOut.restart()
                        }
                    }

                    Rectangle {
                        width: outBtn.implicitWidth + 24
                        height: 26
                        radius: 13
                        color: "transparent"
                        border.color: outArea.containsMouse ? Theme.accent : Theme.line
                        border.width: 1

                        Text {
                            id: outBtn
                            anchors.centerIn: parent
                            text: panel.outMuted ? "Activar sonido" : "Silenciar"
                            color: outArea.containsMouse ? Theme.accent : Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: outArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                                panel.outMuted = !panel.outMuted
                                panel.changed()
                                later.restart()
                            }
                        }
                    }
                }

                Column {
                    width: (parent.width - 18) / 2
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 18

                        Row {
                            spacing: 6

                            Text {
                                text: panel.inMuted ? "\uf131" : "\uf130"
                                color: Theme.fg
                                font.family: Theme.fontIcons
                                font.pixelSize: 13
                            }

                            Text {
                                text: "Entrada"
                                color: Theme.fg
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            text: !panel.hasIn ? "--" : (panel.inMuted ? "mute" : Math.round(panel.inVol * 100) + "%")
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Text {
                        width: parent.width
                        text: panel.hasIn ? "Micrófono" : "Sin micrófono"
                        elide: Text.ElideRight
                        color: Theme.fgMuted
                        font.family: Theme.fontSerif
                        font.pixelSize: 14
                        font.italic: true
                    }

                    ThinSlider {
                        width: parent.width
                        value: panel.inVol
                        enabled2: panel.hasIn
                        onMoved: (v) => {
                            panel.inVol = v
                            holdIn.restart()
                            applyIn.restart()
                        }
                    }

                    Rectangle {
                        width: inBtn.implicitWidth + 24
                        height: 26
                        radius: 13
                        color: "transparent"
                        border.color: inArea.containsMouse ? Theme.accent : Theme.line
                        border.width: 1
                        opacity: panel.hasIn ? 1 : 0.4

                        Text {
                            id: inBtn
                            anchors.centerIn: parent
                            text: panel.inMuted ? "Activar" : "Silenciar"
                            color: inArea.containsMouse ? Theme.accent : Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: inArea
                            anchors.fill: parent
                            enabled: panel.hasIn
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
                                panel.inMuted = !panel.inMuted
                                later.restart()
                            }
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

            Text {
                text: "Dispositivos de salida"
                color: Theme.fgMuted
                font.family: Theme.fontSerif
                font.pixelSize: 15
                font.italic: true
            }

            Column {
                width: parent.width

                Repeater {
                    model: panel.sinks

                    delegate: Item {
                        id: dev
                        required property var modelData

                        readonly property bool isDef: modelData.name === panel.defSink

                        width: parent.width
                        height: 30

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: tick.left
                            anchors.rightMargin: 8
                            text: dev.modelData.description
                            elide: Text.ElideRight
                            color: dev.isDef || devArea.containsMouse ? Theme.accent : Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }

                        Text {
                            id: tick
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            text: "\uf00c"
                            visible: dev.isDef
                            color: Theme.accent
                            font.family: Theme.fontIcons
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: devArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["pactl", "set-default-sink", dev.modelData.name])
                                panel.defSink = dev.modelData.name
                                panel.changed()
                                later.restart()
                            }
                        }
                    }
                }
            }
        }
    }
}
