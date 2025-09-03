import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: parent ? parent.width - 20 : 1200
    height: parent ? parent.height * 0.8 : 600
    anchors.centerIn: parent
    color: "#f5f5f5"
    border.color: "#2196F3"
    border.width: 2
    radius: 8

    property var tableModel: []
    property alias rehBrackets: rehBracketsInput.text
    property alias rehProfiles: rehProfilesInput.text
    
    // Property untuk menyimpan lebar kolom yang dapat di-resize
    property var columnWidths: [
        root.width * 0.06,  // Type - 6%
        root.width * 0.10,  // Name - 10%
        root.width * 0.06,  // hw - 6%
        root.width * 0.06,  // tw - 6%
        root.width * 0.06,  // bf (Profiles) - 6%
        root.width * 0.06,  // tf - 6%
        root.width * 0.07,  // Area - 7%
        root.width * 0.06,  // e - 6%
        root.width * 0.07,  // W - 7%
        root.width * 0.07,  // I - 7%
        root.width * 0.06,  // l - 6%
        root.width * 0.06,  // tb - 6%
        root.width * 0.06,  // bf (Brackets) - 6%
        root.width * 0.06,  // tbf - 6%
        root.width * 0.05   // Action - 5%
    ]

    // Function untuk refresh data dari database
    function refreshData() {
        if (profileController) {
            profileController.refreshProfiles()
            // Convert profiles to table model
            var profiles = profileController.profiles || []
            var validProfiles = []
            for (var i = 0; i < profiles.length; i++) {
                if (profiles[i] && profiles[i].id !== undefined) {
                    validProfiles.push(profiles[i])
                }
            }
            tableModel = validProfiles
            console.log("Loaded", validProfiles.length, "valid profiles from database")
        } else {
            console.log("Profile controller not available")
            tableModel = []
        }
    }

    // Load data when component is completed
    Component.onCompleted: {
        refreshData()
    }
    
    // Helper function untuk focus + select all
    function focusAndSelect(targetInput) {
        targetInput.forceActiveFocus()
        targetInput.selectAll()
    }

    // Function untuk add profile baru dari shadow row
    function addNewProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf) {
        if (profileController) {
            var success = profileController.createProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf)
            if (success) {
                console.log("New profile added successfully")
                refreshData()
                // Reset shadow row ke nilai default
                resetShadowRow()
            } else {
                console.log("Failed to add profile")
            }
        }
    }

    // Function untuk reset shadow row ke data terakhir
    function resetShadowRow() {
        if (profileController && tableModel.length > 0) {
            var lastProfile = tableModel[tableModel.length - 1]
            shadowRow.resetToLastData(lastProfile)
        }
    }

    // Function untuk delete profile
    function deleteProfile(index, profileId) {
        if (profileController) {
            if (profileController.deleteProfile(profileId)) {
                console.log("Profile deleted successfully")
                refreshData()
            } else {
                console.log("Failed to delete profile")
            }
        }
    }

    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "#2196F3"
        radius: 6
        
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 6
            color: "#2196F3"
        }

        Column {
            anchors.fill: parent
            
            // Title and REH inputs
            RowLayout {
                width: parent.width
                height: 30
                anchors.margins: 10

                Text {
                    text: "Profile Table"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: "REH Brackets:"
                    color: "white"
                    font.pixelSize: 10
                }

                TextField {
                    id: rehBracketsInput
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 20
                    text: "235"
                    validator: DoubleValidator { bottom: 0; top: 999999 }
                    selectByMouse: true
                    font.pixelSize: 10
                }

                Text {
                    text: "REH Profiles:"
                    color: "white"
                    font.pixelSize: 10
                }

                TextField {
                    id: rehProfilesInput
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 20
                    text: "235"
                    validator: DoubleValidator { bottom: 0; top: 999999 }
                    selectByMouse: true
                    font.pixelSize: 10
                }

                Button {
                    text: "Load Data"
                    Layout.preferredHeight: 20
                    font.pixelSize: 9
                    onClicked: {
                        if (profileController) {
                            profileController.loadSampleData()
                        }
                    }
                }
            }

            // Controls row
            RowLayout {
                width: parent.width
                height: 30
                anchors.margins: 10

                Text {
                    text: "Total: " + (tableModel ? tableModel.length : 0)
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                }

                Button {
                    text: "Add Profile"
                    Layout.preferredHeight: 20
                    font.pixelSize: 9
                    onClicked: {
                        if (profileController) {
                            profileController.createProfile(
                                "Bar", "Bar Test", 400.0, 26.0, 85.0, 14.7,
                                104.0, 200.0, 1359.29, 48096.0,
                                512.0, 14.7, 85.0, 14.7
                            )
                        }
                    }
                }

                Button {
                    text: "Clear All"
                    Layout.preferredHeight: 20
                    font.pixelSize: 9
                    onClicked: {
                        if (profileController) {
                            profileController.clearAllProfiles()
                        }
                    }
                }

                Button {
                    text: "Refresh"
                    Layout.preferredHeight: 20
                    font.pixelSize: 9
                    onClicked: refreshData()
                }
            }
        }
    }

    // Table content
    Rectangle {
        id: tableContainer
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        color: "white"

        // Column headers
        Row {
            id: columnHeaders
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 70
            clip: true

            // Header Row 1 - Main categories
            Column {
                width: parent.width
                height: parent.height

                // First row - main categories
                Row {
                    height: 35

                    Rectangle {
                        width: root.columnWidths[0] + root.columnWidths[1] + root.columnWidths[2] + root.columnWidths[3] + root.columnWidths[4] + root.columnWidths[5] + root.columnWidths[6] + root.columnWidths[7] + root.columnWidths[8] + root.columnWidths[9]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Profiles"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[10] + root.columnWidths[11] + root.columnWidths[12] + root.columnWidths[13]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Brackets"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[14]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Action"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                // Second row - sub headers
                Row {
                    height: 35

                    Rectangle {
                        width: root.columnWidths[0]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Type"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[1]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Name"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[2]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "hw\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[3]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "tw\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[4]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "bf\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[5]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "tf\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[6]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Area\n[cm²]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[7]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "e\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[8]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "W\n[cm³]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[9]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "I\n[cm⁴]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[10]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "l\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[11]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "tb\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[12]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "bf\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[13]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "tbf\n[mm]"
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        width: root.columnWidths[14]
                        height: 35
                        color: "#1e4a6b"
                        border.color: "#ddd"
                        border.width: 1
                    }
                }
            }
        }

        // Scrollable table content
        ScrollView {
            id: scrollView
            anchors.top: columnHeaders.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            
            // Hanya scroll vertical
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: scrollView.width
                
                // Data rows
                Repeater {
                    id: profileRepeater
                    model: root.tableModel
                    delegate: Row {
                        property int rowIndex: index
                        property bool isEven: index % 2 === 0
                        property var profileData: modelData || {}
                        width: parent.width
                        clip: true

                        property var originalValues: ({}) // Store original values for comparison
                        
                        function updateProfile() {
                            if (profileController && profileData.id) {
                                // Check if any values have actually changed
                                var hasChanges = false
                                var currentValues = {
                                    type: profileData.type || "",
                                    name: profileData.name || "",
                                    hw: profileData.hw || 0,
                                    tw: profileData.tw || 0,
                                    bfProfiles: profileData.bfProfiles || 0,
                                    tf: profileData.tf || 0,
                                    area: profileData.area || 0,
                                    e: profileData.e || 0,
                                    w: profileData.w || 0,
                                    upperI: profileData.upperI || 0,
                                    lowerL: profileData.lowerL || 0,
                                    tb: profileData.tb || 0,
                                    bfBrackets: profileData.bfBrackets || 0,
                                    tbf: profileData.tbf || 0
                                }
                                
                                // Compare with original values
                                for (var key in currentValues) {
                                    if (originalValues[key] !== currentValues[key]) {
                                        hasChanges = true
                                        break
                                    }
                                }
                                
                                if (hasChanges) {
                                    console.log("Profile values changed, updating database for ID:", profileData.id)
                                    // Call controller update method here when available
                                    // For now, just refresh data
                                    root.refreshData()
                                    // Update original values
                                    originalValues = currentValues
                                } else {
                                    console.log("No changes detected for profile ID:", profileData.id, "- skipping update")
                                }
                            }
                        }
                        
                        // Initialize original values when component is created
                        Component.onCompleted: {
                            originalValues = {
                                type: profileData.type || "",
                                name: profileData.name || "",
                                hw: profileData.hw || 0,
                                tw: profileData.tw || 0,
                                bfProfiles: profileData.bfProfiles || 0,
                                tf: profileData.tf || 0,
                                area: profileData.area || 0,
                                e: profileData.e || 0,
                                w: profileData.w || 0,
                                upperI: profileData.upperI || 0,
                                lowerL: profileData.lowerL || 0,
                                tb: profileData.tb || 0,
                                bfBrackets: profileData.bfBrackets || 0,
                                tbf: profileData.tbf || 0
                            }
                        }

                        // Type - ComboBox
                        Rectangle {
                            width: root.columnWidths[0]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1

                            ComboBox {
                                anchors.centerIn: parent
                                width: parent.width - 4
                                height: 25
                                model: ["HP", "L", "T", "Bar"]
                                currentIndex: {
                                    var type = profileData.type || "Bar"
                                    return model.indexOf(type)
                                }
                                font.pixelSize: 9
                                onCurrentTextChanged: {
                                    if (profileController && profileData.id) {
                                        console.log("Type changed to:", currentText)
                                    }
                                }
                            }
                        }

                        // Name - Editable Text Input
                        Rectangle {
                            width: root.columnWidths[1]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: nameInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.name || ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                
                                KeyNavigation.tab: hwInput
                                KeyNavigation.backtab: tbfInput
                                KeyNavigation.left: nameInput // Stay in same cell (first editable column)
                                KeyNavigation.right: hwInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[1] && prevRow.children[1].children[0]) {
                                            focusAndSelect(prevRow.children[1].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[1] && nextRow.children[1].children[0]) {
                                            focusAndSelect(nextRow.children[1].children[0])
                                        }
                                    } else {
                                        // Go to shadow row
                                        focusAndSelect(shadowNameField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(hwInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.name = text
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // hw - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[2]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: hwInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.hw ? profileData.hw.toFixed(1) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 1 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: twInput
                                KeyNavigation.backtab: nameInput
                                KeyNavigation.left: nameInput
                                KeyNavigation.right: twInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[2] && prevRow.children[2].children[0]) {
                                            focusAndSelect(prevRow.children[2].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[2] && nextRow.children[2].children[0]) {
                                            focusAndSelect(nextRow.children[2].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowHwField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(twInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(nameInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.hw = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // tw - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[3]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: twInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.tw ? profileData.tw.toFixed(1) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 1 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: bfProfilesInput
                                KeyNavigation.backtab: hwInput
                                KeyNavigation.left: hwInput
                                KeyNavigation.right: bfProfilesInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[3] && prevRow.children[3].children[0]) {
                                            focusAndSelect(prevRow.children[3].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[3] && nextRow.children[3].children[0]) {
                                            focusAndSelect(nextRow.children[3].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowTwField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(bfProfilesInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(hwInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.tw = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // bf (Profiles) - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[4]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: bfProfilesInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.bfProfiles ? profileData.bfProfiles.toFixed(1) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 1 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: tfInput
                                KeyNavigation.backtab: twInput
                                KeyNavigation.left: twInput
                                KeyNavigation.right: tfInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[4] && prevRow.children[4].children[0]) {
                                            focusAndSelect(prevRow.children[4].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[4] && nextRow.children[4].children[0]) {
                                            focusAndSelect(nextRow.children[4].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowBfProfilesField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(tfInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(twInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.bfProfiles = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // tf - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[5]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: tfInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.tf ? profileData.tf.toFixed(1) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 1 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: areaInput
                                KeyNavigation.backtab: bfProfilesInput
                                KeyNavigation.left: bfProfilesInput
                                KeyNavigation.right: areaInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[5] && prevRow.children[5].children[0]) {
                                            focusAndSelect(prevRow.children[5].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[5] && nextRow.children[5].children[0]) {
                                            focusAndSelect(nextRow.children[5].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowTfField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(areaInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(bfProfilesInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.tf = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // Area - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[6]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: areaInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.area ? profileData.area.toFixed(2) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 2 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: eInput
                                KeyNavigation.backtab: tfInput
                                KeyNavigation.left: tfInput
                                KeyNavigation.right: eInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[6] && prevRow.children[6].children[0]) {
                                            focusAndSelect(prevRow.children[6].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[6] && nextRow.children[6].children[0]) {
                                            focusAndSelect(nextRow.children[6].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowAreaField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(eInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(tfInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.area = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // e - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[7]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: eInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.e ? profileData.e.toFixed(2) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 2 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: wInput
                                KeyNavigation.backtab: areaInput
                                KeyNavigation.left: areaInput
                                KeyNavigation.right: wInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[7] && prevRow.children[7].children[0]) {
                                            focusAndSelect(prevRow.children[7].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[7] && nextRow.children[7].children[0]) {
                                            focusAndSelect(nextRow.children[7].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowEField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(wInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(areaInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.e = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // W - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[8]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: wInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.w ? profileData.w.toFixed(2) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 2 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: upperIInput
                                KeyNavigation.backtab: eInput
                                KeyNavigation.left: eInput
                                KeyNavigation.right: upperIInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[8] && prevRow.children[8].children[0]) {
                                            focusAndSelect(prevRow.children[8].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[8] && nextRow.children[8].children[0]) {
                                            focusAndSelect(nextRow.children[8].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowWField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(upperIInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(eInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.w = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // I - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[9]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: upperIInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.upperI ? profileData.upperI.toFixed(2) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 2 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: lowerLInput
                                KeyNavigation.backtab: wInput
                                KeyNavigation.left: wInput
                                KeyNavigation.right: lowerLInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[9] && prevRow.children[9].children[0]) {
                                            focusAndSelect(prevRow.children[9].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[9] && nextRow.children[9].children[0]) {
                                            focusAndSelect(nextRow.children[9].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowUpperIField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(lowerLInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(wInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.upperI = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // l (Brackets) - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[10]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: lowerLInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.lowerL ? profileData.lowerL.toFixed(0) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: IntValidator { bottom: 0 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: tbInput
                                KeyNavigation.backtab: upperIInput
                                KeyNavigation.left: upperIInput
                                KeyNavigation.right: tbInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[10] && prevRow.children[10].children[0]) {
                                            focusAndSelect(prevRow.children[10].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[10] && nextRow.children[10].children[0]) {
                                            focusAndSelect(nextRow.children[10].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowLowerLField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(tbInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(upperIInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.lowerL = parseInt(text) || 0
                                    parent.parent.updateProfile()
                                }
                                
                            }
                        }

                        // tb - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[11]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: tbInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.tb ? profileData.tb.toFixed(1) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 1 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: bfBracketsInput
                                KeyNavigation.backtab: lowerLInput
                                KeyNavigation.left: lowerLInput
                                KeyNavigation.right: bfBracketsInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[11] && prevRow.children[11].children[0]) {
                                            focusAndSelect(prevRow.children[11].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[11] && nextRow.children[11].children[0]) {
                                            focusAndSelect(nextRow.children[11].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowTbField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(bfBracketsInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(lowerLInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.tb = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // bf (Brackets) - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[12]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: bfBracketsInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.bfBrackets ? profileData.bfBrackets.toFixed(0) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: IntValidator { bottom: 0 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: tbfInput
                                KeyNavigation.backtab: tbInput
                                KeyNavigation.left: tbInput
                                KeyNavigation.right: tbfInput
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[12] && prevRow.children[12].children[0]) {
                                            focusAndSelect(prevRow.children[12].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[12] && nextRow.children[12].children[0]) {
                                            focusAndSelect(nextRow.children[12].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowBfBracketsField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        focusAndSelect(tbfInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(tbInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.bfBrackets = parseInt(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // tbf - Editable Numeric Input
                        Rectangle {
                            width: root.columnWidths[13]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: tbfInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: profileData.tbf ? profileData.tbf.toFixed(1) : ""
                                font.pixelSize: 10
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: DoubleValidator { bottom: 0; decimals: 1 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: nameInput // Loop back to first cell (or move to next row)
                                KeyNavigation.backtab: bfBracketsInput
                                KeyNavigation.left: bfBracketsInput
                                KeyNavigation.right: tbfInput // Stay in same cell (last column)
                                
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        var prevRow = profileRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[13] && prevRow.children[13].children[0]) {
                                            focusAndSelect(prevRow.children[13].children[0])
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < profileRepeater.count - 1) {
                                        var nextRow = profileRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[13] && nextRow.children[13].children[0]) {
                                            focusAndSelect(nextRow.children[13].children[0])
                                        }
                                    } else {
                                        focusAndSelect(shadowTbfField)
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        // At end of last column, stay here or move to next row
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        focusAndSelect(bfBracketsInput)
                                        event.accepted = true
                                    } else {
                                        event.accepted = false
                                    }
                                }
                                
                                onEditingFinished: {
                                    // Update the profileData with new value
                                    profileData.tbf = parseFloat(text) || 0
                                    parent.parent.updateProfile()
                                }
                            }
                        }

                        // Action - Delete Button
                        Rectangle {
                            width: root.columnWidths[14]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1

                            // Trash Icon
                            Rectangle {
                                anchors.centerIn: parent
                                width: 16
                                height: 18
                                color: "transparent"
                                
                                // Trash lid
                                Rectangle {
                                    width: 14
                                    height: 2
                                    color: "#f44336"
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                // Trash handle
                                Rectangle {
                                    width: 6
                                    height: 2
                                    color: "#f44336"
                                    anchors.top: parent.top
                                    anchors.topMargin: -2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                
                                // Trash body
                                Rectangle {
                                    width: 12
                                    height: 14
                                    color: "#f44336"
                                    anchors.top: parent.top
                                    anchors.topMargin: 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    // Vertical lines inside trash
                                    Rectangle {
                                        width: 1
                                        height: 10
                                        color: "white"
                                        anchors.left: parent.left
                                        anchors.leftMargin: 3
                                        anchors.top: parent.top
                                        anchors.topMargin: 2
                                    }
                                    Rectangle {
                                        width: 1
                                        height: 10
                                        color: "white"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: 2
                                    }
                                    Rectangle {
                                        width: 1
                                        height: 10
                                        color: "white"
                                        anchors.right: parent.right
                                        anchors.rightMargin: 3
                                        anchors.top: parent.top
                                        anchors.topMargin: 2
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    
                                    onEntered: {
                                        parent.scale = 1.1
                                    }
                                    
                                    onExited: {
                                        parent.scale = 1.0
                                    }
                                    
                                    onClicked: {
                                        if (profileController && profileData.id) {
                                            root.deleteProfile(rowIndex, profileData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Shadow row untuk menambah data baru
                Row {
                    id: shadowRow
                    
                    function resetToLastData(lastProfile) {
                        shadowTypeField.text = lastProfile.type || ""
                        shadowNameField.text = ""
                        shadowHwField.text = lastProfile.hw || "0"
                        shadowTwField.text = lastProfile.tw || "0"
                        shadowBfProfilesField.text = lastProfile.bfProfiles || "0"
                        shadowTfField.text = lastProfile.tf || "0"
                        shadowAreaField.text = lastProfile.area || "0"
                        shadowEField.text = lastProfile.e || "0"
                        shadowWField.text = lastProfile.w || "0"
                        shadowUpperIField.text = lastProfile.upperI || "0"
                        shadowLowerLField.text = lastProfile.lowerL || "0"
                        shadowTbField.text = lastProfile.tb || "0"
                        shadowBfBracketsField.text = lastProfile.bfBrackets || "0"
                        shadowTbfField.text = lastProfile.tbf || "0"
                    }
                    
                    // Type column
                    Rectangle {
                        width: columnWidths[0]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowTypeField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: ""
                        }
                    }
                    
                    // Name column
                    Rectangle {
                        width: columnWidths[1]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowNameField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: ""
                        }
                    }
                    
                    // hw column
                    Rectangle {
                        width: columnWidths[2]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowHwField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // tw column
                    Rectangle {
                        width: columnWidths[3]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowTwField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // bfProfiles column
                    Rectangle {
                        width: columnWidths[4]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowBfProfilesField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // tf column
                    Rectangle {
                        width: columnWidths[5]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowTfField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // Area column
                    Rectangle {
                        width: columnWidths[6]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowAreaField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // e column
                    Rectangle {
                        width: columnWidths[7]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowEField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // w column
                    Rectangle {
                        width: columnWidths[8]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowWField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // upperI column
                    Rectangle {
                        width: columnWidths[9]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowUpperIField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // lowerL column
                    Rectangle {
                        width: columnWidths[10]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowLowerLField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // tb column
                    Rectangle {
                        width: columnWidths[11]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowTbField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // bfBrackets column
                    Rectangle {
                        width: columnWidths[12]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowBfBracketsField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // tbf column
                    Rectangle {
                        width: columnWidths[13]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        TextInput {
                            id: shadowTbfField
                            anchors.fill: parent
                            anchors.margins: 4
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 3
                            }
                        }
                    }
                    
                    // Action column untuk save/cancel
                    Rectangle {
                        width: columnWidths[14]
                        height: 40
                        border.width: 1
                        border.color: "#CCCCCC"
                        color: "#F8F8F8"
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            
                            // Save button
                            Rectangle {
                                width: 20
                                height: 20
                                color: saveMouseArea.containsMouse ? "#4CAF50" : "#66BB6A"
                                radius: 2
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    font.pixelSize: 12
                                    color: "white"
                                }
                                
                                MouseArea {
                                    id: saveMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        addNewProfile(
                                            shadowTypeField.text,
                                            shadowNameField.text,
                                            parseFloat(shadowHwField.text) || 0,
                                            parseFloat(shadowTwField.text) || 0,
                                            parseFloat(shadowBfProfilesField.text) || 0,
                                            parseFloat(shadowTfField.text) || 0,
                                            parseFloat(shadowAreaField.text) || 0,
                                            parseFloat(shadowEField.text) || 0,
                                            parseFloat(shadowWField.text) || 0,
                                            parseFloat(shadowUpperIField.text) || 0,
                                            parseFloat(shadowLowerLField.text) || 0,
                                            parseFloat(shadowTbField.text) || 0,
                                            parseFloat(shadowBfBracketsField.text) || 0,
                                            parseFloat(shadowTbfField.text) || 0
                                        )
                                    }
                                }
                            }
                            
                            // Cancel button
                            Rectangle {
                                width: 20
                                height: 20
                                color: cancelMouseArea.containsMouse ? "#F44336" : "#EF5350"
                                radius: 2
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "✗"
                                    font.pixelSize: 12
                                    color: "white"
                                }
                                
                                MouseArea {
                                    id: cancelMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        resetShadowRow()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
        

    

    // Connections untuk mendengarkan perubahan controller
    Connections {
        target: profileController
        function onOperationCompleted(success, message) {
            console.log("Profile operation:", success ? "Success" : "Failed", "-", message)
            if (success) {
                root.refreshData()
            }
        }
        function onProfilesChanged() {
            root.refreshData()
        }
    }
}
