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
	implicitHeight: 25
	color: "#1e1e2e"
	
	//ESTADO DE LA RED ACTUALIZADO POR NET.SH
	property string netType: "none"
	property string netDev: ""
	property string netIp: ""

	
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
	
	Timer {
		interval: 5000
		running: true
		repeat: true
		onTriggered: netProc.running = true
	}

	Rectangle {
		id: wsBox
		readonly property int cell: 24
		readonly property int gap: 5
		readonly property int slots: 10
		readonly property int pad: 6
		
		anchors.left: parent.left
		anchors.leftMargin: 8
		anchors.verticalCenter: parent.verticalCenter
		width: slots * cell + (slots -1) * gap + 2 * pad
		height: 23
		radius: 7
		color: "#181825"
	
		Row {
			anchors.left:parent.left
			anchors.leftMargin:8
			anchors.verticalCenter: parent.verticalCenter
			spacing: 5
		

			Repeater {
				model : Hyprland.workspaces

				Rectangle {
					width: 24
					height: 19
					radius: 5
					color: modelData.focused ? "#89b4fa" : "#313244"	
				

				Text {
					anchors.centerIn: parent
					text: modelData.id
					color: modelData.focused ? "#1e1e2e" : "#cdd6f4"
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
		color: "#cdd6f4"
		font.pixelSize: 15
		text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm:ss")
	}
	
	Rectangle {
		id: netChip
		anchors.right: parent.right
		anchors.rightMargin: 8
		anchors.verticalCenter: parent.verticalCenter
		width: netText.implicitWidth + 16
		height: 19
		radius: 5
		color: root.netType === "none" ? "#45475a" : "#313244"
	
		Text {
			id: netText
			anchors.centerIn: parent
			color: "#cdd6f4"
			font.pixelSize: 12
			text: root.netType === "none"
				? "Sin red"
				: (root.netType === "ethernet" ? "Cable" : "Wi-Fi") + " . " + root.netIp.split("/")[0]
		}
	}

}
