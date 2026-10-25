import Quickshell
import QtQuick
import Quickshell.Hyprland

PanelWindow {
	anchors {
		top: true
		left: true
		right: true
	}
	implicitHeight: 25
	color: "#1e1e2e"
	
	SystemClock {
		id: clock
		precision: SystemClock.Seconds
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
}
