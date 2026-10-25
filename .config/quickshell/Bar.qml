import Quickshell
import QtQuick

PanelWindow {
	anchors {
		top: true
		left: true
		right: true
	}
	implicitHeight: 30
	color: "#1e1e2e"
	
	SystemClock {
		id: clock
		precision: SystemClock.Seconds
	}

	Text {
		anchors.centerIn: parent
		color: "#cdd6f4"
		font.pixelSize: 15
		text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm:ss")
	}
}
