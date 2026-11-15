import Quickshell
import Quickshell.Io
import QtQuick

PopupWindow {
    id: panel

    signal closeRequested()

    implicitWidth: 560
    implicitHeight: 560
    color: "transparent"

    readonly property real stageW: 524
    readonly property real stageH: 190

    property var mons: []
    property int sel: 0
    property string pendRes: ""
    property string pendRate: ""
    property real pendScale: 1.0
    property int pendX: 0
    property int pendY: 0
    property int pendTr: 0
    property string status: ""
    property bool confirming: false
    property bool reverting: false
    property bool savePending: false
    property int countdown: 15
    property var prev: null

    property real fx0: 0
    property real fy0: 0
    property real ffac: 0.1

    onPendTrChanged: recalcFrame()
    onPendScaleChanged: recalcFrame()
    onPendResChanged: recalcFrame()

    readonly property var cur: (sel >= 0 && sel < mons.length) ? mons[sel] : null
    readonly property var resOptions: cur ? sortRes(cur.resList) : []
    readonly property var rateOptions: (cur && cur.modes[pendRes]) ? cur.modes[pendRes] : []
    readonly property var scaleOptions: [1.0, 1.25, 1.5, 1.75, 2.0]
    readonly property bool dirty: cur !== null && (pendRes !== cur.w + "x" + cur.h || Math.abs(parseFloat(pendRate) - cur.rate) > 0.5 || Math.abs(pendScale - cur.scale) > 0.001 || pendX !== cur.x || pendY !== cur.y || pendTr !== cur.transform)

    function dimsOf(i) {
        var m = mons[i]
        var w = m.w
        var h = m.h
        var tr = m.transform
        var sc = m.scale
        if (i === sel) {
            var wh = pendRes.split("x")
            if (wh.length === 2) {
                w = parseInt(wh[0])
                h = parseInt(wh[1])
            }
            tr = pendTr
            sc = pendScale
        }
        var swap = (tr % 2) === 1
        return { w: (swap ? h : w) / sc, h: (swap ? w : h) / sc }
    }

    function posOf(i) {
        if (i === sel)
            return { x: pendX, y: pendY }
        return { x: mons[i].x, y: mons[i].y }
    }

    function recalcFrame() {
        if (mons.length === 0)
            return
        var x0 = 1e9
        var y0 = 1e9
        var x1 = -1e9
        var y1 = -1e9
        var mw = 0
        var mh = 0
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i]
            var dd = dimsOf(i)
            var w = dd.w
            var h = dd.h
            x0 = Math.min(x0, m.x)
            y0 = Math.min(y0, m.y)
            x1 = Math.max(x1, m.x + w)
            y1 = Math.max(y1, m.y + h)
            mw = Math.max(mw, w)
            mh = Math.max(mh, h)
        }
        x0 -= mw * 0.35
        x1 += mw * 0.35
        y0 -= mh * 0.35
        y1 += mh * 0.35
        var W = x1 - x0
        var H = y1 - y0
        var f = Math.min((stageW - 20) / W, (stageH - 20) / H)
        ffac = f
        fx0 = x0 - ((stageW - W * f) / 2) / f
        fy0 = y0 - ((stageH - H * f) / 2) / f
    }

    function sortRes(list) {
        var a = list.slice()
        a.sort(function (p, q) {
            var pp = p.split("x")
            var qq = q.split("x")
            return parseInt(qq[0]) * parseInt(qq[1]) - parseInt(pp[0]) * parseInt(pp[1])
        })
        return a
    }

    function nearestRate(list, target) {
        var best = ""
        var bd = 1e9
        for (var i = 0; i < list.length; i++) {
            var d = Math.abs(parseFloat(list[i]) - target)
            if (d < bd) {
                bd = d
                best = list[i]
            }
        }
        return best
    }

    function maxRate(list) {
        var best = ""
        var bv = -1
        for (var i = 0; i < list.length; i++) {
            var v = parseFloat(list[i])
            if (v > bv) {
                bv = v
                best = list[i]
            }
        }
        return best
    }

    function rateLabel(r) {
        var f = parseFloat(r)
        var near = Math.abs(f - Math.round(f)) < 0.05
        return (near ? String(Math.round(f)) : f.toFixed(2)) + " Hz"
    }

    function syncSel() {
        if (!cur)
            return
        pendRes = cur.w + "x" + cur.h
        pendRate = nearestRate(cur.modes[pendRes] || [], cur.rate)
        pendScale = cur.scale
        pendX = cur.x
        pendY = cur.y
        pendTr = cur.transform
        recalcFrame()
    }

    function pickMonitor(i) {
        if (i === sel)
            return
        sel = i
        syncSel()
    }

    function selectRes(r) {
        pendRes = r
        var list = cur.modes[r] || []
        pendRate = maxRate(list)
    }

    function snapSelected() {
        if (mons.length < 2 || !cur)
            return
        var d = dimsOf(sel)
        var x = pendX
        var y = pendY
        var T = 60
        var bestX = x
        var bestY = y
        var bdx = T + 1
        var bdy = T + 1
        var i
        for (i = 0; i < mons.length; i++) {
            if (i === sel)
                continue
            var o = mons[i]
            var od = dimsOf(i)
            var cx = [o.x - d.w, o.x + od.w, o.x, o.x + od.w - d.w]
            var cy = [o.y - d.h, o.y + od.h, o.y, o.y + od.h - d.h]
            for (var a = 0; a < 4; a++) {
                var ddx = Math.abs(cx[a] - x)
                if (ddx < bdx) {
                    bdx = ddx
                    bestX = cx[a]
                }
                var ddy = Math.abs(cy[a] - y)
                if (ddy < bdy) {
                    bdy = ddy
                    bestY = cy[a]
                }
            }
        }
        x = bestX
        y = bestY
        for (i = 0; i < mons.length; i++) {
            if (i === sel)
                continue
            var p = mons[i]
            var pd = dimsOf(i)
            var ox = Math.min(x + d.w, p.x + pd.w) - Math.max(x, p.x)
            var oy = Math.min(y + d.h, p.y + pd.h) - Math.max(y, p.y)
            if (ox > 0 && oy > 0) {
                if (ox < oy)
                    x += (x + d.w / 2 < p.x + pd.w / 2) ? -ox : ox
                else
                    y += (y + d.h / 2 < p.y + pd.h / 2) ? -oy : oy
            }
        }
        pendX = Math.round(x)
        pendY = Math.round(y)
    }

    function gotList(text) {
        var arr = []
        try {
            arr = JSON.parse(text)
        } catch (e) {
            arr = []
        }
        var out = []
        for (var i = 0; i < arr.length; i++) {
            var m = arr[i]
            var modes = {}
            var resList = []
            var am = m.availableModes || []
            for (var j = 0; j < am.length; j++) {
                var mm = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(am[j])
                if (!mm)
                    continue
                var r = mm[1] + "x" + mm[2]
                if (!modes[r]) {
                    modes[r] = []
                    resList.push(r)
                }
                modes[r].push(mm[3])
            }
            out.push({
                name: m.name,
                desc: m.description || m.name,
                w: m.width,
                h: m.height,
                rate: m.refreshRate,
                x: m.x,
                y: m.y,
                scale: m.scale,
                transform: m.transform || 0,
                modes: modes,
                resList: resList
            })
        }
        mons = out
        if (sel >= out.length)
            sel = 0
        syncSel()
        recalcFrame()
        if (savePending) {
            savePending = false
            saveFile()
        }
    }

    function saveFile() {
        var lines = ["-- Generado por el panel de Pantallas de Quickshell. No lo edite a mano."]
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i]
            var rate = nearestRate(m.modes[m.w + "x" + m.h] || [], m.rate)
            if (rate === "")
                rate = m.rate.toFixed(2)
            var sc = String(Math.round(m.scale * 100) / 100)
            var s = "hl.monitor({ output = \"" + m.name + "\", mode = \"" + m.w + "x" + m.h + "@" + rate + "\", position = \"" + m.x + "x" + m.y + "\", scale = \"" + sc + "\""
            if (m.transform !== 0)
                s += ", transform = " + m.transform
            s += " })"
            lines.push(s)
        }
        saveProc.command = ["sh", "-c", "mkdir -p \"$HOME/.config/hypr\" && printf '%s\\n' \"$0\" > \"$HOME/.config/hypr/monitors.lua\" && echo ok", lines.join("\n")]
        saveProc.running = true
    }

    function runSet(name, mode, pos, scale, tr) {
        setProc.command = ["sh", "-c", "$HOME/.config/quickshell/scripts/monitor-set.sh \"$0\" \"$1\" \"$2\" \"$3\" \"$4\"", name, mode, pos, String(scale), String(tr)]
        setProc.running = true
    }

    function applyChange() {
        if (!cur)
            return
        status = ""
        var pr = nearestRate(cur.modes[cur.w + "x" + cur.h] || [], cur.rate)
        if (pr === "")
            pr = cur.rate.toFixed(2)
        prev = {
            name: cur.name,
            mode: cur.w + "x" + cur.h + "@" + pr,
            pos: cur.x + "x" + cur.y,
            scale: cur.scale,
            tr: cur.transform
        }
        reverting = false
        runSet(cur.name, pendRes + "@" + pendRate, pendX + "x" + pendY, pendScale, pendTr)
    }

    function revertNow() {
        if (!prev) {
            confirming = false
            return
        }
        confirming = false
        reverting = true
        runSet(prev.name, prev.mode, prev.pos, prev.scale, prev.tr)
    }

    function keepNow() {
        confirming = false
        prev = null
        status = "Guardando…"
        savePending = true
        listProc.running = true
    }

    function setDone(t) {
        if (t === "ok") {
            status = ""
            if (reverting) {
                reverting = false
                confirming = false
                prev = null
            } else {
                confirming = true
                countdown = 15
            }
        } else {
            status = t
            if (reverting) {
                reverting = false
                confirming = false
            } else {
                prev = null
            }
        }
        refreshTimer.restart()
    }

    onVisibleChanged: {
        if (visible)
            listProc.running = true
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool active: false
        signal clicked()
        implicitWidth: pt.implicitWidth + 22
        implicitHeight: 26
        radius: 13
        color: pill.active ? Theme.accent : "transparent"
        border.color: pill.active ? Theme.accent : Theme.line
        border.width: 1

        Text {
            id: pt
            anchors.centerIn: parent
            text: pill.label
            color: pill.active ? Theme.fgOnAccent : Theme.fg
            font.family: Theme.fontUi
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pill.clicked()
        }
    }

    Process {
        id: listProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: panel.gotList(this.text)
        }
    }

    Process {
        id: setProc
        stdout: StdioCollector {
            onStreamFinished: panel.setDone(this.text.trim())
        }
    }

    Process {
        id: saveProc
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                panel.status = t === "ok" ? "Guardado en ~/.config/hypr/monitors.lua" : "No se pudo guardar: " + t
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 700
        onTriggered: listProc.running = true
    }

    Timer {
        interval: 1000
        repeat: true
        running: panel.confirming
        onTriggered: {
            panel.countdown -= 1
            if (panel.countdown <= 0)
                panel.revertNow()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPopup
        radius: Theme.radius
        border.color: Theme.line
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Column {
                width: parent.width
                spacing: 2

                Text {
                    text: "Pantallas"
                    color: Theme.accent
                    font.family: Theme.fontUi
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    text: panel.mons.length > 1 ? "Seleccione una pantalla para cambiar su configuración. Arrástrelas para reorganizarlas." : "Seleccione una pantalla para cambiar su configuración."
                    color: Theme.fgMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                }
            }

            Rectangle {
                id: stage
                clip: true
                width: panel.stageW
                height: panel.stageH
                radius: 10
                color: "#33000000"
                border.color: Theme.line
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    visible: panel.mons.length === 0
                    text: "Sin datos de pantallas"
                    color: Theme.fgMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                }

                Repeater {
                    model: panel.mons

                    delegate: Rectangle {
                        id: mon
                        required property var modelData
                        required property int index
                        x: (panel.posOf(mon.index).x - panel.fx0) * panel.ffac
                        y: (panel.posOf(mon.index).y - panel.fy0) * panel.ffac
                        width: panel.dimsOf(mon.index).w * panel.ffac
                        height: panel.dimsOf(mon.index).h * panel.ffac
                        radius: 4
                        color: mon.index === panel.sel ? "#33e2b564" : "#808c6c4e"
                        border.color: mon.index === panel.sel ? Theme.accent : Theme.line
                        border.width: mon.index === panel.sel ? 2 : 1
                        z: mon.index === panel.sel ? 2 : 1

                        Text {
                            anchors.centerIn: parent
                            text: String(mon.index + 1)
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            property real gx: 0
                            property real gy: 0
                            onPressed: (mouse) => {
                                panel.pickMonitor(mon.index)
                                gx = mouse.x
                                gy = mouse.y
                            }
                            onPositionChanged: (mouse) => {
                                if (!dragArea.pressed || panel.mons.length < 2)
                                    return
                                var p = dragArea.mapToItem(stage, mouse.x, mouse.y)
                                panel.pendX = Math.round(panel.fx0 + (p.x - dragArea.gx) / panel.ffac)
                                panel.pendY = Math.round(panel.fy0 + (p.y - dragArea.gy) / panel.ffac)
                            }
                            onReleased: panel.snapSelected()
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: panel.cur !== null
                elide: Text.ElideRight
                text: panel.cur ? (String(panel.sel + 1) + " · " + panel.cur.desc + " · " + panel.cur.name + " · " + panel.cur.w + "×" + panel.cur.h + " @ " + panel.cur.rate.toFixed(0) + " Hz · posición " + panel.pendX + ", " + panel.pendY) : ""
                color: Theme.fg
                font.family: Theme.fontUi
                font.pixelSize: 11
            }

            Row {
                width: parent.width
                spacing: 18
                visible: panel.cur !== null

                Column {
                    width: 200
                    spacing: 6

                    Text {
                        text: "Resolución"
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }

                    ListView {
                        width: 200
                        height: 130
                        clip: true
                        model: panel.resOptions

                        delegate: Rectangle {
                            id: resRow
                            required property var modelData
                            width: ListView.view.width
                            height: 26
                            radius: 6
                            color: panel.pendRes === resRow.modelData ? "#33e2b564" : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: resRow.modelData.replace("x", " × ") + (panel.cur && resRow.modelData === panel.cur.w + "x" + panel.cur.h ? "   · actual" : "")
                                color: panel.pendRes === resRow.modelData ? Theme.accent : Theme.fg
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.selectRes(resRow.modelData)
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - 218
                    spacing: 8

                    Text {
                        text: "Frecuencia"
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: panel.rateOptions

                            delegate: Pill {
                                required property var modelData
                                label: panel.rateLabel(modelData)
                                active: panel.pendRate === modelData
                                onClicked: panel.pendRate = modelData
                            }
                        }
                    }

                    Text {
                        text: "Escala"
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: panel.scaleOptions

                            delegate: Pill {
                                required property var modelData
                                label: Math.round(modelData * 100) + " %"
                                active: Math.abs(panel.pendScale - modelData) < 0.01
                                onClicked: panel.pendScale = modelData
                            }
                        }
                    }

                    Text {
                        text: "Rotación"
                        color: Theme.fgMuted
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                    }

                    Flow {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [0, 1, 2, 3]

                            delegate: Pill {
                                required property var modelData
                                label: (modelData * 90) + "°"
                                active: panel.pendTr === modelData
                                onClicked: panel.pendTr = modelData
                            }
                        }
                    }
                }
            }

            Row {
                spacing: 10
                visible: panel.cur !== null

                Pill {
                    visible: !panel.confirming
                    label: "Aplicar"
                    active: panel.dirty
                    onClicked: if (panel.dirty) panel.applyChange()
                }

                Pill {
                    visible: !panel.confirming && panel.dirty
                    label: "Descartar"
                    onClicked: panel.syncSel()
                }

                Text {
                    visible: panel.confirming
                    height: 26
                    verticalAlignment: Text.AlignVCenter
                    text: "¿Conservar esta configuración? Se revierte en " + panel.countdown + " s"
                    color: Theme.fg
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                }

                Pill {
                    visible: panel.confirming
                    label: "Revertir"
                    onClicked: panel.revertNow()
                }

                Pill {
                    visible: panel.confirming
                    label: "Conservar y guardar"
                    active: true
                    onClicked: panel.keepNow()
                }
            }

            Text {
                width: parent.width
                visible: panel.status !== ""
                wrapMode: Text.WordWrap
                text: panel.status
                color: Theme.accent2
                font.family: Theme.fontUi
                font.pixelSize: 11
            }
        }
    }
}
