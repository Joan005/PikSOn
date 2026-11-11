import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: cal

    signal closeRequested()

    property date shown: new Date()
    property date today: new Date()
    property date selected: new Date()
    property var agenda: ({})
    property bool adding: false
    property int newTag: 0

    readonly property var monthNames: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    readonly property var dayNames: ["L", "M", "X", "J", "V", "S", "D"]
    readonly property var dayLong: ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]
    readonly property var tags: [
        { n: "Pendiente", c: "#cf5b4a" },
        { n: "Lectura", c: "#6fa597" },
        { n: "Música", c: "#e2b564" }
    ]
    readonly property string dataDir: Quickshell.env("HOME") + "/.local/share/pikson"
    readonly property string dataFile: dataDir + "/agenda.json"

    readonly property int firstOffset: (new Date(shown.getFullYear(), shown.getMonth(), 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property string selKey: keyOf(selected)
    readonly property var selectedTasks: agenda[selKey] || []

    function p2(n) {
        return n < 10 ? "0" + n : "" + n
    }

    function keyOf(d) {
        return d.getFullYear() + "-" + p2(d.getMonth() + 1) + "-" + p2(d.getDate())
    }

    function dotsFor(day) {
        var list = agenda[keyOf(new Date(shown.getFullYear(), shown.getMonth(), day))] || []
        var out = []
        for (var i = 0; i < list.length; i++) {
            var c = tags[list[i].tag].c
            if (out.indexOf(c) < 0)
                out.push(c)
        }
        return out
    }

    function shift(n) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1)
    }

    function goToday() {
        today = new Date()
        shown = new Date()
        selected = new Date()
    }

    function save() {
        store.setText(JSON.stringify(agenda, null, 1))
    }

    function copyAgenda() {
        return JSON.parse(JSON.stringify(agenda))
    }

    function addTask(text) {
        var t = text.trim()
        if (t === "")
            return
        var a = copyAgenda()
        var l = a[selKey] || []
        l.push({ t: t, tag: newTag, done: false })
        a[selKey] = l
        agenda = a
        save()
    }

    function toggle(i) {
        var a = copyAgenda()
        a[selKey][i].done = !a[selKey][i].done
        agenda = a
        save()
    }

    function remove(i) {
        var a = copyAgenda()
        a[selKey].splice(i, 1)
        if (a[selKey].length === 0)
            delete a[selKey]
        agenda = a
        save()
    }

    onVisibleChanged: {
        if (visible) {
            goToday()
            adding = false
            store.reload()
        }
    }

    Process {
        id: mk
        command: ["mkdir", "-p", cal.dataDir]
        running: true
    }

    FileView {
        id: store
        path: cal.dataFile
        onLoaded: {
            try {
                cal.agenda = JSON.parse(store.text())
            } catch (e) {
                cal.agenda = ({})
            }
        }
        onLoadFailed: cal.agenda = ({})
    }

    implicitWidth: 620
    implicitHeight: Math.max(leftCol.implicitHeight, rightCol.implicitHeight) + 32
    color: "transparent"

    HyprlandFocusGrab {
        windows: [cal]
        active: cal.visible
        onCleared: cal.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgPopup
        border.color: Theme.line
        border.width: 1

        Column {
            id: leftCol
            x: 16
            y: 16
            width: 252
            spacing: 8

            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: cal.monthNames[cal.shown.getMonth()].toUpperCase() + " " + cal.shown.getFullYear()
                    color: titleArea.containsMouse ? Theme.fg : Theme.accent
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    font.bold: true

                    MouseArea {
                        id: titleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: cal.goToday()
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: "\uf104"
                        color: prevArea.containsMouse ? Theme.accent : Theme.fgMuted
                        font.family: Theme.fontIcons
                        font.pixelSize: 15

                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: cal.shift(-1)
                        }
                    }

                    Text {
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: "\uf105"
                        color: nextArea.containsMouse ? Theme.accent : Theme.fgMuted
                        font.family: Theme.fontIcons
                        font.pixelSize: 15

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: cal.shift(1)
                        }
                    }
                }
            }

            Row {
                Repeater {
                    model: cal.dayNames

                    delegate: Item {
                        required property string modelData
                        required property int index

                        width: 36
                        height: 18

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: parent.index === 6 ? "#cf5b4a" : Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }
            }

            Grid {
                columns: 7

                Repeater {
                    model: 42

                    delegate: Item {
                        id: cell
                        required property int index

                        readonly property int day: index - cal.firstOffset + 1
                        readonly property bool valid: day >= 1 && day <= cal.daysInMonth
                        readonly property bool isToday: valid && day === cal.today.getDate() && cal.shown.getMonth() === cal.today.getMonth() && cal.shown.getFullYear() === cal.today.getFullYear()
                        readonly property bool isSel: valid && day === cal.selected.getDate() && cal.shown.getMonth() === cal.selected.getMonth() && cal.shown.getFullYear() === cal.selected.getFullYear()

                        width: 36
                        height: 34

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 1
                            width: 28
                            height: 28
                            radius: 14
                            color: cell.isSel ? "#33e2b564" : "transparent"
                            border.color: Theme.accent
                            border.width: cell.isToday ? 1 : 0
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 8
                            text: cell.valid ? cell.day : ""
                            color: cell.isSel ? Theme.accent : (cell.index % 7 === 6 ? "#cf5b4a" : Theme.fg)
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: cell.isSel || cell.isToday
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 29
                            spacing: 2

                            Repeater {
                                model: cell.valid ? cal.dotsFor(cell.day) : []

                                delegate: Rectangle {
                                    required property var modelData

                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: modelData
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (cell.valid) {
                                    cal.selected = new Date(cal.shown.getFullYear(), cal.shown.getMonth(), cell.day)
                                    cal.adding = false
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            x: 288
            y: 16
            width: 1
            height: parent.height - 32
            color: Theme.line
            opacity: 0.4
        }

        Column {
            id: rightCol
            x: 309
            y: 16
            width: parent.width - 309 - 16
            spacing: 6

            Text {
                width: parent.width
                text: cal.dayLong[cal.selected.getDay()] + " " + cal.selected.getDate() + " de " + cal.monthNames[cal.selected.getMonth()].toLowerCase()
                color: Theme.fg
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                text: cal.selectedTasks.length === 0 ? "Nada apuntado" : cal.selectedTasks.length + (cal.selectedTasks.length === 1 ? " tarea" : " tareas")
                color: Theme.fgMuted
                font.family: Theme.fontUi
                font.pixelSize: 10
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.line
                opacity: 0.4
            }

            Column {
                width: parent.width

                Repeater {
                    model: cal.selectedTasks

                    delegate: Item {
                        id: tr
                        required property var modelData
                        required property int index

                        width: rightCol.width
                        height: Math.max(30, taskText.implicitHeight + 14)

                        Rectangle {
                            x: 0
                            y: (parent.height - 14) / 2
                            width: 14
                            height: 14
                            radius: 3
                            color: tr.modelData.done ? "#33e2b564" : "transparent"
                            border.color: tr.modelData.done ? Theme.accent : Theme.fgMuted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "\uf00c"
                                visible: tr.modelData.done
                                color: Theme.accent
                                font.family: Theme.fontIcons
                                font.pixelSize: 9
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: cal.toggle(tr.index)
                            }
                        }

                        Text {
                            id: taskText
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24 - 20 - 22
                            text: tr.modelData.t
                            wrapMode: Text.WordWrap
                            color: Theme.fg
                            opacity: tr.modelData.done ? 0.5 : 1
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.strikeout: tr.modelData.done
                        }

                        Rectangle {
                            anchors.right: xBtn.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 7
                            height: 7
                            radius: 3.5
                            color: cal.tags[tr.modelData.tag].c
                        }

                        Text {
                            id: xBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: "\uf00d"
                            color: xArea.containsMouse ? Theme.accent2 : Theme.fgMuted
                            opacity: xArea.containsMouse ? 1 : 0.5
                            font.family: Theme.fontIcons
                            font.pixelSize: 11

                            MouseArea {
                                id: xArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: cal.remove(tr.index)
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.line
                            opacity: 0.25
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 34

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !cal.adding
                    text: "+ Añadir una tarea…"
                    color: addArea.containsMouse ? Theme.accent : Theme.fgMuted
                    font.family: Theme.fontUi
                    font.pixelSize: 11

                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            cal.adding = true
                            input.forceActiveFocus()
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: cal.adding
                    spacing: 8

                    Repeater {
                        model: cal.tags

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            radius: 6
                            color: modelData.c
                            border.color: Theme.fg
                            border.width: cal.newTag === index ? 2 : 0
                            opacity: cal.newTag === index ? 1 : 0.55

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    cal.newTag = index
                                    input.forceActiveFocus()
                                }
                            }
                        }
                    }

                    TextInput {
                        id: input
                        anchors.verticalCenter: parent.verticalCenter
                        width: rightCol.width - 60
                        clip: true
                        color: Theme.fg
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.fgOnAccent
                        font.family: Theme.fontUi
                        font.pixelSize: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: "Escriba y pulse Enter"
                            color: Theme.fgMuted
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                        }

                        Keys.onReturnPressed: {
                            cal.addTask(input.text)
                            input.text = ""
                        }
                        Keys.onEnterPressed: {
                            cal.addTask(input.text)
                            input.text = ""
                        }
                        Keys.onEscapePressed: cal.adding = false
                    }
                }
            }
        }
    }
}
