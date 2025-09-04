import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components/section0"

ApplicationWindow {
    id: mainWindow
    width: 1400
    height: 1000
    visible: true
    title: qsTr("Dewaruci - Linear Isotropic Materials & Profile Table")

    Rectangle {
        anchors.fill: parent
        color: "#f0f0f0"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Top panel - Linear Isotropic Materials
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: parent.height * 0.4
                spacing: 10

                LinearIsotropicMaterials {
                    id: materialTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            // Bottom panel - Profile Table
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: parent.height * 0.6
                spacing: 10

                ProfileTable {
                    id: profileTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
