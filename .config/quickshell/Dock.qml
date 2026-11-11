import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick

PanelWindow {
    id: win

    readonly property int railClosed: 6
    readonly property int railOpen: 164

    anchors {
        top: true
        right: true
        bottom: true
    }
    implicitWidth: railOpen + 12
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dock"
    visible: ToplevelManager.toplevels.values.length > 0 || SystemTray.items.values.length > 0
    mask: Region { item: rail }

    function iconFor(id) {
        var e = DesktopEntries.heuristicLookup(id)
        var name = (e && e.icon) ? e.icon : id
        return Quickshell.iconPath(name, true)
    }

    Rectangle {
        id: rail
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: hov.hovered ? win.railOpen : win.railClosed
        clip: true
        color: hov.hovered ? "#f52d1e12" : "transparent"

        Behavior on width {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        HoverHandler {
            id: hov
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: "#668c6d4f"
            opacity: hov.hovered ? 1.0 : 0.0
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: win.railOpen
            spacing: 6
            opacity: hov.hovered ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Repeater {
                model: ToplevelManager.toplevels

                delegate: Item {
                    id: winRow
                    required property var modelData
                    width: parent.width
                    height: 34

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 22
                        radius: 2
                        color: Theme.accent
                        visible: winRow.modelData.activated
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        opacity: winRow.modelData.activated ? 1.0 : 0.7

                        IconImage {
                            implicitSize: 20
                            source: win.iconFor(winRow.modelData.appId)
                            visible: source !== ""
                        }

                        Text {
                            visible: win.iconFor(winRow.modelData.appId) === ""
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: winRow.modelData.appId.substring(0, 1).toUpperCase()
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Text {
                            width: 100
                            elide: Text.ElideRight
                            text: winRow.modelData.appId
                            color: winRow.modelData.activated ? Theme.fg : Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: function (mouse) {
                            if (mouse.button === Qt.LeftButton)
                                winRow.modelData.activate()
                            else
                                winRow.modelData.close()
                        }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 20
                height: 1
                color: "#998c6d4f"
                visible: ToplevelManager.toplevels.values.length > 0 && SystemTray.items.values.length > 0
            }

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: trayRow
                    required property var modelData
                    width: parent.width
                    height: 30

                    MouseArea {
                        anchors.fill: parent
                        onClicked: trayRow.modelData.activate()
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        opacity: 0.8

                        IconImage {
                            implicitSize: 16
                            source: trayRow.modelData.icon
                        }

                        Text {
                            width: 56
                            elide: Text.ElideRight
                            text: trayRow.modelData.title !== "" ? trayRow.modelData.title : trayRow.modelData.id
                            color: Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Cerrar"
                        color: Theme.accent2
                        font.family: Theme.fontUi
                        font.pixelSize: 10

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: Quickshell.execDetached(["sh", "-c", "$HOME/.config/quickshell/scripts/trayquit.sh \"$0\"", trayRow.modelData.id])
                        }
                    }
                }
            }
        }
    }
}
