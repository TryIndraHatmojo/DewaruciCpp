import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: pageRoot
    anchors.fill: parent
    color: "#f0f0f0"

    // Expose properties to allow parent to control sizing if needed
    property alias materialTable: materialTable
    property alias profileTable: profileTable

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
