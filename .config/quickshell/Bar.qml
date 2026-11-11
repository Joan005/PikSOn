import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 36
    color: "transparent"

    // estado de la red (net.sh)
    property string netType: "none"
    property string netDev: ""
    property string netIp: ""

    // paneles abiertos y detalle de la red (netinfo.sh)
    property bool calOpen: false
    property bool netOpen: false
    property bool powerOpen: false
    property bool soundOpen: false
    property bool notifOpen: false
    property bool weatherOpen: false
    property bool lyricsFloat: false
    property var info: ({})

    readonly property bool anyOpen: calOpen || netOpen || powerOpen || soundOpen || notifOpen || weatherOpen || playerChip.opened

    // volumen (-1 = sin datos)
    property int volPercent: -1
    property bool volMuted: false

    // notificaciones: historial, avisos emergentes y contador
    property var notifList: []
    property var toastList: []
    property int unread: 0
    property bool dnd: false

    function closeAll() {
        calOpen = false
        netOpen = false
        powerOpen = false
        soundOpen = false
        notifOpen = false
        weatherOpen = false
        playerChip.opened = false
    }

    function toggle(name) {
        var was = root[name]
        closeAll()
        root[name] = !was
    }

    function addNotif(n) {
        n.tracked = true
        var item = {
            id: n.id,
            app: n.appName !== "" ? n.appName : "Sistema",
            summary: n.summary,
            body: n.body,
            crit: n.urgency === NotificationUrgency.Critical,
            time: new Date(),
            ref: n
        }
        n.closed.connect(function () {
            root.removeNotif(item.id)
        })
        var l = [item].concat(root.notifList)
        if (l.length > 50)
            l = l.slice(0, 50)
        root.notifList = l
        if (!root.notifOpen)
            root.unread = root.unread + 1
        if (!root.dnd)
            root.toastList = [item].concat(root.toastList).slice(0, 4)
    }

    function removeNotif(id) {
        root.notifList = root.notifList.filter(function (x) { return x.id !== id })
        root.toastList = root.toastList.filter(function (x) { return x.id !== id })
        if (root.unread > root.notifList.length)
            root.unread = root.notifList.length
    }

    function dismissNotif(id) {
        for (var i = 0; i < root.notifList.length; i++) {
            if (root.notifList[i].id === id) {
                root.notifList[i].ref.dismiss()
                break
            }
        }
        removeNotif(id)
    }

    function clearNotifs() {
        var l = root.notifList
        for (var i = 0; i < l.length; i++)
            l[i].ref.dismiss()
        root.notifList = []
        root.toastList = []
        root.unread = 0
    }

    function hideToast(id) {
        root.toastList = root.toastList.filter(function (x) { return x.id !== id })
    }

    onNetOpenChanged: {
        if (netOpen)
            infoProc.running = true
    }

    onNotifOpenChanged: {
        if (notifOpen)
            unread = 0
    }

    Weather {
        id: weather
    }

    Lyrics {
        id: lyrics
        player: playerChip.player
        active: playerChip.opened || root.lyricsFloat
    }

    NotificationServer {
        id: nserver
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: false
        imageSupported: false
        onNotification: (n) => root.addNotif(n)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        id: netProc
        command: ["sh", "-c", "$HOME/.config/quickshell/scripts/net.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim().split("|")
                if (p[0] === "none" || p.length < 3) {
                    root.netType = "none"
                    root.netDev = ""
                    root.netIp = ""
                } else {
                    root.netType = p[0]
                    root.netDev = p[1]
                    root.netIp = p[2]
                }
            }
        }
    }

    Process {
        id: infoProc
        command: ["sh", "-c", "$HOME/.config/quickshell/scripts/netinfo.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var o = {}
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var k = lines[i].indexOf("=")
                    if (k > 0)
                        o[lines[i].substring(0, k)] = lines[i].substring(k + 1)
                }
                root.info = o
            }
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                if (t.indexOf("Volume:") !== 0) {
                    root.volPercent = -1
                    root.volMuted = false
                } else {
                    root.volPercent = Math.round(parseFloat(t.split(" ")[1]) * 100)
                    root.volMuted = t.indexOf("MUTED") >= 0
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }

    Timer {
        interval: 3000
        running: root.netOpen
        repeat: true
        onTriggered: infoProc.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }

    Timer {
        id: volRefresh
        interval: 200
        onTriggered: volProc.running = true
    }

    // capa invisible: recoge la pulsación fuera de los paneles y los cierra
    PanelWindow {
        id: catcher
        visible: root.anyOpen
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        margins {
            top: root.height
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "panel-catcher"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.closeAll()
        }
    }

    // fondo: degradado suave y una línea fina de latón abajo
    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#e61a110b" }
            GradientStop { position: 1.0; color: "#001a110b" }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#668c6d4f"
    }

    // workspaces en números romanos
    Row {
        id: wsRow
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: [1, 2, 3, 4, 5]

            delegate: Item {
                id: ws
                required property int modelData

                function findWs() {
                    var list = Hyprland.workspaces.values
                    for (var i = 0; i < list.length; i++) {
                        if (list[i].id === ws.modelData)
                            return list[i]
                    }
                    return null
                }

                readonly property var obj: findWs()
                readonly property bool exists: obj !== null
                readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

                width: numeral.implicitWidth + 14
                height: 28

                Text {
                    id: numeral
                    anchors.centerIn: parent
                    text: ["I", "II", "III", "IV", "V"][ws.modelData - 1]
                    color: ws.focused || wsArea.containsMouse ? Theme.accent : Theme.fgMuted
                    opacity: ws.exists ? 1 : 0.45
                    font.family: Theme.fontSerif
                    font.pixelSize: 16
                    font.bold: true
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    width: numeral.implicitWidth
                    height: 2
                    radius: 1
                    color: Theme.accent
                    visible: ws.focused
                }

                MouseArea {
                    id: wsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (ws.obj)
                            ws.obj.activate()
                        else
                            Hyprland.dispatch("workspace " + ws.modelData)
                    }
                }
            }
        }
    }

    Rectangle {
        id: sepLeft
        anchors.left: wsRow.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 14
        color: Theme.line
        opacity: 0.5
    }

    // chip de música, su panel y la letra flotante
    Player {
        id: playerChip
        anchors.left: sepLeft.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    PlayerPanel {
        anchor.window: root
        anchor.rect.x: playerChip.x
        anchor.rect.y: root.height + 4
        visible: playerChip.opened && playerChip.player !== null
        player: playerChip.player
        lyr: lyrics
        floating: root.lyricsFloat
        onFloatToggled: root.lyricsFloat = !root.lyricsFloat
    }

    LyricsFloat {
        lyr: lyrics
        title: playerChip.player ? ((playerChip.player.trackTitle || "") + (playerChip.player.trackArtist ? " · " + playerChip.player.trackArtist : "")) : ""
        visible: root.lyricsFloat && playerChip.player !== null
        onDock: root.lyricsFloat = false
    }

    // reloj en el centro y la agenda
    Item {
        id: clockBox
        anchors.centerIn: parent
        width: clockRow.implicitWidth
        height: 28

        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 9

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM")
                color: clockArea.containsMouse || root.calOpen ? Theme.accent : Theme.fg
                font.family: Theme.fontUi
                font.pixelSize: 12
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                color: clockArea.containsMouse || root.calOpen ? Theme.accent : Theme.fg
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.bold: true
            }
        }

        MouseArea {
            id: clockArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.toggle("calOpen")
        }
    }

    Calendar {
        anchor.window: root
        anchor.rect.x: (root.width - implicitWidth) / 2
        anchor.rect.y: root.height + 4
        visible: root.calOpen
        onCloseRequested: root.calOpen = false
    }

    // tiempo, volumen, red, campana y apagado a la derecha
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Item {
            id: weatherChip
            width: weatherRow.implicitWidth
            height: 28

            Row {
                id: weatherRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: weather.ready ? weather.glyph(weather.code, weather.isDay) : "\ue312"
                    color: weatherArea.containsMouse || root.weatherOpen ? Theme.accent : Theme.fg
                    opacity: weather.ready ? 1 : 0.5
                    font.family: Theme.fontIcons
                    font.pixelSize: 14
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: weather.ready ? weather.temp.toFixed(1) + "°C" : "--"
                    color: weatherArea.containsMouse || root.weatherOpen ? Theme.accent : Theme.fg
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: weatherArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.toggle("weatherOpen")
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 14
            color: Theme.line
            opacity: 0.5
        }

        Item {
            id: volChip
            width: volRow.implicitWidth
            height: 28

            Row {
                id: volRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volMuted || root.volPercent < 0 ? "\uf026" : "\uf028"
                    color: volArea.containsMouse || root.soundOpen ? Theme.accent : Theme.fg
                    font.family: Theme.fontIcons
                    font.pixelSize: 13
                }

                Text {
                    id: volText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volPercent < 0 ? "--" : (root.volMuted ? "mute" : root.volPercent + "%")
                    color: volArea.containsMouse || root.soundOpen ? Theme.accent : Theme.fg
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: volArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.toggle("soundOpen")
                onWheel: (wheel) => {
                    var paso = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                    Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", paso])
                    volRefresh.restart()
                }
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 14
            color: Theme.line
            opacity: 0.5
        }

        Item {
            id: netChip
            width: netRow.implicitWidth
            height: 28

            Row {
                id: netRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.netType === "wifi" ? "\uf1eb" : "\uf0e8"
                    color: netArea.containsMouse || root.netOpen ? Theme.accent : Theme.fg
                    opacity: root.netType === "none" ? 0.5 : 1
                    font.family: Theme.fontIcons
                    font.pixelSize: 13
                }

                Text {
                    id: netText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.netType === "none" ? "Sin red" : root.netIp.split("/")[0]
                    color: netArea.containsMouse || root.netOpen ? Theme.accent : Theme.fg
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: netArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.toggle("netOpen")
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 14
            color: Theme.line
            opacity: 0.5
        }

        Item {
            id: bellChip
            width: bellIcon.implicitWidth + (root.unread > 0 ? bellCount.implicitWidth + 6 : 0)
            height: 28

            Text {
                id: bellIcon
                anchors.verticalCenter: parent.verticalCenter
                text: root.dnd ? "\uf1f6" : "\uf0f3"
                color: bellArea.containsMouse || root.notifOpen ? Theme.accent : Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 13
            }

            Rectangle {
                x: bellIcon.implicitWidth - 3
                y: 5
                width: 6
                height: 6
                radius: 3
                color: "#cf5b4a"
                visible: root.unread > 0 && !root.dnd
            }

            Text {
                id: bellCount
                x: bellIcon.implicitWidth + 6
                anchors.verticalCenter: parent.verticalCenter
                text: root.unread
                visible: root.unread > 0
                color: bellArea.containsMouse || root.notifOpen ? Theme.accent : Theme.fg
                font.family: Theme.fontUi
                font.pixelSize: 12
            }

            MouseArea {
                id: bellArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.toggle("notifOpen")
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 14
            color: Theme.line
            opacity: 0.5
        }

        Item {
            id: powerChip
            width: 22
            height: 28

            Text {
                anchors.centerIn: parent
                text: "\uf011"
                color: powerArea.containsMouse || root.powerOpen ? Theme.accent : Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 13
            }

            MouseArea {
                id: powerArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.toggle("powerOpen")
            }
        }
    }

    WeatherPanel {
        anchor.window: root
        anchor.rect.x: root.width - implicitWidth - 8
        anchor.rect.y: root.height + 4
        visible: root.weatherOpen
        wx: weather
    }

    NetPanel {
        id: netPanel
        anchor.window: root
        anchor.rect.x: root.width - implicitWidth - 8
        anchor.rect.y: root.height + 4
        visible: root.netOpen
        info: root.info
    }

    SoundPanel {
        anchor.window: root
        anchor.rect.x: root.width - implicitWidth - 8
        anchor.rect.y: root.height + 4
        visible: root.soundOpen
        onCloseRequested: root.soundOpen = false
        onChanged: volRefresh.restart()
    }

    NotifPanel {
        anchor.window: root
        anchor.rect.x: root.width - implicitWidth - 8
        anchor.rect.y: root.height + 4
        visible: root.notifOpen
        items: root.notifList
        dnd: root.dnd
        onCloseRequested: root.notifOpen = false
        onDismissRequested: (id) => root.dismissNotif(id)
        onClearRequested: root.clearNotifs()
        onDndToggled: root.dnd = !root.dnd
    }

    NotifToasts {
        items: root.toastList
        onExpired: (id) => root.hideToast(id)
    }

    PowerMenu {
        anchor.window: root
        anchor.rect.x: root.width - implicitWidth - 8
        anchor.rect.y: root.height + 4
        visible: root.powerOpen
        onCloseRequested: root.powerOpen = false
    }
}
