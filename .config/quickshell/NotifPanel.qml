import Quickshell
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: panel

    property var items: []
    property bool dnd: false
    property int tick: 0

    signal closeRequested()
    signal dismissRequested(int id)
    signal clearRequested()
    signal dndToggled()

    function ago(t, tk) {
        var s = Math.floor((Date.now() - t.getTime()) / 1000)
        if (s < 60)
            return "ahora"
        var m = Math.floor(s / 60)
        if (m < 60)
            return "hace " + m + " min"
        var h = Math.floor(m / 60)
        if (h < 24)
            return "hace " + h + " h"
        return "hace " + Math.floor(h / 24) + " d"
    }

    Timer {
        interval: 30000
        running: panel.visible
        repeat: true
        onTriggered: panel.tick = panel.tick + 1
    }

    implicitWidth: 400
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
            spacing: 10

            Item {
                width: parent.width
                height: 24

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: "Avisos"
                        color: Theme.accent
                        font.family: Theme.fontUi
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: panel.items.length
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "No molestar"
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 16
                        radius: 8
                        color: panel.dnd ? "#33e2b564" : "transparent"
                        border.color: panel.dnd ? Theme.accent : Theme.line
                        border.width: 1

                        Rectangle {
                            x: panel.dnd ? 16 : 2
                            y: 2
                            width: 10
                            height: 10
                            radius: 5
                            color: panel.dnd ? Theme.accent : Theme.fgMuted

                            Behavior on x {
                                NumberAnimation { duration: 120 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: panel.dndToggled()
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: clearText.implicitWidth + 24
                        height: 24
                        radius: 12
                        color: "transparent"
                        border.color: clearArea.containsMouse ? Theme.accent : Theme.line
                        border.width: 1

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "Limpiar"
                            color: clearArea.containsMouse ? Theme.accent : Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: panel.clearRequested()
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
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: panel.items.length === 0
                text: "Todo al dÃa."
                color: Theme.fgMuted
                font.family: Theme.fontUi
                font.pixelSize: 12
                topPadding: 10
                bottomPadding: 10
            }

            Flickable {
                width: parent.width
                height: Math.min(list.implicitHeight, 380)
                contentHeight: list.implicitHeight
                clip: true
                visible: panel.items.length > 0

                Column {
                    id: list
                    width: parent.width

                    Repeater {
                        model: panel.items

                        delegate: Item {
                            id: row
                            required property var modelData

                            width: list.width
                            height: texts.implicitHeight + 16

                            Rectangle {
                                id: badge
                                x: 0
                                y: 8
                                width: 26
                                height: 26
                                radius: 6
                                color: "transparent"
                                border.color: row.modelData.crit ? "#cf5b4a" : Theme.line
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: row.modelData.app.charAt(0).toUpperCase()
                                    color: row.modelData.crit ? "#cf5b4a" : Theme.accent
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Column {
                                id: texts
                                x: 36
                                y: 8
                                width: row.width - 36 - 26
                                spacing: 2

                                Item {
                                    width: parent.width
                                    height: 14

                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: when.left
                                        anchors.rightMargin: 8
                                        text: row.modelData.app
                                        elide: Text.ElideRight
                                        color: Theme.fgMuted
                                        font.family: Theme.fontUi
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Text {
                                        id: when
                                        anchors.right: parent.right
                                        text: panel.ago(row.modelData.time, panel.tick)
                                        color: Theme.fgMuted
                                        font.family: Theme.fontUi
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: row.modelData.summary
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: Theme.fg
                                    font.family: Theme.fontUi
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width
                                    visible: row.modelData.body !== ""
                                    text: row.modelData.body
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    color: Theme.fgMuted
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                y: 8
                                width: 22
                                horizontalAlignment: Text.AlignHCenter
                                text: "\uf00d"
                                color: xArea.containsMouse ? Theme.accent : Theme.fgMuted
                                font.family: Theme.fontIcons
                                font.pixelSize: 12

                                MouseArea {
                                    id: xArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: panel.dismissRequested(row.modelData.id)
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Theme.line
                                opacity: 0.3
                            }
                        }
                    }
                }
            }
        }
    }
}
