import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import QtQuick

PanelWindow {
	id: root

	anchors {
		top: true
		right: true
		bottom: true
	}
	implicitWidth: 34
	color: "transparent"
	visible: SystemTray.items.values.length > 0
	mask: Region { item: box }
	
	Rectangle {
		id: box
		anchors.right: parent.right
		anchors.rightMargin: 4
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 8
		width: 30
		height: col.implicitHeight + 12
		radius: 8
		color: "#cc313244"

		Column {
			id: col
			anchors.centerIn: parent
			spacing: 6		

		Repeater {
			model: SystemTray.items
			
			delegate: MouseArea {
				id: trayItem
				required property var modelData

				width: 20
				height: 20
				acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			
				onClicked: mouse => {
					if (mouse.button === Qt.LeftButton && !modelData.onlyMenu){
						modelData.activate()
					} else if (mouse.button === Qt.MiddleButton) {
						modelData.secondaryActivate()
					} else {
						console.log("TRAY menu: hasMenu=" + modelData.hasMenu + " entradas=" + opener.children.values.length)
						popup.visible = !popup.visible
					}
				}
				
				IconImage {
					anchors.fill: parent
					source: trayItem.modelData.icon
				}
			
				QsMenuOpener {
					id: opener
					menu: trayItem.modelData.menu
				}
				HyprlandFocusGrab {
					windows: [popup]
					active: popup.visible
					onCleared: popup.visible = false
				}
				
				PopupWindow {
					id: popup
					visible: false
					anchor.window: root	
					anchor.rect.x: box.x
					anchor.rect.y: box.y + col.y + trayItem.y
					anchor.rect.width: box.width
					anchor.rect.height: trayItem.height
					anchor.edges: Edges.Left
					anchor.gravity: Edges.Left
					implicitWidth: 190
					implicitHeight: menuCol.implicitHeight + 12
					color: "transparent"
				
				Rectangle {
					anchors.fill: parent
					radius: 8
					color: "#f2313244"
					border.color: "#45475a"
					border.width: 1
				
				Column {
					id: menuCol
					anchors.fill: parent
					anchors.margins: 6
					spacing: 2
				
					Repeater {
						model: [ { "text": "Cerrar", "isSeparator": false, "enabled": true} ]

						delegate: Rectangle {
							id: entry
							required property var modelData

							width: menuCol.width
							height: modelData.isSeparator ? 5: 26
							radius: 5
							color: (!modelData.isSeparator && entryMouse.containsMouse) ? "#45475a" : "transparent"

						Rectangle {
							visible: entry.modelData.isSeparator
							anchors.centerIn: parent
							width: parent.width - 8
							height: 1
							color: "#585b70"
						}
						
						Text {
							visible: !entry.modelData.isSeparator
							anchors.verticalCenter: parent.verticalCenter
							anchors.left: parent.left
							anchors.leftMargin: 8
							text: entry.modelData.text
							color: entry.modelData.enabled ? "#cdd6f4" : "#6c7086"
							font.pixelSize: 12
						}
							
						MouseArea {
							id: entryMouse
							anchors.fill: parent
							hoverEnabled: true
							enabled: !entry.modelData.isSeparator && entry.modelData.enabled
							onClicked: {
								Quickshell.execDetached(["sh", "-c", "$HOME/.config/quickshell/scripts/trayquit.sh \"$0\"", trayItem.modelData.id])
								popup.visible = false
							}
						}
					}
				}
			}
		}					
	}
}	
}
}
}
}

		
