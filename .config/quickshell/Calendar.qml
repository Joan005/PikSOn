import Quickshell
import QtQuick

PopupWindow {
    id: cal

    property date shown: new Date()
    property date today: new Date()
    readonly property var monthNames: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    readonly property var dayNames: ["L", "M", "X", "J", "V", "S", "D"]
    readonly property int firstOffset: (new Date(shown.getFullYear(), shown.getMonth(), 1).getDay() + 6) % 7
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()

    function shift(n) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + n, 1)
    }

    onVisibleChanged: {
        if (visible) {
            today = new Date()
            shown = new Date()
        }
    }

    implicitWidth: 232
    implicitHeight: content.implicitHeight + 20
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#f2313244"
        border.color: "#45475a"
        border.width: 1

        Column {
            id: content
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 6

            Row {
                Item {
                    width: 28
                    height: 26

                    Text {
                        anchors.centerIn: parent
                        text: "\uf100"
                        color: "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(-12)
                    }
                }

                Item {
                    width: 28
                    height: 26

                    Text {
                        anchors.centerIn: parent
                        text: "\uf104"
                        color: "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(-1)
                    }
                }

                Item {
                    width: 100
                    height: 26

                    Text {
                        anchors.centerIn: parent
                        text: cal.monthNames[cal.shown.getMonth()] + " " + cal.shown.getFullYear()
                        color: "#cdd6f4"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shown = new Date()
                    }
                }

                Item {
                    width: 28
                    height: 26

                    Text {
                        anchors.centerIn: parent
                        text: "\uf105"
                        color: "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(1)
                    }
                }

                Item {
                    width: 28
                    height: 26

                    Text {
                        anchors.centerIn: parent
                        text: "\uf101"
                        color: "#cdd6f4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cal.shift(12)
                    }
                }
            }

            Row {
                Repeater {
                    model: cal.dayNames

                    delegate: Item {
                        required property string modelData

                        width: 30
                        height: 20

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: "#a6adc8"
                            font.pixelSize: 11
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

                        width: 30
                        height: 26

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: 6
                            color: cell.isToday ? "#89b4fa" : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cell.valid ? cell.day : ""
                            color: cell.isToday ? "#1e1e2e" : "#cdd6f4"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
