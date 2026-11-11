import Quickshell
import QtQuick

PopupWindow {
    id: panel

    property var info: ({})
    property int tab: 0
    property bool on: true

    readonly property real cx: 260
    readonly property real cy: 205
    readonly property var slots: [[260, 54], [89, 130], [431, 130], [104, 292], [416, 301]]
    readonly property bool ok: panel.info !== undefined && panel.info !== null && panel.info.estado === "ok"

    readonly property int strength: !on ? 0 : (tab === 0 ? (ok ? 100 : 0) : (tab === 1 ? 87 : 81))
    readonly property string medIcon: tab === 0 ? "\uf0e8" : (tab === 1 ? "\uf1eb" : "\uf293")
    readonly property string medName: !on ? "Apagado" : (tab === 0 ? (ok ? panel.info.conexion : "Sin conexión") : (tab === 1 ? "Casa_5G" : "JBL Tune 720BT"))
    readonly property string medStatus: !on ? "Pulse el botón" : (tab === 0 ? (ok ? "Conectada" : "Sin cable") : (tab === 1 ? "Conectada · ejemplo" : "Emparejado · ejemplo"))
    readonly property var cards: cardsFor()

    function cardsFor() {
        var d = "—"
        if (tab === 0) {
            var k = panel.on && panel.ok
            return [
                { b: "ETH", v: k ? panel.info.dispositivo : d, l: "Dispositivo" },
                { b: "IP", v: k ? panel.info.ip.split("/")[0] : d, l: "Dirección IP" },
                { b: "Mb/s", v: k ? panel.info.velocidad : d, l: "Velocidad" },
                { b: "GW", v: k ? panel.info.puerta : d, l: "Puerta de enlace" },
                { b: "DNS", v: k ? panel.info.dns : d, l: "Servidores DNS" }
            ]
        }
        if (tab === 1) {
            var w = panel.on
            return [
                { b: "GHz", v: w ? "5180 MHz" : d, l: "Banda" },
                { b: "IP", v: w ? "192.168.1.238" : d, l: "Dirección IP" },
                { b: "...", v: "Escanear redes", l: "Próximamente" },
                { b: "SEC", v: w ? "WPA3" : d, l: "Seguridad" },
                { b: "%", v: w ? "87 %" : d, l: "Intensidad de señal" }
            ]
        }
        var b = panel.on
        return [
            { b: "COD", v: b ? "AAC" : d, l: "Códec" },
            { b: "TIP", v: b ? "Auriculares" : d, l: "Tipo de dispositivo" },
            { b: "...", v: "Escanear dispositivos", l: "Próximamente" },
            { b: "BAT", v: b ? "80 %" : d, l: "Batería" },
            { b: "%", v: b ? "81 %" : d, l: "Intensidad de señal" }
        ]
    }

    implicitWidth: 520
    implicitHeight: 450
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgPopup
        border.color: Theme.line
        border.width: 1
        clip: true

        Repeater {
            model: [150, 200, 250]

            delegate: Rectangle {
                required property var modelData

                x: panel.cx - modelData
                y: panel.cy - modelData
                width: modelData * 2
                height: modelData * 2
                radius: modelData
                color: "transparent"
                border.color: Theme.line
                border.width: 1
                opacity: 0.35
            }
        }

        Repeater {
            model: panel.slots

            delegate: Item {
                required property var modelData

                readonly property real dx: modelData[0] - panel.cx
                readonly property real dy: modelData[1] - panel.cy

                Rectangle {
                    x: panel.cx
                    y: panel.cy - 0.75
                    width: Math.sqrt(parent.dx * parent.dx + parent.dy * parent.dy)
                    height: 1.5
                    rotation: Math.atan2(parent.dy, parent.dx) * 180 / Math.PI
                    transformOrigin: Item.Left
                    color: Theme.line
                }

                Rectangle {
                    x: modelData[0] - 3.5
                    y: modelData[1] - 3.5
                    width: 7
                    height: 7
                    radius: 3.5
                    color: Theme.accent
                }
            }
        }

        Rectangle {
            x: panel.cx - 100
            y: panel.cy - 100
            width: 200
            height: 200
            radius: 100
            color: "#2d1e12"
            border.color: Theme.line
            border.width: 1
        }

        Repeater {
            model: 24

            delegate: Item {
                required property int index

                x: panel.cx
                y: panel.cy
                rotation: index * 15

                Rectangle {
                    x: -1.5
                    y: -94
                    width: 3
                    height: 9
                    radius: 1.5
                    color: index < Math.round(panel.strength / 100 * 24) ? Theme.accent : Theme.bgCell
                }
            }
        }

        Rectangle {
            x: panel.cx - 78
            y: panel.cy - 78
            width: 156
            height: 156
            radius: 78
            border.color: "#7a5a1f"
            border.width: 2

            gradient: Gradient {
                GradientStop { position: 0.0; color: panel.on ? "#f0d08a" : "#6b4f39" }
                GradientStop { position: 1.0; color: panel.on ? "#b98d3f" : "#3a2a1c" }
            }

            Column {
                anchors.centerIn: parent
                width: 130
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: panel.medIcon
                    color: panel.on ? Theme.fgOnAccent : Theme.fgMuted
                    font.family: Theme.fontIcons
                    font.pixelSize: 30
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: panel.medName
                    elide: Text.ElideRight
                    color: panel.on ? Theme.fgOnAccent : Theme.fgMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: panel.medStatus
                    elide: Text.ElideRight
                    color: panel.on ? "#5a3d1c" : Theme.fgMuted
                    font.family: Theme.fontSerif
                    font.pixelSize: 14
                    font.italic: true
                }
            }
        }

        Repeater {
            model: panel.cards

            delegate: Rectangle {
                required property var modelData
                required property int index

                x: panel.slots[index][0] - width / 2
                y: panel.slots[index][1] - height / 2
                width: 142
                height: Math.max(46, cardCol.implicitHeight + 14)
                radius: 12
                color: Theme.bgChip
                border.color: Theme.line
                border.width: 1
                opacity: panel.on ? 1 : 0.55

                Rectangle {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    radius: 8
                    color: Theme.bgCell
                    border.color: Theme.line
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.b
                        color: Theme.accent
                        font.family: Theme.fontUi
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                Column {
                    id: cardCol; x: 46
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 52

                    Text {
                        width: parent.width
                        text: modelData.v
                        elide: Text.ElideRight
                        color: Theme.fg
                        font.family: Theme.fontUi
                        wrapMode: Text.WordWrap; font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: modelData.l
                        elide: Text.ElideRight
                        color: Theme.fgMuted
                        font.family: Theme.fontSerif
                        font.pixelSize: 12
                        font.italic: true
                    }
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 62
            width: tabs.implicitWidth + 12
            height: 38
            radius: 19
            color: "#241811"
            border.color: Theme.line
            border.width: 1

            Row {
                id: tabs
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: ["Cable", "Wi-Fi", "Bluetooth"]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: tabLabel.implicitWidth + 28
                        height: 30
                        radius: 15
                        color: panel.tab === index ? Theme.accent : "transparent"

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: panel.tab === index ? Theme.fgOnAccent : Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: panel.tab = index
                        }
                    }
                }
            }
        }

        Rectangle {
            x: parent.width - 58
            y: parent.height - 62
            width: 40
            height: 40
            radius: 20
            border.color: panel.on ? Theme.accent : Theme.line
            border.width: 2

            gradient: Gradient {
                GradientStop { position: 0.0; color: panel.on ? "#f0d08a" : "#4a382a" }
                GradientStop { position: 1.0; color: panel.on ? "#a9803a" : "#2d1e12" }
            }

            Text {
                anchors.centerIn: parent
                text: "\uf011"
                color: panel.on ? Theme.fgOnAccent : Theme.fgMuted
                font.family: Theme.fontIcons
                font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent
                onClicked: panel.on = !panel.on
            }
        }
    }
}
