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

			// Tombol kecil overlay pojok untuk regenerate data drawing
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
		}
	}
}
