import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: win

    // Ancho de la tarjeta y de la franja sensible del borde derecho.
    readonly property int cardW: 150
    readonly property int railClosed: 6

    // Brillo previo al tinte: 0 = como antes (iconos oscuros), 1 = silueta plana.
    readonly property real iconBoost: 0.5

    // Altura del ratón al tocar el borde: la tarjeta se centra ahí.
    property real anchorY: 300

    // La tarjeta se muestra mientras el ratón esté en la franja o en la tarjeta.
    readonly property bool open: edgeHov.hovered || holdHov.hovered

    anchors {
        top: true
        right: true
        bottom: true
    }
    implicitWidth: cardW + 24
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dock"
    visible: ToplevelManager.toplevels.values.length > 0 || SystemTray.items.values.length > 0

    // Solo recibe clics la franja del borde y, abierta, la tarjeta.
    mask: Region {
        item: edge
        Region { item: holder }
    }

    // Agrupa las ventanas abiertas por aplicación (una fila por app).
    function buildGroups() {
        var vals = ToplevelManager.toplevels.values
        var order = []
        var map = {}
        for (var i = 0; i < vals.length; i++) {
            var key = vals[i].appId
            if (map[key] === undefined) {
                map[key] = []
                order.push(key)
            }
            map[key].push(vals[i])
        }
        var out = []
        for (var j = 0; j < order.length; j++)
            out.push({ appId: order[j], wins: map[order[j]] })
        return out
    }
    property var groups: buildGroups()

    // Clic izquierdo: pasa a la siguiente ventana del grupo.
    function focusGroup(wins) {
        var idx = -1
        for (var i = 0; i < wins.length; i++)
            if (wins[i].activated) idx = i
        wins[(idx + 1) % wins.length].activate()
    }

    // Clic derecho o central: cierra la ventana activa del grupo (o la última).
    function closeGroup(wins) {
        for (var i = 0; i < wins.length; i++) {
            if (wins[i].activated) {
                wins[i].close()
                return
            }
        }
        wins[wins.length - 1].close()
    }

    function iconFor(id) {
        var e = DesktopEntries.heuristicLookup(id)
        var name = (e && e.icon) ? e.icon : id
        return Quickshell.iconPath(name, true)
    }

    // Franja invisible del borde derecho: al tocarla se abre la tarjeta.
    // Mientras la tarjeta esté invisible, anota la altura del ratón.
    Item {
        id: edge
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: win.railClosed

        HoverHandler {
            id: edgeHov
            onPointChanged: {
                if (card.opacity < 0.05)
                    win.anchorY = point.position.y
            }
            onHoveredChanged: {
                if (hovered && card.opacity < 0.05)
                    win.anchorY = point.position.y
            }
        }
    }

    // Zona sensible de la tarjeta (con su margen); mide 0 cuando está cerrada.
    Item {
        id: holder
        anchors.right: parent.right
        width: win.open ? win.cardW + 14 : 0
        height: card.height
        // Centrada en la altura del ratón, sin invadir la barra ni salirse por abajo.
        y: Math.max(40, Math.min(parent.height - height - 12, win.anchorY - height / 2))

        HoverHandler {
            id: holdHov
        }

        Rectangle {
            id: card
            anchors.right: parent.right
            anchors.rightMargin: 10
            width: win.cardW
            height: col.implicitHeight + 20
            radius: Theme.radius
            color: Theme.bgPopup
            border.color: Theme.line
            border.width: 1
            opacity: win.open ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Column {
                id: col
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                spacing: 2

                // Sección: ventanas abiertas
                Item {
                    width: parent.width
                    height: 16
                    visible: win.groups.length > 0

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.bottom: parent.bottom
                        text: "Ventanas"
                        color: Theme.line
                        font.family: Theme.fontUi
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        font.capitalization: Font.AllUppercase
                    }
                }

                Repeater {
                    model: win.groups

                    delegate: Item {
                        id: grp
                        required property var modelData
                        width: parent.width
                        height: 26

                        readonly property string icon: win.iconFor(modelData.appId)
                        readonly property bool isActive: modelData.wins.some(function (w) { return w.activated })
                        readonly property color tint: (isActive || area.containsMouse) ? Theme.accent : Theme.fgMuted

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: grp.isActive ? Qt.alpha(Theme.accent, 0.16) : (area.containsMouse ? Qt.alpha(Theme.fg, 0.07) : "transparent")
                            border.width: grp.isActive ? 1 : 0
                            border.color: Qt.alpha(Theme.accent, 0.5)
                        }

                        IconImage {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 16
                            source: grp.icon
                            visible: grp.icon !== ""
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                brightness: win.iconBoost
                                colorization: 1.0
                                colorizationColor: grp.tint
                            }
                        }

                        Text {
                            x: 10
                            width: 16
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignHCenter
                            visible: grp.icon === ""
                            text: grp.modelData.appId.substring(0, 1).toUpperCase()
                            color: grp.tint
                            font.family: Theme.fontUi
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 34
                            anchors.right: cnt.left
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: grp.modelData.appId
                            color: grp.tint
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }

                        Text {
                            id: cnt
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: grp.modelData.wins.length > 1 ? "×" + grp.modelData.wins.length : ""
                            color: Theme.accent
                            font.family: Theme.fontUi
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: function (mouse) {
                                if (mouse.button === Qt.LeftButton)
                                    win.focusGroup(grp.modelData.wins)
                                else
                                    win.closeGroup(grp.modelData.wins)
                            }
                        }
                    }
                }

                // Sección: segundo plano (bandeja del sistema)
                Item {
                    width: parent.width
                    height: win.groups.length > 0 ? 24 : 16
                    visible: SystemTray.items.values.length > 0

                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 3
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        height: 1
                        color: Theme.line
                        opacity: 0.4
                        visible: win.groups.length > 0
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.bottom: parent.bottom
                        text: "Segundo plano"
                        color: Theme.line
                        font.family: Theme.fontUi
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        font.capitalization: Font.AllUppercase
                    }
                }

                Repeater {
                    model: SystemTray.items

                    delegate: Item {
                        id: tray
                        required property var modelData
                        width: parent.width
                        height: 26

                        readonly property color tint: trayArea.containsMouse ? Theme.accent : Theme.fgMuted

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: trayArea.containsMouse ? Qt.alpha(Theme.fg, 0.07) : "transparent"
                        }

                        MouseArea {
                            id: trayArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: tray.modelData.activate()
                        }

                        IconImage {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 16
                            source: tray.modelData.icon
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                brightness: win.iconBoost
                                colorization: 1.0
                                colorizationColor: tray.tint
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 34
                            anchors.right: closeTxt.left
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: tray.modelData.title !== "" ? tray.modelData.title : tray.modelData.id
                            color: tray.tint
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                        }

                        Text {
                            id: closeTxt
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Cerrar"
                            color: Theme.accent2
                            font.family: Theme.fontUi
                            font.pixelSize: 10

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: Quickshell.execDetached(["sh", "-c", "$HOME/.config/quickshell/scripts/trayquit.sh \"$0\"", tray.modelData.id])
                            }
                        }
                    }
                }
            }
        }
    }
}
