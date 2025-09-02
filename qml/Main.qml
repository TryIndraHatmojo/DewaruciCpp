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

            // Footer with action buttons
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    // Material actions
                    Text {
                        text: "Materials:"
                        font.bold: true
                        color: "#2196F3"
                    }

                    Button {
                        text: "Add Material"
                        onClicked: {
                            // Sample data untuk testing - bisa diganti dengan dialog input
                            if (materialModel) {
                                var success = materialModel.addMaterial(
                                    210000000, // E-Modulus
                                    80000000,  // G-Modulus  
                                    7850,      // Density
                                    250,       // Yield Stress
                                    420,       // Tensile Strength
                                    "Test Material" // Remark
                                )
                                if (success) {
                                    console.log("Material added successfully")
                                    materialTable.refreshData()
                                } else {
                                    console.log("Failed to add material:", materialModel.getLastError())
                                }
                            } else {
                                console.log("Material model not available")
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 30
                        color: "#cccccc"
                    }

                    // Profile actions
                    Text {
                        text: "Profiles:"
                        font.bold: true
                        color: "#2196F3"
                    }

                    Button {
                        text: "Load Sample Profiles"
                        onClicked: {
                            if (profileController) {
                                profileController.loadSampleData()
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Save All Changes"
                        highlighted: true
                        onClicked: {
                            if (materialModel) {
                                console.log("Material model is available")
                                materialTable.refreshData()
                            } else {
                                console.log("Material model not available")
                            }
                            if (profileController) {
                                profileTable.refreshData()
                            }
                        }
                    }
                }
            }
        }
    }
}
