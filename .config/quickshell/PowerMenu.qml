import Quickshell
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: menu

    signal closeRequested()

    property string armed: ""

    readonly property var items: [
        { id: "lock", t: "Bloquear pantalla", i: "\uf023", c: ["sh", "-c", "command -v hyprlock >/dev/null && hyprlock || loginctl lock-session"], danger: false, confirm: false },
        { id: "suspend", t: "Suspender", i: "\uf186", c: ["systemctl", "suspend"], danger: false, confirm: false },
        { id: "logout", t: "Cerrar sesión", i: "\uf08b", c: ["sh", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER"], danger: false, confirm: true },
        { id: "reboot", t: "Reiniciar", i: "\uf021", c: ["systemctl", "reboot"], danger: false, confirm: true },
        { id: "poweroff", t: "Apagar", i: "\uf011", c: ["systemctl", "poweroff"], danger: true, confirm: true }
    ]

    function activate(it) {
        if (it.confirm && menu.armed !== it.id) {
            menu.armed = it.id
            disarm.restart()
            return
        }
        menu.armed = ""
        menu.closeRequested()
        Quickshell.execDetached(it.c)
    }

    onVisibleChanged: {
        if (!visible)
            armed = ""
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: menu.armed = ""
    }

    implicitWidth: 240
    implicitHeight: col.implicitHeight + 16
    color: "transparent"

    HyprlandFocusGrab {
        windows: [menu]
        active: menu.visible
        onCleared: menu.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgPopup
        border.color: Theme.line
        border.width: 1

        Column {
            id: col
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            Repeater {
                model: menu.items

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index

                    readonly property bool isArmed: menu.armed === modelData.id
                    readonly property color hot: modelData.danger ? Theme.accent2 : Theme.accent

                    width: col.width
                    height: 38

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            horizontalAlignment: Text.AlignHCenter
                            text: row.modelData.i
                            color: area.containsMouse || row.isArmed ? row.hot : Theme.fg
                            font.family: Theme.fontIcons
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.isArmed ? "¿Seguro? Pulse otra vez" : row.modelData.t
                            color: area.containsMouse || row.isArmed ? row.hot : Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.line
                        opacity: 0.3
                        visible: row.index < menu.items.length - 1
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: menu.activate(row.modelData)
                    }
                }
            }
        }
    }
}
