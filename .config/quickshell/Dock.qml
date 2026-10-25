import Quickshell
import QtQuick

PanelWindow {
	anchors {
		top: true
		bottom: true
		right: true
	}
	margins {
		top: 30
	}
	implicitWidth: 60
	color: "#1e1e2e"

	Column {
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.verticalCenter: parent.verticalCenter
		spacing: 10

		Repeater {
			model: [
				{label: "Br", cmd: ["brave"]},
				{label: "Dc", cmd: ["discord"]}
	]

			Rectangle {
				width: 40
				height: 40
				radius: 10
				color : area.containsMouse ? "#89b4fa" : "#313244"
			
			Text {
				anchors.centerIn: parent
				text: modelData.label
				color: area.containsMouse ? "#1e1e2e" : "#cdd6f4"
				font.pixelSize: 15
				font.bold : true
			}
		
			MouseArea {
				id: area
				anchors.fill: parent
				hoverEnabled: true
				onClicked: Quickshell.execDetached(modelData.cmd)
			}	
		}
	}
}
}

		
