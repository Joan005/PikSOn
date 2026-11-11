import Quickshell
import QtQuick

PopupWindow {
    id: cal

    property date shown: new Date()
    property date today: new Date()
    property date selected: new Date()
    property var agenda: ({})

    readonly property var monthNames: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    readonly property var dayNames: ["L", "M", "X", "J", "V", "S", "D"]
    readonly property var weekdayNames: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
    readonly property var tags: [
        { n: "Pendiente", c: "#a8352b" },
        { n: "Lectura", c: "#3f6f6a" },
        { n: "Música", c: "#b08a2e" }
    ]
    readonly property int firstOffset: (new Date(shown.getFullYear(), shown.getMonth(), 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property var selectedTasks: cal.agenda[cal.keyOf(cal.selected)] || []

    function keyOf(d) {
        return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate()
    }

    function tagColor(name) {
        for (var i = 0; i < tags.length; i++) {
            if (tags[i].n === name)
                return tags[i].c
        }
        return "#6b4f39"
    }

    function dotsFor(day) {
        var list = cal.agenda[cal.keyOf(new Date(shown.getFullYear(), shown.getMonth(), day))] || []
        var out = []
        for (var i = 0; i < list.length; i++) {
            var c = tagColor(list[i].tag)
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

    function toggle(i) {
        var list = cal.agenda[cal.keyOf(cal.selected)]
        if (!list)
            return
        list[i].done = !list[i].done
        cal.agenda = Object.assign({}, cal.agenda)
    }

    function seed() {
        var t = new Date()
        var a = {}
        a[keyOf(t)] = [
            { t: "Terminar los paneles del escritorio", tag: "Pendiente", done: false },
            { t: "Leer un capítulo antes de dormir", tag: "Lectura", done: true },
            { t: "Escuchar a Bocelli con calma", tag: "Música", done: false }
        ]
        a[keyOf(new Date(t.getFullYear(), t.getMonth(), t.getDate() + 2))] = [
            { t: "Probar el panel de red en el portátil", tag: "Pendiente", done: false }
        ]
        a[keyOf(new Date(t.getFullYear(), t.getMonth(), t.getDate() + 5))] = [
            { t: "Subir la agenda al repositorio", tag: "Pendiente", done: false },
            { t: "Releer a Dumas", tag: "Lectura", done: false }
        ]
        agenda = a
    }

    onVisibleChanged: {
        if (visible)
            goToday()
    }

    implicitWidth: 664
    implicitHeight: 410
    color: "transparent"

    Rectangle {
        id: cover
        anchors.fill: parent
        radius: Theme.radius
        color: "#2a1810"
        border.color: Theme.line
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: Theme.radius - 4
            color: "transparent"
            border.color: "#7a5a1f"
            border.width: 1
            opacity: 0.7
        }

        Rectangle {
            id: leftPage
            x: 12
            y: 12
            width: 310
            height: 386
            radius: 6
            color: "#eadcbc"

            Item {
                x: 18
                y: 14
                width: 274
                height: 58

                Item {
                    x: 0
                    y: 6
                    width: 24
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: "\uf100"
                        color: Theme.fgOnAccent
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(-12)
                    }
                }

                Item {
                    x: 26
                    y: 6
                    width: 24
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: "\uf104"
                        color: Theme.fgOnAccent
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(-1)
                    }
                }

                Item {
                    x: 224
                    y: 6
                    width: 24
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: "\uf105"
                        color: Theme.fgOnAccent
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(1)
                    }
                }

                Item {
                    x: 250
                    y: 6
                    width: 24
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: "\uf101"
                        color: Theme.fgOnAccent
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(12)
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    text: cal.monthNames[cal.shown.getMonth()]
                    color: Theme.fgOnAccent
                    font.family: Theme.fontSerif
                    font.pixelSize: 28
                    font.bold: true
                    font.capitalization: Font.SmallCaps
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 36
                    text: cal.shown.getFullYear()
                    color: "#6b4f39"
                    font.family: Theme.fontSerif
                    font.pixelSize: 15
                    font.italic: true
                }
            }

            Rectangle {
                x: 18
                y: 76
                width: 274
                height: 2
                color: "#8c6d4f"
            }

            Rectangle {
                x: 18
                y: 80
                width: 274
                height: 1
                color: "#8c6d4f"
            }

            Row {
                x: 18
                y: 88

                Repeater {
                    model: cal.dayNames

                    delegate: Item {
                        required property string modelData
                        required property int index

                        width: 39
                        height: 20

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: parent.index === 6 ? "#a8352b" : "#6b4f39"
                            font.family: Theme.fontSerif
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                }
            }

            Grid {
                x: 18
                y: 110
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

                        width: 39
                        height: 34

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 1
                            width: 28
                            height: 28
                            radius: 14
                            color: cell.isSel ? "#99e2b564" : "transparent"
                            border.color: Theme.fgOnAccent
                            border.width: cell.isToday ? 2 : 0
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 4
                            text: cell.valid ? cell.day : ""
                            color: cell.index % 7 === 6 ? "#a8352b" : Theme.fgOnAccent
                            font.family: Theme.fontSerif
                            font.pixelSize: 17
                            font.bold: cell.isToday
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
                                if (cell.valid)
                                    cal.selected = new Date(cal.shown.getFullYear(), cal.shown.getMonth(), cell.day)
                            }
                        }
                    }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 342
                width: 120
                height: 26

                Text {
                    anchors.centerIn: parent
                    text: "Volver a hoy"
                    color: "#8f3a2c"
                    font.family: Theme.fontSerif
                    font.pixelSize: 15
                    font.italic: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: cal.goToday()
                }
            }
        }

        Rectangle {
            id: rightPage
            x: 322
            y: 12
            width: 310
            height: 386
            radius: 6
            color: "#efe4c8"

            Text {
                x: 18
                y: 6
                text: cal.selected.getDate()
                color: Theme.fgOnAccent
                font.family: Theme.fontSerif
                font.pixelSize: 54
                font.bold: true
            }

            Column {
                x: 84
                y: 20

                Text {
                    text: cal.weekdayNames[cal.selected.getDay()]
                    color: "#6b4f39"
                    font.family: Theme.fontSerif
                    font.pixelSize: 22
                    font.italic: true
                }

                Text {
                    text: "de " + cal.monthNames[cal.selected.getMonth()].toLowerCase() + " de " + cal.selected.getFullYear()
                    color: "#6b4f39"
                    font.family: Theme.fontSerif
                    font.pixelSize: 15
                }
            }

            Rectangle {
                x: 18
                y: 76
                width: 274
                height: 2
                color: "#8c6d4f"
            }

            Rectangle {
                x: 18
                y: 80
                width: 274
                height: 1
                color: "#8c6d4f"
            }

            Column {
                x: 18
                y: 92
                width: 274

                Repeater {
                    model: cal.selectedTasks

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index

                        width: 274
                        height: Math.max(34, taskText.implicitHeight + 14)

                        Rectangle {
                            x: 0
                            y: 9
                            width: 16
                            height: 16
                            radius: 3
                            color: row.modelData.done ? "#3a2a1c22" : "transparent"
                            border.color: Theme.fgOnAccent
                            border.width: 1.5

                            Text {
                                anchors.centerIn: parent
                                text: "\uf00c"
                                visible: row.modelData.done
                                color: Theme.fgOnAccent
                                font.family: Theme.fontIcons
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            id: taskText
                            x: 26
                            y: 6
                            width: 274 - 26 - 74
                            text: row.modelData.t
                            wrapMode: Text.WordWrap
                            color: Theme.fgOnAccent
                            opacity: row.modelData.done ? 0.5 : 1
                            font.family: Theme.fontSerif
                            font.pixelSize: 17
                            font.strikeout: row.modelData.done
                        }

                        Rectangle {
                            anchors.right: parent.right
                            y: 9
                            width: tagLabel.implicitWidth + 12
                            height: 17
                            radius: 8
                            color: cal.tagColor(row.modelData.tag)

                            Text {
                                id: tagLabel
                                anchors.centerIn: parent
                                text: row.modelData.tag
                                color: "#f6ebcf"
                                font.family: Theme.fontUi
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: "#c9b78f"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: cal.toggle(row.index)
                        }
                    }
                }
            }

            Text {
                x: 18
                y: 100
                visible: cal.selectedTasks.length === 0
                text: "Nada apuntado para este día."
                color: "#8c6d4f"
                font.family: Theme.fontSerif
                font.pixelSize: 17
                font.italic: true
            }

            Text {
                x: 18
                y: 336
                text: "+ Añadir una nota o una tarea…"
                color: "#8c6d4f"
                font.family: Theme.fontSerif
                font.pixelSize: 16
                font.italic: true
            }

            Text {
                x: 18
                y: 362
                text: "Tareas de ejemplo: aún no se guardan"
                color: "#a08d68"
                font.family: Theme.fontUi
                font.pixelSize: 9
            }
        }

        Rectangle {
            x: 316
            y: 12
            width: 12
            height: 386
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.5; color: "#55000000" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
        }

        Rectangle {
            x: 584
            y: 12
            width: 14
            height: 86
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#8a2f26" }
                GradientStop { position: 0.5; color: "#b8493c" }
                GradientStop { position: 1.0; color: "#8a2f26" }
            }
        }

        Rectangle {
            x: 586
            y: 93
            width: 10
            height: 10
            rotation: 45
            color: "#efe4c8"
        }

        Repeater {
            model: cal.tags

            delegate: Rectangle {
                required property var modelData
                required property int index

                x: cover.width - 28
                y: 60 + index * 92
                width: 26
                height: 84
                radius: 6
                color: modelData.c
                border.color: "#44000000"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    rotation: 90
                    text: modelData.n
                    color: "#f6ebcf"
                    font.family: Theme.fontUi
                    font.pixelSize: 10
                    font.bold: true
                }
            }
        }
    }
}
