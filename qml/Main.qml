import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components/section0"

ApplicationWindow {
    id: mainWindow
    width: 1200
    height: 800
    visible: true
    title: qsTr("Dewaruci - Linear Isotropic Materials")

    Rectangle {
        anchors.fill: parent
        color: "#f0f0f0"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#2196F3"
                radius: 8

                Text {
                    anchors.centerIn: parent
                    text: "Material Properties Management"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                }
            }

            // Table component
            LinearIsotropicMaterials {
                id: materialTable
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Footer with action buttons
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    Button {
                        text: "Add New Material"
                        onClicked: {
                            // Sample data untuk testing - bisa diganti dengan dialog input
                            if (materialDatabase && materialDatabase.isDBConnected()) {
                                var success = materialDatabase.addMaterial(
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
                                    console.log("Failed to add material:", materialDatabase.getLastError())
                                }
                            } else {
                                console.log("Database not connected")
                            }
                        }
                    }

                    Button {
                        text: "Import Data"
                        onClicked: {
                            console.log("Import data clicked")
                        }
                    }

                    Button {
                        text: "Export Data"
                        onClicked: {
                            console.log("Export data clicked")
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Save Changes"
                        highlighted: true
                        onClicked: {
                            if (materialDatabase && materialDatabase.isDBConnected()) {
                                console.log("Database is connected and ready")
                                materialTable.refreshData()
                            } else {
                                console.log("Database connection error:", materialDatabase ? materialDatabase.getLastError() : "MaterialDatabase not available")
                            }
                        }
                    }
                }
            }
        }
    }
}
