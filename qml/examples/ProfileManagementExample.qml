import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "Structure Profile Management Example"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20

        // Title
        Text {
            text: "Structure Profile Management"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Controls
        RowLayout {
            Layout.fillWidth: true
            
            Button {
                text: "Load Sample Data"
                onClicked: {
                    if (profileController.loadSampleData()) {
                        statusText.text = "Sample data loaded successfully"
                        statusText.color = "green"
                    } else {
                        statusText.text = "Failed to load sample data: " + profileController.lastError
                        statusText.color = "red"
                    }
                }
            }
            
            Button {
                text: "Refresh"
                onClicked: {
                    profileController.refreshProfiles()
                    statusText.text = "Profiles refreshed"
                    statusText.color = "blue"
                }
            }
            
            Button {
                text: "Clear All"
                onClicked: {
                    if (profileController.clearAllProfiles()) {
                        statusText.text = "All profiles cleared"
                        statusText.color = "orange"
                    } else {
                        statusText.text = "Failed to clear profiles: " + profileController.lastError
                        statusText.color = "red"
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: "Count: " + profileController.getProfileCount()
                font.pixelSize: 14
            }
        }

        // Status
        Text {
            id: statusText
            text: "Ready"
            color: "black"
            Layout.fillWidth: true
        }

        // Search
        RowLayout {
            Layout.fillWidth: true
            
            TextField {
                id: searchField
                placeholderText: "Search profiles..."
                Layout.fillWidth: true
                onTextChanged: {
                    if (text.length > 0) {
                        var results = profileController.searchProfiles(text)
                        listView.model = results
                    } else {
                        listView.model = profileController.profiles
                    }
                }
            }
            
            ComboBox {
                id: typeFilter
                model: ["All Types"].concat(profileController.getAvailableTypes())
                onCurrentTextChanged: {
                    if (currentText === "All Types") {
                        listView.model = profileController.profiles
                    } else {
                        var results = profileController.filterProfilesByType(currentText)
                        listView.model = results
                    }
                    searchField.text = ""
                }
            }
        }

        // Profile List
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ListView {
                id: listView
                model: profileController.profiles
                
                delegate: Rectangle {
                    width: listView.width
                    height: 60
                    border.color: "#ddd"
                    border.width: 1
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        Column {
                            Layout.fillWidth: true
                            
                            Text {
                                text: modelData.name || "Unknown"
                                font.bold: true
                                font.pixelSize: 16
                            }
                            
                            Text {
                                text: "Type: " + (modelData.type || "Unknown") + " | HW: " + (modelData.hw || 0) + " | TW: " + (modelData.tw || 0)
                                font.pixelSize: 12
                                color: "#666"
                            }
                        }
                        
                        Button {
                            text: "Delete"
                            onClicked: {
                                if (profileController.deleteProfile(modelData.id)) {
                                    statusText.text = "Profile '" + modelData.name + "' deleted"
                                    statusText.color = "orange"
                                } else {
                                    statusText.text = "Failed to delete profile: " + profileController.lastError
                                    statusText.color = "red"
                                }
                            }
                        }
                    }
                }
            }
        }

        // Add Profile Form
        GroupBox {
            title: "Add New Profile"
            Layout.fillWidth: true
            
            GridLayout {
                columns: 4
                anchors.fill: parent
                
                Text { text: "Type:" }
                TextField {
                    id: typeField
                    placeholderText: "e.g., I-Beam"
                    Layout.fillWidth: true
                }
                
                Text { text: "Name:" }
                TextField {
                    id: nameField
                    placeholderText: "e.g., IPE200"
                    Layout.fillWidth: true
                }
                
                Text { text: "HW:" }
                TextField {
                    id: hwField
                    placeholderText: "200.0"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                    Layout.fillWidth: true
                }
                
                Text { text: "TW:" }
                TextField {
                    id: twField
                    placeholderText: "5.6"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                    Layout.fillWidth: true
                }
                
                Text { text: "BF Profiles:" }
                TextField {
                    id: bfProfilesField
                    placeholderText: "100.0"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                    Layout.fillWidth: true
                }
                
                Text { text: "TF:" }
                TextField {
                    id: tfField
                    placeholderText: "8.5"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                    Layout.fillWidth: true
                }
                
                Text { text: "Area:" }
                TextField {
                    id: areaField
                    placeholderText: "28.5"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                    Layout.fillWidth: true
                }
                
                Text { text: "E:" }
                TextField {
                    id: eField
                    placeholderText: "19.4"
                    validator: DoubleValidator { bottom: 0; decimals: 2 }
                    Layout.fillWidth: true
                }
                
                Button {
                    text: "Add Profile"
                    Layout.columnSpan: 4
                    Layout.fillWidth: true
                    
                    onClicked: {
                        var success = profileController.createProfile(
                            typeField.text,
                            nameField.text,
                            parseFloat(hwField.text) || 0,
                            parseFloat(twField.text) || 0,
                            parseFloat(bfProfilesField.text) || 0,
                            parseFloat(tfField.text) || 0,
                            parseFloat(areaField.text) || 0,
                            parseFloat(eField.text) || 0,
                            0, // w
                            0, // upperI
                            0, // lowerL
                            0, // tb
                            0, // bfBrackets
                            0  // tbf
                        )
                        
                        if (success) {
                            statusText.text = "Profile '" + nameField.text + "' added successfully"
                            statusText.color = "green"
                            // Clear form
                            typeField.text = ""
                            nameField.text = ""
                            hwField.text = ""
                            twField.text = ""
                            bfProfilesField.text = ""
                            tfField.text = ""
                            areaField.text = ""
                            eField.text = ""
                        } else {
                            statusText.text = "Failed to add profile: " + profileController.lastError
                            statusText.color = "red"
                        }
                    }
                }
            }
        }
    }
    
    // Loading indicator
    Rectangle {
        anchors.fill: parent
        color: "#80000000"
        visible: profileController.isLoading
        
        BusyIndicator {
            anchors.centerIn: parent
            running: profileController.isLoading
        }
    }
    
    Connections {
        target: profileController
        
        function onProfilesChanged() {
            // Update the list view if no filter is active
            if (searchField.text.length === 0 && typeFilter.currentText === "All Types") {
                listView.model = profileController.profiles
            }
        }
        
        function onOperationCompleted(success, message) {
            statusText.text = message
            statusText.color = success ? "green" : "red"
        }
    }
}
