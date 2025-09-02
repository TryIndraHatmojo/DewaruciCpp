import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: profileTableRoot
    color: "white"
    border.color: "#cccccc"
    border.width: 1
    radius: 8

    property alias rehBrackets: rehBracketsInput.text
    property alias rehProfiles: rehProfilesInput.text

    function refreshData() {
        if (profileController) {
            profileController.refreshProfiles()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header
        Text {
            text: "Profile Table"
            font.pixelSize: 18
            font.bold: true
            color: "#2196F3"
        }

        // REH Input Section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#f5f5f5"
            border.color: "#cccccc"
            border.width: 1
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 20

                Text {
                    text: "REH [N/mm**2] for Brackets"
                    font.pixelSize: 12
                }

                TextField {
                    id: rehBracketsInput
                    Layout.preferredWidth: 80
                    text: "235"
                    validator: DoubleValidator { bottom: 0; top: 999999 }
                    selectByMouse: true
                }

                Text {
                    text: "REH for Profiles"
                    font.pixelSize: 12
                }

                TextField {
                    id: rehProfilesInput
                    Layout.preferredWidth: 80
                    text: "235"
                    validator: DoubleValidator { bottom: 0; top: 999999 }
                    selectByMouse: true
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Load More Data"
                    onClicked: {
                        if (profileController) {
                            profileController.loadSampleData()
                        }
                    }
                }
            }
        }

        // Table Section
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            border.color: "#cccccc"
            border.width: 1

            ScrollView {
                anchors.fill: parent
                clip: true

                ListView {
                    id: profileListView
                    model: profileController ? profileController.profiles : []
                    
                    header: Rectangle {
                        width: profileListView.width
                        height: 80
                        color: "#1e4a6b"

                        // Header Row 1 - Main categories
                        Row {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            height: 40

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Type"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 120
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Name"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 400
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Profiles"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 400
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Brackets"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Action"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Header Row 2 - Sub columns
                        Row {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            height: 40

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                            }

                            Rectangle {
                                width: 120
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                            }

                            // Profiles sub-headers
                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "hw\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "tw\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "bf\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "tf\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Area\n[cm**2]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            // Brackets sub-headers
                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "e\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "W\n[cm**3]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "I\n[cm**4]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "l\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "tb\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "bf\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "tbf\n[mm]"
                                    color: "white"
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 40
                                color: "#1e4a6b"
                                border.color: "white"
                                border.width: 1
                            }
                        }
                    }

                    delegate: Rectangle {
                        width: profileListView.width
                        height: 35
                        color: index % 2 === 0 ? "white" : "#f8f8f8"
                        border.color: "#e0e0e0"
                        border.width: 1

                        Row {
                            anchors.fill: parent

                            // Type dropdown
                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1

                                ComboBox {
                                    anchors.centerIn: parent
                                    width: 70
                                    height: 25
                                    model: ["Bar", "Angle", "T-Bar", "Channel"]
                                    currentIndex: {
                                        var type = modelData.type || "Bar"
                                        return model.indexOf(type)
                                    }
                                    onCurrentTextChanged: {
                                        if (profileController && modelData.id) {
                                            // Update profile type
                                        }
                                    }
                                    font.pixelSize: 10
                                }
                            }

                            // Name
                            Rectangle {
                                width: 120
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name || ""
                                    font.pixelSize: 11
                                }
                            }

                            // Profiles section
                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.hw || 0).toFixed(1)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.tw || 0).toFixed(1)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.bfProfiles || 0).toFixed(1)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.tf || 0).toFixed(1)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.area || 0).toFixed(2)
                                    font.pixelSize: 11
                                }
                            }

                            // Brackets section
                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.e || 0).toFixed(2)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.w || 0).toFixed(2)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.upperI || 0).toFixed(2)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.lowerL || 0).toFixed(0)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.tb || 0).toFixed(1)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.bfBrackets || 0).toFixed(0)
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.tbf || 0).toFixed(1)
                                    font.pixelSize: 11
                                }
                            }

                            // Action - Delete button
                            Rectangle {
                                width: 80
                                height: 35
                                border.color: "#e0e0e0"
                                border.width: 1

                                Button {
                                    anchors.centerIn: parent
                                    width: 60
                                    height: 25
                                    text: "Delete"
                                    font.pixelSize: 10
                                    background: Rectangle {
                                        color: parent.pressed ? "#d32f2f" : "#f44336"
                                        radius: 3
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: parent.font.pixelSize
                                    }
                                    onClicked: {
                                        if (profileController && modelData.id) {
                                            profileController.deleteProfile(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Footer with profile count and controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#f5f5f5"
            border.color: "#cccccc"
            border.width: 1
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Text {
                    text: "Total Profiles: " + (profileController ? profileController.getProfileCount() : 0)
                    font.pixelSize: 12
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Add Profile"
                    onClicked: {
                        // Add sample profile for testing
                        if (profileController) {
                            profileController.createProfile(
                                "Bar",           // type
                                "Bar Test",      // name
                                400.0,           // hw
                                26.0,            // tw
                                85.0,            // bfProfiles
                                14.7,            // tf
                                104.0,           // area
                                200.0,           // e
                                1359.29,         // w
                                48096.0,         // upperI
                                512.0,           // lowerL
                                14.7,            // tb
                                85.0,            // bfBrackets
                                14.7             // tbf
                            )
                        }
                    }
                }

                Button {
                    text: "Clear All"
                    onClicked: {
                        if (profileController) {
                            profileController.clearAllProfiles()
                        }
                    }
                }

                Button {
                    text: "Refresh"
                    onClicked: refreshData()
                }
            }
        }
    }

    // Loading indicator
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.3
        visible: profileController ? profileController.isLoading : false

        BusyIndicator {
            anchors.centerIn: parent
            running: profileController ? profileController.isLoading : false
        }
    }

    // Connections to handle profile controller signals
    Connections {
        target: profileController
        function onOperationCompleted(success, message) {
            console.log("Profile operation:", success ? "Success" : "Failed", "-", message)
        }
    }

    Component.onCompleted: {
        if (profileController) {
            profileController.refreshProfiles()
        }
    }
}
