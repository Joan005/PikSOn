import Quickshell
import QtQuick

PopupWindow {
    id: panel

    property var wx: null

    readonly property bool ok: wx !== null && wx.ready
    readonly property real gmin: calcMin()
    readonly property real gmax: calcMax()

    function calcMin() {
        if (!wx || wx.days.length === 0)
            return 0
        var m = wx.days[0].min
        for (var i = 1; i < wx.days.length; i++)
            m = Math.min(m, wx.days[i].min)
        return m
    }

    function calcMax() {
        if (!wx || wx.days.length === 0)
            return 1
        var m = wx.days[0].max
        for (var i = 1; i < wx.days.length; i++)
            m = Math.max(m, wx.days[i].max)
        return m
    }

    onVisibleChanged: {
        if (visible && wx)
            wx.refresh()
    }

    implicitWidth: 360
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
            spacing: 12

            Text {
                width: parent.width
                visible: !panel.ok
                horizontalAlignment: Text.AlignHCenter
                text: panel.wx && panel.wx.failed ? "Sin conexión con el servicio del tiempo." : "Cargando el tiempo de Barcelona…"
                color: Theme.fgMuted
                font.family: Theme.fontUi
                font.pixelSize: 12
                topPadding: 20
                bottomPadding: 20
            }

            Item {
                width: parent.width
                height: 62
                visible: panel.ok

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: panel.ok ? panel.wx.glyph(panel.wx.code, panel.wx.isDay) : ""
                        color: Theme.accent
                        font.family: Theme.fontIcons
                        font.pixelSize: 34
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: panel.ok ? panel.wx.temp.toFixed(1) + "°" : ""
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 28
                            font.bold: true
                        }

                        Text {
                            text: panel.ok ? panel.wx.describe(panel.wx.code) + " · sensación " + Math.round(panel.wx.feels) + "°" : ""
                            color: Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                        }
                    }
                }

                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        anchors.right: parent.right
                        text: panel.ok ? "↑ " + panel.wx.sunrise : ""
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }

                    Text {
                        anchors.right: parent.right
                        text: panel.ok ? "↓ " + panel.wx.sunset : ""
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }

                    Text {
                        anchors.right: parent.right
                        text: "Barcelona"
                        color: Theme.fgMuted
                        opacity: 0.7
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.line
                opacity: 0.45
                visible: panel.ok
            }

            Text {
                text: "Próximas horas"
                visible: panel.ok
                color: Theme.fgMuted
                font.family: Theme.fontUi
                font.pixelSize: 10
                font.bold: true
            }

            Row {
                width: parent.width
                visible: panel.ok

                Repeater {
                    model: panel.ok ? panel.wx.hours : []

                    delegate: Column {
                        required property var modelData

                        width: parent.width / 6
                        spacing: 5

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.modelData.h
                            color: Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 10
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: panel.wx.glyph(parent.modelData.code, parent.modelData.day)
                            color: Theme.fg
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(parent.modelData.t) + "°"
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.line
                opacity: 0.45
                visible: panel.ok
            }

            Text {
                text: "Próximos días"
                visible: panel.ok
                color: Theme.fgMuted
                font.family: Theme.fontUi
                font.pixelSize: 10
                font.bold: true
            }

            Column {
                width: parent.width
                spacing: 4
                visible: panel.ok

                Repeater {
                    model: panel.ok ? panel.wx.days : []

                    delegate: Item {
                        id: dayRow
                        required property var modelData

                        width: parent.width
                        height: 26

                        Text {
                            x: 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            text: dayRow.modelData.d
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }

                        Text {
                            x: 40
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            text: panel.wx.glyph(dayRow.modelData.code, true)
                            color: Theme.fg
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                        }

                        Text {
                            x: 72
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(dayRow.modelData.min) + "°"
                            color: Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }

                        Rectangle {
                            id: track
                            x: 112
                            anchors.verticalCenter: parent.verticalCenter
                            width: dayRow.width - 112 - 40
                            height: 4
                            radius: 2
                            color: Theme.line
                            opacity: 0.45
                        }

                        Rectangle {
                            x: track.x + (dayRow.modelData.min - panel.gmin) / Math.max(1, panel.gmax - panel.gmin) * track.width
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(6, (dayRow.modelData.max - dayRow.modelData.min) / Math.max(1, panel.gmax - panel.gmin) * track.width)
                            height: 4
                            radius: 2

                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#7d93ae" }
                                GradientStop { position: 0.5; color: "#e2b564" }
                                GradientStop { position: 1.0; color: "#cf7b55" }
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 30
                            text: Math.round(dayRow.modelData.max) + "°"
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
