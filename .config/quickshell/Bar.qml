import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
	id: root
	anchors {
		top: true
		left: true
		right: true
	}
	implicitHeight: 40
	color: "transparent"
	
	//ESTADO DE LA RED ACTUALIZADO POR NET.SH
	property string netType: "none"
	property string netDev: ""
	property string netIp: ""

	//DETALLE PAR AEL PANEL (NET.SH)
	
	property bool calOpen: false
	property bool netOpen: false
	property var info: ({})

	//VOLUMEN SIN DATOS
	property int volPercent: -1
	property bool volMuted: false

	onNetOpenChanged: {
		if (netOpen)
			infoProc.running = true
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
	command : ["sh", "-c", "$HOME/.config/quickshell/scripts/netinfo.sh"]
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
				if (t.indexOf("Volume:") !==0) {
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
		onTriggered: infoProc.running = true		
}

	Timer {
		id: volRefresh
		interval: 200
		onTriggered: volProc.running = true

}
	
	Player {
		id: playerChip
		anchors.left: wsBox.right
		anchors.leftMargin: 8
		anchors.verticalCenter: wsBox.verticalCenter
	}

	PlayerPanel {
		anchor.window: root
		anchor.rect.x: playerChip.x
		anchor.rect.y: root.height + 4
		visible: playerChip.opened && playerChip.player !== null
		player: playerChip.player
		}

	Rectangle {
		id: wsBox
		readonly property int cell: 24
		readonly property int gap: 5
		readonly property int slots: 5
		readonly property int pad: 6
		
		anchors.left: parent.left
		anchors.leftMargin: 8
		anchors.verticalCenter: parent.verticalCenter
		width: slots * cell + (slots -1) * gap + 2 * pad
		height: 32
		radius: Theme.radius
		color: Theme.bgChip
		border.color: Theme.line
		border.width: 1

		Rectangle {
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 3
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.leftMargin: 5
			anchors.rightMargin: 5
			height: 2
			radius: 1
			color: Theme.wood
			}		

		Row {
			anchors.left:parent.left
			anchors.leftMargin:8
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 5
			spacing: 5
		

			Repeater {
				model : Hyprland.workspaces

		Item {
			width: 24
			height: 25

			Rectangle {
				anchors.bottom: parent.bottom
				anchors.horizontalCenter: parent.horizontalCenter
				width: 22
				height: modelData.focused ? 25 : 20
				radius: 3
				color: Theme.spines[((modelData.id - 1) % 5 + 5) % 5]
				border.color: modelData.focused ? Theme.accent : Theme.line
				border.width: 1

				Behavior on height { NumberAnimation { duration: 120 } }

		Rectangle {
			anchors.top: parent.top
			anchors.topMargin: 2
			width: parent.width
			height: 1
			color: Theme.accent
			opacity: 0.7
		}

			Rectangle {
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 2
			width: parent.width
			height: 1
			color: Theme.accent
			opacity: 0.7
		}

		Text {
	anchors.centerIn: parent
	text: ["I", "II", "III", "IV", "V"][((modelData.id - 1) % 5 + 5) % 5]
	color: Theme.fg
	font.family: Theme.fontSerif
	font.pixelSize: 11
	font.bold: modelData.focused
		}
	}

			MouseArea {
				anchors.fill: parent
				onClicked: modelData.activate()
				}
			}
		}
	}	
}

	Text {
		anchors.centerIn: parent
		color: Theme.fg
		font.pixelSize: 15
		text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm:ss")
	
	
		MouseArea {
		anchors.fill: parent
		onClicked: root.calOpen = !root.calOpen
		}
	}
	Calendar {
	anchor.window: root
	anchor.rect.x: (root.width - implicitWidth) / 2
	anchor.rect.y: root.height + 4
	visible: root.calOpen
	}
	
	Rectangle {
		id: netChip
		anchors.right: parent.right
		anchors.rightMargin: 8
		anchors.verticalCenter: parent.verticalCenter
		width: netText.implicitWidth + 16
		height: 32
		radius: Theme.radius
		color: root.netType === "none" ? Theme.bgCell : Theme.bgChip
	
		Text {
			id: netText
			anchors.centerIn: parent
			color: Theme.fg
			font.pixelSize: 12
			text: root.netType === "none"
				? "Sin red"
				: (root.netType === "ethernet" ? "Cable" : "Wi-Fi") + " . " + root.netIp.split("/")[0]
		}
	
		MouseArea {
			anchors.fill: parent
			onClicked: root.netOpen = !root.netOpen
		}
	}
	
	Rectangle {
		id: volChip
		anchors.right: netChip.left
		anchors.rightMargin: 6
		anchors.verticalCenter: parent.verticalCenter
		width: volText.implicitWidth + 16
		height: 32
		radius: Theme.radius
		color: (root.volMuted || root.volPercent < 0) ? Theme.bgCell : Theme.bgChip

		Text {
			id: volText
			anchors.centerIn: parent
			color: Theme.fg
			font.pixelSize: 12
			text: root.volPercent < 0
				? "Vol --"
				: (root.volMuted ? "Vol mute" : "Vol " + root.volPercent + "%")
		} 

		MouseArea {
			anchors.fill: parent
			onClicked: {
				Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
				volRefresh.restart()
			}
			onWheel: (wheel) => {
				var paso = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
				Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", paso])
				volRefresh.restart()
			}
		}
	}


		NetPanel {
		id: netPanel
		anchor.window: root
		anchor.rect.x: root.width - implicitWidth - 8
		anchor.rect.y: root.height + 4
		visible: root.netOpen
		info: root.info
		}
}
		








