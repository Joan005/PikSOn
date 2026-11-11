import Quickshell.Services.Mpris
import QtQuick

Rectangle {
	id: chip

	property bool opened: false
	function pickPlayer() {
		var list = Mpris.players.values
		var pick = null
		for (var i = 0; i < list.length; i++) {
			var p = list[i]
			if (p.identity === "Spotify")
				return p
			if (pick === null || (p.isPlaying && !pick.isPlaying))
				pick = p
		}
		return pick
	}
	
	function shortText() {
		if (!chip.player)
			return ""
		var t = chip.player.trackTitle || ""
		var a = chip.player.trackArtist || ""
		var i1 = t.indexOf("(")
		if (i1 > 0)
			t = t.substring(0, i1).trim()
		if (a !== "" && t.indexOf(" - ") < 0)
			return t + " - " + a
		return t
	}

	readonly property var player: pickPlayer()

	visible: player !== null
	height: 32
	width: row.implicitWidth + 20
	radius: Theme.radius
	color: "transparent"

	Row {
		id: row
		anchors.centerIn: parent
		spacing: 4

		Item {
			width: 22
			height: 28
			
			Text {
				anchors.centerIn: parent
				text: "\uf048"
				color: Theme.fg
				font.family: Theme.fontIcons
				font.pixelSize: 12
			}
		
			MouseArea {
				anchors.fill: parent
				onClicked: if (chip.player) chip.player.previous()
			}
		}

		Item {
			width: 22
			height: 28

			Text {
				anchors.centerIn: parent
				text: chip.player && chip.player.isPlaying ? "\uf04c" : "\uf04b"
				color: Theme.fg
				font.family: Theme.fontIcons
				font.pixelSize: 12
			}

			MouseArea {
				anchors.fill: parent
				onClicked: if (chip.player) chip.player.togglePlaying()
			}
		}
		
		Item {
			width: 22
			height: 28

			Text {
				anchors.centerIn: parent
				text: "\uf051"
				color: Theme.fg
				font.family: Theme.fontIcons
				font.pixelSize: 12
			}
		
			MouseArea {
				anchors.fill: parent
				onClicked: if (chip.player) chip.player.next()
			}
		}
	
		Item {
			width: Math.min(label.implicitWidth, 180)
			height: 28

			Text {
				id: label
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width
				elide: Text.ElideRight
				color: Theme.fg
				font.pixelSize: 12
				font.family: Theme.fontUi; text: chip.shortText()
			}
			MouseArea {
				anchors.fill: parent
				onClicked: chip.opened = !chip.opened			
			}
		}
	}
}

		










			



