import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win

    property var items: []

    signal expired(int id)

    anchors {
        top: true
        right: true
    }
    margins {
        top: 44
        right: 12
    }
    implicitWidth: 340
    implicitHeight: Math.max(1, col.implicitHeight)
    visible: items.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: col }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "toasts"

    Column {
        id: col
        width: win.width
        spacing: 8

        Repeater {
            model: win.items

            delegate: Rectangle {
                id: toast
                required property var modelData

                width: col.width
                height: tcol.implicitHeight + 20
                radius: 12
                color: Theme.bgPopup
                border.color: Theme.line
                border.width: 1

                Rectangle {
                    x: 0
                    y: 10
                    width: 2
                    height: parent.height - 20
                    color: toast.modelData.crit ? "#cf5b4a" : Theme.accent
                }

                Column {
                    id: tcol
                    x: 14
                    y: 10
                    width: parent.width - 28
                    spacing: 3

                    Text {
                        width: parent.width
                        text: toast.modelData.app
                        elide: Text.ElideRight
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: toast.modelData.summary
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
                        visible: toast.modelData.body !== ""
                        text: toast.modelData.body
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }
                }

                Timer {
                    running: true
                    interval: toast.modelData.crit ? 12000 : 6000
                    onTriggered: win.expired(toast.modelData.id)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: win.expired(toast.modelData.id)
                }
            }
        }
    }
}
