import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win

    property var lyr: null
    property string title: ""

    signal dock()

    anchors {
        top: true
        right: true
        bottom: true
    }
    implicitWidth: 328
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 316
    color: "transparent"
    mask: Region { item: card }
    WlrLayershell.namespace: "lyrics-side"

    Rectangle {
        id: card
        x: 0
        y: 20
        width: 320
        height: win.height - 40
        radius: Theme.radius
        color: Theme.bgPopup
        border.color: Theme.line
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: dockBtn.left
            anchors.rightMargin: 8
            y: 8
            text: win.title !== "" ? win.title : "Letra"
            elide: Text.ElideRight
            color: Theme.fgMuted
            font.family: Theme.fontUi
            font.pixelSize: 10
            font.bold: true
        }

        Text {
            id: dockBtn
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 7
            text: "\uf066"
            color: dockArea.containsMouse ? Theme.accent : Theme.fgMuted
            font.family: Theme.fontIcons
            font.pixelSize: 13

            MouseArea {
                id: dockArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                onClicked: win.dock()
            }
        }

        Rectangle {
            x: 14
            y: 30
            width: parent.width - 28
            height: 1
            color: Theme.line
            opacity: 0.4
        }

        Item {
            x: 14
            y: 38
            width: parent.width - 28
            height: parent.height - 46

            Text {
                anchors.centerIn: parent
                width: parent.width - 16
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: !win.lyr || win.lyr.status !== "ok"
                text: win.lyr && win.lyr.status === "loading" ? "Buscando la letra…" : "Sin letra para esta canción."
                color: Theme.fgMuted
                font.family: Theme.fontUi
                font.pixelSize: 11
            }

            ListView {
                id: lv
                anchors.fill: parent
                clip: true
                interactive: false
                visible: win.lyr !== null && win.lyr.status === "ok"
                model: win.lyr ? win.lyr.lines : []
                currentIndex: win.lyr ? win.lyr.curLine : 0
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
                        color: win.lyr && parent.index === win.lyr.curLine ? Theme.accent : Theme.fgMuted
                        opacity: win.lyr && parent.index === win.lyr.curLine ? 1 : 0.65
                        font.family: Theme.fontUi
                        font.pixelSize: win.lyr && parent.index === win.lyr.curLine ? 12 : 11
                        font.bold: win.lyr && parent.index === win.lyr.curLine
                    }
                }
            }
        }
    }
}
