import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import DewaruciCpp 1.0

// Reusable Frame Y Z Graph component extracted from FrameArrangement.qml
Rectangle {
	id: yzFrameRoot
	color: "#ffffff"
	border.color: "#cccccc"
	border.width: 1
	radius: 8

	// Caption for clicked line info
	property string infoText: ""
	// For cycling overlapping hits at the same click point
	property real _lastClickX: -1
	property real _lastClickY: -1
	property int _candidateIndex: 0

	// Public API (can be wired later)
	property int displayedFrameNo: -1
	property alias graphArea: graphAreaRect
	signal helpRequested()

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 15
		spacing: 10

		Text {
			text: "Frame Y Z"
			font.pixelSize: 14
			font.bold: true
			color: "#34495e"
		}

		// Frame number display line
		RowLayout {
			spacing: 6
			Text {
				text: "Frame No.      :"
				font.pixelSize: 12
				color: "#6c757d"
			}
			Text {
				text: displayedFrameNo >= 0 ? displayedFrameNo : "-"
				font.pixelSize: 12
				color: "#2c3e50"
			}
			Item { Layout.fillWidth: true }
			Rectangle {
				width: 20; height: 20; radius: 10; color: "#3498db"
				Text { anchors.centerIn: parent; text: "?"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
				MouseArea { anchors.fill: parent; onClicked: yzFrameRoot.helpRequested() }
			}
		}

		// Area gambar: komponen C++ QQuickPaintedItem
		FrameArrangementYZFrameController {
			id: graphAreaRect
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			gridSpacing: 20
			currentFrameNo: displayedFrameNo
			frameController: frameYZController
			greenLineColor: "#00ff00"
			// Zoom & Pan state
			scaleFactor: 1.0
			panX: 0
			panY: 0

			// Tombol kecil overlay pojok untuk regenerate data drawing
			/*
			Button {
				id: regenBtn
				text: "Gen"
				anchors.top: parent.top
				anchors.right: parent.right
				anchors.margins: 4
				font.pixelSize: 10
				onClicked: graphAreaRect.regenerateDrawingData()
				ToolTip.visible: hovered
				ToolTip.text: "Regenerasi data drawing (reset + insert)"
			}
			*/
			// Auto-refresh when frame number changes
			onCurrentFrameNoChanged: {
				if (frameController) {
					// Load fresh data when frame changes
					Qt.callLater(function() {
						graphAreaRect.regenerateDrawingData()
					})
				}
			}

			// Refresh display when frame controller is set
			onFrameControllerChanged: {
				if (frameController && currentFrameNo >= 0) {
					Qt.callLater(function() {
						graphAreaRect.regenerateDrawingData()
					})
				}
			}

			// Zoom with mouse wheel (focus on cursor)
			WheelHandler {
				id: wheel
				acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
				target: graphAreaRect
				onWheel: function(event) {
					// Always accept so parents don't steal the event
					event.accepted = true
					const step = event.angleDelta.y > 0 ? 1.1 : 0.9
					const oldScale = graphAreaRect.scaleFactor
					let newScale = oldScale * step
					// Clamp in QML too to keep UX consistent
					newScale = Math.max(0.2, Math.min(5.0, newScale))

					// Zoom about cursor: adjust pan so that the point under cursor stays put
					const cx = graphAreaRect.width / 2
					const cy = graphAreaRect.height / 2
					const mouseX = event.x
					const mouseY = event.y
					// Current transform is: translate(pan) -> translate(center) -> scale -> translate(-center)
					// To keep mouse anchor stable, derive delta pan
					const dx = (mouseX - cx)
					const dy = (mouseY - cy)
					const scaleDelta = newScale / oldScale
					// New pan should satisfy: (pan' + cx + dx*newScale - cx) close to (pan + cx + dx*oldScale - cx)
					graphAreaRect.panX = graphAreaRect.panX - dx * (scaleDelta - 1)
					graphAreaRect.panY = graphAreaRect.panY - dy * (scaleDelta - 1)
					graphAreaRect.scaleFactor = newScale
				}
			}

			// Drag to pan (left button only); keep arrow cursor
			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.ArrowCursor
				drag.target: null
				acceptedButtons: Qt.LeftButton
				hoverEnabled: true
				property real lastX: 0
				property real lastY: 0
				property bool moved: false
				onPressed: function(mouse) {
					if (mouse.button !== Qt.LeftButton) return
					lastX = mouse.x
					lastY = mouse.y
					moved = false
				}
				onPositionChanged: function(mouse) {
					if (mouse.buttons & Qt.LeftButton) {
						graphAreaRect.panX += (mouse.x - lastX)
						graphAreaRect.panY += (mouse.y - lastY)
						if (Math.abs(mouse.x - lastX) > 1 || Math.abs(mouse.y - lastY) > 1) moved = true
						lastX = mouse.x
						lastY = mouse.y
					}
				}
				onReleased: function(mouse) {
					if (!moved) {
						// Treat as click: hit test
						const tol = 6
						const res = graphAreaRect.hitTestAt(mouse.x, mouse.y, tol)
						if (res && res.success) {
							// If clicking close to previous point, cycle through candidates
							const sameSpot = Math.abs(mouse.x - yzFrameRoot._lastClickX) < tol && Math.abs(mouse.y - yzFrameRoot._lastClickY) < tol
							let textToShow = res.text
							if (res.candidates && res.candidates.length > 0) {
								if (sameSpot) {
									yzFrameRoot._candidateIndex = (yzFrameRoot._candidateIndex + 1) % res.candidates.length
								} else {
									yzFrameRoot._candidateIndex = 0
								}
								const c = res.candidates[yzFrameRoot._candidateIndex]
								if (c.horizontal) {
									textToShow = "Line L" + c.index + " coordinate Y: ~ Z: " + c.valueMM
								} else {
									textToShow = "Line L" + c.index + " coordinate Y: " + c.valueMM + " Z: ~"
								}
							}
							yzFrameRoot.infoText = textToShow
							yzFrameRoot._lastClickX = mouse.x
							yzFrameRoot._lastClickY = mouse.y
						} else {
							yzFrameRoot.infoText = ""
							yzFrameRoot._candidateIndex = 0
							yzFrameRoot._lastClickX = -1
							yzFrameRoot._lastClickY = -1
						}
					}
				}
			}
		}

		// Info coordinate banner (shows when a line is clicked)
		Rectangle {
			id: infoBanner
			Layout.fillWidth: true
			visible: yzFrameRoot.infoText && yzFrameRoot.infoText.length > 0
			color: "#2c3e50"            // light blue background
			border.color: "#2c3e50"     // soft blue border
			border.width: 1
			radius: 6
			height: implicitHeight
			implicitHeight: infoRow.implicitHeight + 10
			RowLayout {
				id: infoRow
				anchors.fill: parent
				anchors.leftMargin: 8
				spacing: 8
				// Info badge
				// Rectangle {
				// 	width: 18; height: 18; radius: 9
				// 	color: "#4aa3df"
				// 	Text { anchors.centerIn: parent; text: "i"; color: "white"; font.pixelSize: 12; font.bold: true }
				// }
				Text {
					text: yzFrameRoot.infoText
					Layout.fillWidth: true
					wrapMode: Text.WordWrap
					font.pixelSize: 12
					color: "#ddd"
					font.bold: true
				}
				ToolButton {
					text: "✕"
					font.pixelSize: 12
					onClicked: yzFrameRoot.infoText = ""
				}
			}
		}

		// Usage hints (static card)
		Rectangle {
			Layout.fillWidth: true
			color: "#f8f9fa"
			border.color: "#e0e0e0"
			border.width: 1
			radius: 6
			height: implicitHeight
			implicitHeight: usageCol.implicitHeight + 10
			ColumnLayout {
				id: usageCol
				anchors.fill: parent
				anchors.margins: 8
				spacing: 4
				Text { text: "Tips"; font.bold: true; font.pixelSize: 12; color: "#2c3e50" }
				Text { text: "• Mouse Wheel: Zoom in/out"; font.pixelSize: 11; color: "#6c757d" }
				Text { text: "• Hold Left Button + Drag: Pan"; font.pixelSize: 11; color: "#6c757d" }
				Text { text: "• Click a line to see its coordinates"; font.pixelSize: 11; color: "#6c757d" }
			}
		}

		// Try to auto-connect to sibling YZInput if available in parent scope
		Connections {
			// Expect a sibling or parent exposing `dataChanged()`; adjust target in parent integration
			target: typeof yzInput !== 'undefined' ? yzInput : null
			function onDataChanged() {
				graphAreaRect.regenerateDrawingData()
			}
		}
	}
}
