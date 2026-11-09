import Quickshell.Services.Mpris
import QtQuick

Rectangle {
	id: chip

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
	height: 28
	width: row.implicitWidth + 20
	radius: 8
	color: "#cc313244"

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
				color: "#cdd6f4"
				font.family: "JetBrainsMono Nerd Font"
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
				color: "#cdd6f4"
				font.family: "JetBrainsMono Nerd Font"
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
				color: "#cdd6f4"
				font.family: "JetBrainsMono Nerd Font"
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
				color: "#cdd6f4"
				font.pixelSize: 12
				text: chip.shortText()
			}
		}
	}
}

		










			



