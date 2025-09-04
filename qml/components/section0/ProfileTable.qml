import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/*
 * PERFORMANCE OPTIMIZATIONS IMPLEMENTED:
 * 
 * 1. Initial Load Optimization:
 *    - isInitialLoad flag prevents calculations during database load
 *    - Only display data without expensive calculations on first load
 * 
 * 2. Event Handling Optimization:
 *    - isUserEditing flag tracks real user interactions
 *    - handleEditingFinished only runs when user actually edits
 *    - Floating-point tolerance prevents unnecessary calculations
 * 
 * 3. CRUD Operations Optimization:
 *    - updateSingleRow(): Updates only specific row by ID
 *    - deleteSingleRow(): Removes only specific row by ID  
 *    - addSingleRow(): Adds new row without full refresh
 *    - All CRUD operations avoid full data reloads
 *
 * 4. Numeric Formatting Consistency:
 *    - All calculations rounded to 2 decimal places for consistency
 *    - formatToTwoDecimals(): Ensures consistent rounding in calculations
 *    - formatDisplay(): Provides consistent display formatting
 *    - UI and database use identical formatting (no rounding differences)
 */

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
    
    // Flag untuk membedakan antara initial load dan user changes
    property bool isInitialLoad: true
    
    // Flag untuk prevent recursive shadow row updates
    property bool isUpdatingShadowRow: false
    
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

    // Function untuk refresh data dari database (hanya untuk initial load)
    function refreshData() {
        isInitialLoad = true
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
            
            // Set flag bahwa initial load sudah selesai
            isInitialLoad = false
        } else {
            console.log("Profile controller not available")
            tableModel = []
            isInitialLoad = false
        }
    }

    // Function untuk update single row berdasarkan ID
    function updateSingleRow(profileId) {
        if (!profileController) {
            console.log("Profile controller not available for single row update")
            return
        }
        
        console.log("Updating single row for profile ID:", profileId)
        
        // Get updated profile data from controller
        var updatedProfile = profileController.getProfileById(profileId)
        if (!updatedProfile) {
            console.log("Profile with ID", profileId, "not found")
            return
        }
        
        // Find and update the row in tableModel
        var found = false
        var wasLastRow = false
        for (var i = 0; i < tableModel.length; i++) {
            if (tableModel[i].id === profileId) {
                // Check if this is the last row before updating
                wasLastRow = (i === tableModel.length - 1)
                
                tableModel[i] = updatedProfile
                found = true
                console.log("Updated row", i, "with new data for profile ID:", profileId)
                break
            }
        }
        
        if (!found) {
            console.log("Profile ID", profileId, "not found in current table model")
            return
        }
        
        // Trigger model update
        tableModel = tableModel.slice() // Force array update
        
        // Auto-update shadow row dari data terbaru jika yang diupdate adalah baris terakhir
        // atau jika setelah update ini menjadi baris terakhir
        if (shadowRow && shadowRow.autoUpdateFromLastRow) {
            var currentLastIndex = tableModel.length - 1
            var updatedIsNowLast = false
            
            // Check if the updated profile is now the last row
            for (var j = 0; j < tableModel.length; j++) {
                if (tableModel[j].id === profileId && j === currentLastIndex) {
                    updatedIsNowLast = true
                    break
                }
            }
            
            // Update shadow row if the updated row was or is now the last row
            if (wasLastRow || updatedIsNowLast) {
                console.log("Updated row was/is last row, updating shadow row accordingly")
                shadowRow.autoUpdateFromLastRow()
            }
        }
    }

    // Function untuk delete single row berdasarkan ID
    function deleteSingleRow(profileId) {
        console.log("Deleting single row for profile ID:", profileId)
        
        // Find and remove the row from tableModel
        var newTableModel = []
        var found = false
        
        for (var i = 0; i < tableModel.length; i++) {
            if (tableModel[i].id !== profileId) {
                newTableModel.push(tableModel[i])
            } else {
                found = true
                console.log("Removed row", i, "for profile ID:", profileId)
            }
        }
        
        if (found) {
            tableModel = newTableModel
            console.log("Profile deleted. New table size:", tableModel.length)
        } else {
            console.log("Profile ID", profileId, "not found in current table model")
        }
    }

    // Function untuk add single row 
    function addSingleRow(newProfile) {
        if (!newProfile || !newProfile.id) {
            console.log("Invalid profile data for adding new row")
            return
        }
        
        console.log("Adding single row for new profile ID:", newProfile.id)
        
        // Check if profile already exists (avoid duplicates)
        for (var i = 0; i < tableModel.length; i++) {
            if (tableModel[i].id === newProfile.id) {
                console.log("Profile ID", newProfile.id, "already exists, updating instead")
                updateSingleRow(newProfile.id)
                return
            }
        }
        
        // Add new profile to tableModel
        var newTableModel = tableModel.slice() // Create copy
        newTableModel.push(newProfile)
        tableModel = newTableModel
        
        console.log("New profile added. New table size:", tableModel.length)
        
        // Auto-update shadow row dari data terbaru
        if (shadowRow && shadowRow.autoUpdateFromLastRow) {
            shadowRow.autoUpdateFromLastRow()
        }
    }

    // Load data when component is completed
    Component.onCompleted: {
        refreshData()
    }
    
    // Watch for changes in tableModel to auto-update shadow row
    onTableModelChanged: {
        if (shadowRow && shadowRow.autoUpdateFromLastRow && tableModel.length > 0) {
            shadowRow.autoUpdateFromLastRow()
        }
    }
    
    // Helper function untuk focus + select all
    function focusAndSelect(targetInput) {
        targetInput.forceActiveFocus()
        targetInput.selectAll()
    }

    // Helper function untuk format angka ke 2 decimal places
    function formatToTwoDecimals(value) {
        var numValue = parseFloat(value) || 0
        return Math.round(numValue * 100) / 100
    }

    // Helper function untuk format display dengan 2 decimal places
    function formatDisplay(value) {
        var numValue = parseFloat(value) || 0
        return (Math.round(numValue * 100) / 100).toFixed(2)
    }

    // Function untuk generate name berdasarkan type dan dimensi
    function generateProfileName(type, hw, tw, bfProfiles, tf) {
        var thisType = type || ""
        var thisHw = parseFloat(hw) || 0
        var thisTw = parseFloat(tw) || 0
        var thisBf_profiles = parseFloat(bfProfiles) || 0
        var thisTf = parseFloat(tf) || 0
        
        console.log("generateProfileName called with:", thisType, thisHw, thisTw, thisBf_profiles, thisTf)
        
        if (thisType == "HP" || thisType == "Bar" || thisType == "T") {
            var result = thisType + " " + thisHw.toFixed(0) + "*" + thisTw.toFixed(1)
            console.log("Generated name for HP/Bar/T:", result)
            return result
        } else if (thisType == "L") {
            var result = thisType + " " + thisHw.toFixed(0) + "*" + thisTw.toFixed(1) + "*" + thisBf_profiles.toFixed(0) + "*" + thisTf.toFixed(1)
            console.log("Generated name for L:", result)
            return result
        }
        console.log("No match, returning type:", thisType)
        return thisType
    }

    // Function untuk calculate area, e, w, dan upper_i menggunakan countingFormula
    function calculateProfileValues(type, hw, tw, bfProfiles, tf) {
        if (!profileController) {
            console.log("ProfileController not available for calculation")
            return {area: 0.00, e: 0.00, w: 0.00, upperI: 0.00}
        }
        
        var thisHw = parseFloat(hw) || 0
        var thisTw = parseFloat(tw) || 0
        var thisBf = parseFloat(bfProfiles) || 0
        var thisTf = parseFloat(tf) || 0
        var thisType = type || "Bar"
        
        // Only skip if essential dimensions are missing
        if (thisHw <= 0 || thisTw <= 0) {
            console.log("Skipping calculation - essential values missing (hw or tw):", thisHw, thisTw)
            return {area: 0.00, e: 0.00, w: 0.00, upperI: 0.00}
        }
        
        // For type L, we also need bf and tf
        if (thisType === "L" && (thisBf <= 0 || thisTf <= 0)) {
            console.log("Skipping calculation - L profile needs bf and tf:", thisBf, thisTf)
            return {area: 0.00, e: 0.00, w: 0.00, upperI: 0.00}
        }
        
        // For other types, ensure tf has a reasonable value
        if (thisType !== "L" && thisTf <= 0) {
            thisTf = thisTw // Use tw as default for tf if not specified
        }
        
        console.log("Calling countingFormula with:", thisHw, thisTw, thisBf, thisTf, thisType)
        
        try {
            var result = profileController.countingFormula(thisHw, thisTw, thisBf, thisTf, thisType)
            if (result && result.length >= 4) {
                // Round all values to 2 decimal places for consistency
                var calculatedValues = {
                    area: Math.round(result[0] * 100) / 100,
                    e: Math.round(result[1] * 100) / 100, 
                    w: Math.round(result[2] * 100) / 100,
                    upperI: Math.round(result[3] * 100) / 100
                }
                console.log("Calculated values (rounded to 2 decimals):", calculatedValues)
                return calculatedValues
            } else {
                console.log("countingFormula returned invalid result:", result)
                return {area: 0.00, e: 0.00, w: 0.00, upperI: 0.00}
            }
        } catch (error) {
            console.log("Error calling countingFormula:", error.toString())
            return {area: 0.00, e: 0.00, w: 0.00, upperI: 0.00}
        }
    }

    // Function untuk calculate l, tb, bf, dan tbf menggunakan profileTableCountingFormulaBrackets
    function calculateBracketValues(tw, w, rehProfiles, rehBrackets) {
        if (!profileController) {
            console.log("ProfileController not available for bracket calculation")
            return {l: 0.00, tb: 0.00, bf: 0.00, tbf: 0.00}
        }
        
        var thisTw = parseFloat(tw) || 0
        var thisW = parseFloat(w) || 0
        var thisRehProfiles = parseFloat(rehProfiles) || 235
        var thisRehBrackets = parseFloat(rehBrackets) || 235
        
        // Skip calculation if essential values are missing
        if (thisTw <= 0 || thisW <= 0) {
            console.log("Skipping bracket calculation - essential values missing (tw or w):", thisTw, thisW)
            return {l: 0.00, tb: 0.00, bf: 0.00, tbf: 0.00}
        }
        
        console.log("Calling profileTableCountingFormulaBrackets with:", thisTw, thisW, thisRehProfiles, thisRehBrackets)
        
        try {
            var result = profileController.profileTableCountingFormulaBrackets(thisTw, thisW, thisRehProfiles, thisRehBrackets)
            if (result && result.length >= 4) {
                // Round all values to 2 decimal places for consistency
                var calculatedValues = {
                    l: Math.round(result[0] * 100) / 100,
                    tb: Math.round(result[1] * 100) / 100,
                    bf: Math.round(result[2] * 100) / 100,
                    tbf: Math.round(result[3] * 100) / 100
                }
                console.log("Calculated bracket values (rounded to 2 decimals):", calculatedValues)
                return calculatedValues
            } else {
                console.log("profileTableCountingFormulaBrackets returned invalid result:", result)
                return {l: 0.00, tb: 0.00, bf: 0.00, tbf: 0.00}
            }
        } catch (error) {
            console.log("Error calling profileTableCountingFormulaBrackets:", error.toString())
            return {l: 0.00, tb: 0.00, bf: 0.00, tbf: 0.00}
        }
    }

    // Function untuk trigger bracket recalculation di semua rows
    function triggerBracketRecalculation() {
        console.log("triggerBracketRecalculation called")
        
        // Update shadow row
        if (shadowRow && shadowRow.updateShadowRowValues) {
            shadowRow.updateShadowRowValues()
        }
        
        // Update all data rows
        for (var i = 0; i < profileRepeater.count; i++) {
            var row = profileRepeater.itemAt(i)
            if (row && row.updateProfileName) {
                row.updateProfileName()
            }
        }
    }

    // Function untuk add profile baru dari shadow row
    function addNewProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf) {
        if (!profileController) {
            console.log("Error: ProfileController not available")
            return false
        }
        
        // Format all numeric values to 2 decimal places before saving
        var formattedHw = formatToTwoDecimals(hw)
        var formattedTw = formatToTwoDecimals(tw)
        var formattedBfProfiles = formatToTwoDecimals(bfProfiles)
        var formattedTf = formatToTwoDecimals(tf)
        var formattedArea = formatToTwoDecimals(area)
        var formattedE = formatToTwoDecimals(e)
        var formattedW = formatToTwoDecimals(w)
        var formattedUpperI = formatToTwoDecimals(upperI)
        var formattedLowerL = formatToTwoDecimals(lowerL)
        var formattedTb = formatToTwoDecimals(tb)
        var formattedBfBrackets = formatToTwoDecimals(bfBrackets)
        var formattedTbf = formatToTwoDecimals(tbf)
        
        console.log("Calling addNewProfile with formatted parameters:", type, name, 
                   formattedHw, formattedTw, formattedBfProfiles, formattedTf, 
                   formattedArea, formattedE, formattedW, formattedUpperI, 
                   formattedLowerL, formattedTb, formattedBfBrackets, formattedTbf)
        
        try {
            var success = profileController.addNewProfile(type, name, formattedHw, formattedTw, formattedBfProfiles, formattedTf, formattedArea, formattedE, formattedW, formattedUpperI, formattedLowerL, formattedTb, formattedBfBrackets, formattedTbf)
            if (success) {
                console.log("New profile added successfully")
                
                // Get the newly created profile from controller instead of full refresh
                var newProfile = {
                    id: profileController.lastInsertedId || Date.now(), // Fallback to timestamp if no ID
                    type: type,
                    name: name,
                    hw: formattedHw,
                    tw: formattedTw,
                    bfProfiles: formattedBfProfiles,
                    tf: formattedTf,
                    area: formattedArea,
                    e: formattedE,
                    w: formattedW,
                    upperI: formattedUpperI,
                    lowerL: formattedLowerL,
                    tb: formattedTb,
                    bfBrackets: formattedBfBrackets,
                    tbf: formattedTbf
                }
                
                // Add single row instead of full refresh
                addSingleRow(newProfile)
                
                // Reset shadow row ke nilai dari data yang baru ditambahkan
                shadowRow.resetToLastData(newProfile)
                
                // Reset manual name flag untuk entry berikutnya
                shadowRow.isManualNameInput = false
                
                return true
            } else {
                console.log("Failed to add profile")
                if (profileController.lastError) {
                    console.log("Error details:", profileController.lastError)
                }
                return false
            }
        } catch (error) {
            console.log("Exception in addNewProfile:", error.toString())
            return false
        }
    }

    // Function untuk reset shadow row ke data terakhir
    function resetShadowRow() {
        if (profileController && tableModel.length > 0) {
            var lastProfile = tableModel[tableModel.length - 1]
            console.log("Resetting shadow row to last profile:", lastProfile.name)
            shadowRow.resetToLastData(lastProfile)
        } else {
            // Set default values when no data is available
            console.log("No data available, setting default shadow row values")
            shadowRow.resetToLastData({
                type: "Bar",
                name: "",  // Empty name untuk entry baru
                hw: "400.0",
                tw: "26.0",
                bfProfiles: "85.0",
                tf: "14.7",
                area: "104.0",
                e: "200.0",
                w: "1359.29",
                upperI: "48096.0",
                lowerL: "512",
                tb: "14.7",
                bfBrackets: "85",
                tbf: "14.7"
            })
        }
    }

    // Function untuk delete profile
    function deleteProfile(index, profileId) {
        if (!profileController) {
            console.log("Profile controller not available")
            return
        }
        
        console.log("Deleting profile with ID:", profileId, "at index:", index)
        
        if (profileController.deleteProfile(profileId)) {
            console.log("Profile deleted successfully from database")
            // Delete single row instead of full refresh
            deleteSingleRow(profileId)
        } else {
            console.log("Failed to delete profile from database")
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
                    
                    onTextChanged: {
                        // Trigger bracket recalculation for all rows when REH Brackets changes
                        Qt.callLater(function() {
                            triggerBracketRecalculation()
                        })
                    }
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
                    
                    onTextChanged: {
                        // Trigger bracket recalculation for all rows when REH Profiles changes
                        Qt.callLater(function() {
                            triggerBracketRecalculation()
                        })
                    }
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
                            if (profileController.clearAllProfiles()) {
                                console.log("All profiles cleared successfully")
                                // Clear tableModel instead of full refresh
                                tableModel = []
                            } else {
                                console.log("Failed to clear all profiles")
                            }
                        }
                    }
                }

                Button {
                    text: "Refresh"
                    Layout.preferredHeight: 20
                    font.pixelSize: 9
                    onClicked: {
                        console.log("Refresh button clicked - loading data from database")
                        refreshData()
                    }
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
                        property bool isUserEditing: false // Flag to track user editing
                        
                        // Function to update name based on current field values
                        function updateProfileName() {
                            // Skip calculations during initial load
                            if (root.isInitialLoad) {
                                console.log("Skipping calculations during initial load for row", rowIndex)
                                return
                            }
                            
                            console.log("updateProfileName called for row", rowIndex)
                            
                            var typeField = children[0].children[0] // ComboBox
                            var nameField = children[1].children[0] // Name TextInput
                            var hwField = children[2].children[0] // hw TextInput  
                            var twField = children[3].children[0] // tw TextInput
                            var bfField = children[4].children[0] // bf TextInput
                            var tfField = children[5].children[0] // tf TextInput
                            var areaField = children[6].children[0] // area TextInput
                            var eField = children[7].children[0] // e TextInput
                            var wField = children[8].children[0] // w TextInput
                            var upperIField = children[9].children[0] // upperI TextInput
                            var lField = children[10].children[0] // l TextInput
                            var tbField = children[11].children[0] // tb TextInput
                            var bfBracketsField = children[12].children[0] // bfBrackets TextInput
                            var tbfField = children[13].children[0] // tbf TextInput
                            
                            var newName = generateProfileName(
                                typeField.currentText,
                                hwField.text,
                                twField.text,
                                bfField.text,
                                tfField.text
                            )
                            
                            nameField.text = newName
                            
                            // Calculate and update area, e, w, upperI using countingFormula
                            var calculatedValues = calculateProfileValues(
                                typeField.currentText,
                                hwField.text,
                                twField.text,
                                bfField.text,
                                tfField.text
                            )
                            
                            console.log("Row", rowIndex, "calculated values:", calculatedValues)
                            
                            // Always update calculated values (even if 0)
                            areaField.text = calculatedValues.area.toFixed(2)
                            profileData.area = calculatedValues.area
                            
                            eField.text = calculatedValues.e.toFixed(2)
                            profileData.e = calculatedValues.e
                            
                            wField.text = calculatedValues.w.toFixed(2)
                            profileData.w = calculatedValues.w
                            
                            upperIField.text = calculatedValues.upperI.toFixed(2)
                            profileData.upperI = calculatedValues.upperI
                            
                            // Calculate and update bracket values using profileTableCountingFormulaBrackets
                            var bracketValues = calculateBracketValues(
                                twField.text,
                                wField.text,
                                rehProfilesInput.text,
                                rehBracketsInput.text
                            )
                            
                            console.log("Row", rowIndex, "calculated bracket values:", bracketValues)
                            
                            // Always update bracket calculated values (even if 0)
                            lField.text = bracketValues.l.toFixed(2)
                            profileData.lowerL = bracketValues.l
                            
                            tbField.text = bracketValues.tb.toFixed(2)
                            profileData.tb = bracketValues.tb
                            
                            bfBracketsField.text = bracketValues.bf.toFixed(2)
                            profileData.bfBrackets = bracketValues.bf
                            
                            tbfField.text = bracketValues.tbf.toFixed(2)
                            profileData.tbf = bracketValues.tbf
                            
                            console.log("Row", rowIndex, "all fields updated - name:", newName, "area:", areaField.text, "e:", eField.text, "w:", wField.text, "upperI:", upperIField.text, "l:", lField.text, "tb:", tbField.text, "bf:", bfBracketsField.text, "tbf:", tbfField.text)
                        }
                        
                        // Common function to handle database update on editing finish
                        function handleEditingFinished() {
                            // Skip if during initial load
                            if (root.isInitialLoad) {
                                console.log("Skipping handleEditingFinished during initial load for row", rowIndex)
                                return
                            }
                            
                            // Only update if user is actually editing
                            if (!isUserEditing) {
                                console.log("Skipping handleEditingFinished - not user editing for row", rowIndex)
                                return
                            }
                            
                            console.log("handleEditingFinished called for row", rowIndex)
                            // Ensure profileData is properly updated before calling updateProfile
                            Qt.callLater(function() {
                                updateProfile()
                            })
                        }
                        
                        function updateProfile() {
                            if (!profileController || !profileData.id) {
                                console.log("Skipping updateProfile - missing controller or profile ID for row", rowIndex)
                                return
                            }
                            
                            // Skip if during initial load
                            if (root.isInitialLoad) {
                                console.log("Skipping updateProfile during initial load for row", rowIndex)
                                return
                            }
                            
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
                            
                            // Compare with original values using tolerance for floating point numbers
                            for (var key in currentValues) {
                                var original = originalValues[key] || 0
                                var current = currentValues[key] || 0
                                
                                // For string values, use direct comparison
                                if (typeof current === "string") {
                                    if (original !== current) {
                                        hasChanges = true
                                        console.log("String change detected for", key, ":", original, "->", current)
                                        break
                                    }
                                } else {
                                    // For numeric values, use tolerance to avoid floating point precision issues
                                    var tolerance = 0.001
                                    if (Math.abs(original - current) > tolerance) {
                                        hasChanges = true
                                        console.log("Numeric change detected for", key, ":", original, "->", current)
                                        break
                                    }
                                }
                            }
                            
                            if (hasChanges) {
                                console.log("Profile values changed, updating database for ID:", profileData.id)
                                console.log("Updating with values:", currentValues)
                                
                                // Call the controller's updateProfile method to save to database
                                var success = profileController.updateProfile(
                                    profileData.id,
                                    currentValues.type,
                                    currentValues.name,
                                    currentValues.hw,
                                    currentValues.tw,
                                    currentValues.bfProfiles,
                                    currentValues.tf,
                                    currentValues.area,
                                    currentValues.e,
                                    currentValues.w,
                                    currentValues.upperI,
                                    currentValues.lowerL,
                                    currentValues.tb,
                                    currentValues.bfBrackets,
                                    currentValues.tbf
                                )
                                
                                if (success) {
                                    console.log("Database update successful for profile ID:", profileData.id)
                                    // Update original values for future comparisons
                                    originalValues = Object.assign({}, currentValues)
                                    
                                    // Check if this is the last row before updating
                                    var wasLastRow = false
                                    var lastRowId = root.tableModel.length > 0 ? root.tableModel[root.tableModel.length - 1].id : null
                                    if (lastRowId === profileData.id) {
                                        wasLastRow = true
                                    }
                                    
                                    // Update tableModel locally to reflect changes immediately
                                    for (var i = 0; i < root.tableModel.length; i++) {
                                        if (root.tableModel[i].id === profileData.id) {
                                            // Update the tableModel entry with new values
                                            var updatedModel = root.tableModel.slice() // Create copy
                                            updatedModel[i] = Object.assign({}, updatedModel[i], currentValues)
                                            root.tableModel = updatedModel
                                            console.log("TableModel updated locally for profile ID:", profileData.id)
                                            
                                            // Check if this row is now the last row after update
                                            var isNowLastRow = (i === updatedModel.length - 1)
                                            
                                            // Update shadow row if this was/is the last row
                                            if ((wasLastRow || isNowLastRow) && shadowRow && shadowRow.autoUpdateFromLastRow) {
                                                console.log("Row", i, "was/is last row, updating shadow row from updated data")
                                                Qt.callLater(function() {
                                                    shadowRow.autoUpdateFromLastRow()
                                                })
                                            }
                                            break
                                        }
                                    }
                                } else {
                                    console.log("Database update failed for profile ID:", profileData.id)
                                    if (profileController.lastError) {
                                        console.log("Error details:", profileController.lastError)
                                    }
                                }
                            } else {
                                console.log("No changes detected for profile ID:", profileData.id, "- skipping update")
                            }
                        }
                        
                        // Initialize original values when component is created
                        Component.onCompleted: {
                            // Set initial editing state to false during component creation
                            isUserEditing = false
                            
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
                            
                            console.log("Row", rowIndex, "initialized with original values:", originalValues)
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
                                    console.log("Data row type changed to:", currentText, "for row", rowIndex)
                                    
                                    // Skip during initial load
                                    if (root.isInitialLoad) {
                                        console.log("Skipping type change handling during initial load for row", rowIndex)
                                        return
                                    }
                                    
                                    // Update profileData with new type
                                    var oldType = profileData.type || ""
                                    profileData.type = currentText
                                    
                                    // Only trigger updates if the type actually changed
                                    if (oldType !== currentText) {
                                        console.log("Type actually changed from", oldType, "to", currentText)
                                        isUserEditing = true
                                        
                                        // Use Qt.callLater to ensure all components are ready
                                        Qt.callLater(function() {
                                            updateProfileName()
                                            handleEditingFinished()
                                        })
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
                                    handleEditingFinished()
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
                                text: profileData.hw ? profileData.hw.toFixed(2) : ""
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
                                    handleEditingFinished()
                                }
                                
                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        isUserEditing = true
                                    }
                                }
                                
                                onFocusChanged: {
                                    if (!focus) {
                                        isUserEditing = false
                                    }
                                }
                                
                                onTextChanged: {
                                    // Auto-update name when hw value changes (only if user is editing)
                                    if (!root.isInitialLoad && isUserEditing) {
                                        Qt.callLater(function() {
                                            updateProfileName()
                                        })
                                    }
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
                                text: profileData.tw ? profileData.tw.toFixed(2) : ""
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
                                    handleEditingFinished()
                                }
                                
                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        isUserEditing = true
                                    }
                                }
                                
                                onFocusChanged: {
                                    if (!focus) {
                                        isUserEditing = false
                                    }
                                }
                                
                                onTextChanged: {
                                    // Auto-update name when tw value changes (only if user is editing)
                                    if (!root.isInitialLoad && isUserEditing) {
                                        Qt.callLater(function() {
                                            updateProfileName()
                                        })
                                    }
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
                                text: profileData.bfProfiles ? profileData.bfProfiles.toFixed(2) : ""
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
                                    handleEditingFinished()
                                }
                                
                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        isUserEditing = true
                                    }
                                }
                                
                                onFocusChanged: {
                                    if (!focus) {
                                        isUserEditing = false
                                    }
                                }
                                
                                onTextChanged: {
                                    // Update profile name when bf value changes (only if user is editing)
                                    if (!root.isInitialLoad && isUserEditing) {
                                        Qt.callLater(function() {
                                            updateProfileName()
                                        })
                                    }
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
                                text: profileData.tf ? profileData.tf.toFixed(2) : ""
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
                                    handleEditingFinished()
                                }
                                
                                onActiveFocusChanged: {
                                    if (activeFocus) {
                                        isUserEditing = true
                                    }
                                }
                                
                                onFocusChanged: {
                                    if (!focus) {
                                        isUserEditing = false
                                    }
                                }
                                
                                onTextChanged: {
                                    // Update profile name when tf value changes
                                    if (!root.isInitialLoad && isUserEditing) {
                                        Qt.callLater(function() {
                                            updateProfileName()
                                        })
                                    }
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
                                    handleEditingFinished()
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
                                    handleEditingFinished()
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
                                    handleEditingFinished()
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
                                    handleEditingFinished()
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
                                text: profileData.lowerL ? profileData.lowerL.toFixed(2) : ""
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
                                    handleEditingFinished()
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
                                text: profileData.tb ? profileData.tb.toFixed(2) : ""
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
                                    handleEditingFinished()
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
                                text: profileData.bfBrackets ? profileData.bfBrackets.toFixed(2) : ""
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
                                    handleEditingFinished()
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
                                text: profileData.tbf ? profileData.tbf.toFixed(2) : ""
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
                                    handleEditingFinished()
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
                    
                    // Property untuk tracking changes
                    property bool autoUpdateEnabled: true
                    property bool isInitializing: false
                    property bool isManualNameInput: false  // Track if user manually typed name
                    
                    function resetToLastData(lastProfile) {
                        isInitializing = true
                        
                        var typeValue = lastProfile.type || "Bar"
                        var typeIndex = shadowTypeField.model.indexOf(typeValue)
                        shadowTypeField.currentIndex = typeIndex >= 0 ? typeIndex : 3 // Default to "Bar" if not found
                        
                        // Copy dimensions dari profile terakhir
                        shadowHwField.text = lastProfile.hw ? lastProfile.hw.toString() : "0"
                        shadowTwField.text = lastProfile.tw ? lastProfile.tw.toString() : "0"
                        shadowBfProfilesField.text = lastProfile.bfProfiles ? lastProfile.bfProfiles.toString() : "0"
                        shadowTfField.text = lastProfile.tf ? lastProfile.tf.toString() : "0"
                        
                        // Generate name berdasarkan type dan dimensions yang sudah dicopy
                        var generatedName = generateProfileName(
                            typeValue,
                            shadowHwField.text,
                            shadowTwField.text,
                            shadowBfProfilesField.text,
                            shadowTfField.text
                        )
                        shadowNameField.text = generatedName
                        
                        // Set calculated fields dari lastProfile
                        shadowAreaField.text = lastProfile.area ? lastProfile.area.toString() : "0"
                        shadowEField.text = lastProfile.e ? lastProfile.e.toString() : "0"
                        shadowWField.text = lastProfile.w ? lastProfile.w.toString() : "0"
                        shadowUpperIField.text = lastProfile.upperI ? lastProfile.upperI.toString() : "0"
                        shadowLowerLField.text = lastProfile.lowerL ? lastProfile.lowerL.toString() : "0"
                        shadowTbField.text = lastProfile.tb ? lastProfile.tb.toString() : "0"
                        shadowBfBracketsField.text = lastProfile.bfBrackets ? lastProfile.bfBrackets.toString() : "0"
                        shadowTbfField.text = lastProfile.tbf ? lastProfile.tbf.toString() : "0"
                        
                        // Reset manual name input flag karena name sudah digenerate
                        isManualNameInput = false
                        isInitializing = false
                        
                        // Trigger automatic calculation after copy
                        shadowRow.updateShadowRowValues()
                    }
                    
                    // Function untuk auto-update shadow row dari data terbaru
                    function autoUpdateFromLastRow() {
                        if (!autoUpdateEnabled || isInitializing || tableModel.length === 0) {
                            return
                        }
                        
                        console.log("Auto-updating shadow row from last data entry")
                        var lastProfile = tableModel[tableModel.length - 1]
                        
                        // Copy semua data termasuk type dan dimensions
                        var typeValue = lastProfile.type || "Bar"
                        var typeIndex = shadowTypeField.model.indexOf(typeValue)
                        if (shadowTypeField.currentIndex !== typeIndex) {
                            shadowTypeField.currentIndex = typeIndex >= 0 ? typeIndex : 3
                        }
                        
                        // Update dimensions jika berbeda
                        if (shadowHwField.text !== lastProfile.hw.toString()) {
                            shadowHwField.text = lastProfile.hw ? lastProfile.hw.toString() : "0"
                        }
                        if (shadowTwField.text !== lastProfile.tw.toString()) {
                            shadowTwField.text = lastProfile.tw ? lastProfile.tw.toString() : "0"
                        }
                        if (shadowBfProfilesField.text !== lastProfile.bfProfiles.toString()) {
                            shadowBfProfilesField.text = lastProfile.bfProfiles ? lastProfile.bfProfiles.toString() : "0"
                        }
                        if (shadowTfField.text !== lastProfile.tf.toString()) {
                            shadowTfField.text = lastProfile.tf ? lastProfile.tf.toString() : "0"
                        }
                        
                        // Always update name dan calculated values berdasarkan dimensions terbaru
                        shadowRow.updateShadowRowValues()
                    }
                    
                    // Function untuk update shadow row values ketika type/dimension berubah
                    function updateShadowRowValues() {
                        // Prevent recursive updates
                        if (root.isUpdatingShadowRow) {
                            console.log("Skipping updateShadowRowValues - already updating")
                            return
                        }
                        
                        root.isUpdatingShadowRow = true
                        console.log("updateShadowRowValues called")
                        
                        // Always generate and update name berdasarkan type dan dimensions
                        var newName = generateProfileName(
                            shadowTypeField.currentText,
                            shadowHwField.text,
                            shadowTwField.text,
                            shadowBfProfilesField.text,
                            shadowTfField.text
                        )
                        
                        console.log("Generated shadow name:", newName)
                        shadowNameField.text = newName
                        
                        // Reset manual name input flag karena name sudah digenerate otomatis
                        isManualNameInput = false
                        
                        // Calculate and update area, e, w, upperI using countingFormula
                        var calculatedValues = calculateProfileValues(
                            shadowTypeField.currentText,
                            shadowHwField.text,
                            shadowTwField.text,
                            shadowBfProfilesField.text,
                            shadowTfField.text
                        )
                        
                        console.log("Shadow calculated values:", calculatedValues)
                        
                        // Always update calculated values (even if 0)
                        shadowAreaField.text = calculatedValues.area.toFixed(2)
                        shadowEField.text = calculatedValues.e.toFixed(2)
                        shadowWField.text = calculatedValues.w.toFixed(2)
                        shadowUpperIField.text = calculatedValues.upperI.toFixed(2)
                        
                        // Calculate and update bracket values using profileTableCountingFormulaBrackets
                        var bracketValues = calculateBracketValues(
                            shadowTwField.text,
                            shadowWField.text,
                            rehProfilesInput.text,
                            rehBracketsInput.text
                        )
                        
                        console.log("Shadow calculated bracket values:", bracketValues)
                        
                        // Always update bracket calculated values (even if 0)
                        shadowLowerLField.text = bracketValues.l.toFixed(2)
                        shadowTbField.text = bracketValues.tb.toFixed(2)
                        shadowBfBracketsField.text = bracketValues.bf.toFixed(2)
                        shadowTbfField.text = bracketValues.tbf.toFixed(2)
                        
                        console.log("Shadow row updated - name:", newName, "area:", shadowAreaField.text, "e:", shadowEField.text, "w:", shadowWField.text, "upperI:", shadowUpperIField.text, "l:", shadowLowerLField.text, "tb:", shadowTbField.text, "bf:", shadowBfBracketsField.text, "tbf:", shadowTbfField.text)
                        
                        // Reset the flag after a short delay
                        Qt.callLater(function() {
                            root.isUpdatingShadowRow = false
                        })
                    }
                    
                    Component.onCompleted: {
                        // Initialize shadow row dengan data terakhir setelah data load
                        root.resetShadowRow()
                    }
                    
                    // Type column
                    Rectangle {
                        width: columnWidths[0]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        ComboBox {
                            id: shadowTypeField
                            anchors.centerIn: parent
                            width: parent.width - 4
                            height: 25
                            model: ["HP", "L", "T", "Bar"]
                            currentIndex: 3 // Default to "Bar"
                            font.pixelSize: 9
                            
                            property alias text: shadowTypeField.currentText
                            
                            onCurrentTextChanged: {
                                console.log("Shadow type changed to:", currentText)
                                
                                // Update name and calculated values automatically
                                if (!root.isUpdatingShadowRow) {
                                    Qt.callLater(function() {
                                        shadowRow.updateShadowRowValues()
                                    })
                                }
                            }
                        }
                    }
                    
                    // Name column
                    Rectangle {
                        width: columnWidths[1]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowNameField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: ""
                            color: "#666" // Gray text to distinguish from data rows
                            
                            KeyNavigation.tab: shadowHwField
                            KeyNavigation.backtab: shadowTbfField
                            KeyNavigation.left: shadowNameField
                            KeyNavigation.right: shadowHwField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[1] && lastRow.children[1].children[0]) {
                                        focusAndSelect(lastRow.children[1].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowHwField)
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
                            
                            Keys.onReturnPressed: {
                                // Add new profile when Enter is pressed
                                saveMouseArea.clicked()
                            }
                            
                            onTextChanged: {
                                // Track manual name input hanya jika bukan dari automatic update
                                if (!shadowRow.isInitializing && !root.isUpdatingShadowRow) {
                                    shadowRow.isManualNameInput = true
                                    console.log("Manual name input detected:", text)
                                }
                            }
                            
                            onActiveFocusChanged: {
                                // Reset manual flag when focus changes away
                                if (!activeFocus && text === "") {
                                    shadowRow.isManualNameInput = false
                                }
                            }
                        }
                    }
                    
                    // hw column
                    Rectangle {
                        width: columnWidths[2]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowHwField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 1 }
                            color: "#666" // Gray text to distinguish from data rows
                            
                            KeyNavigation.tab: shadowTwField
                            KeyNavigation.backtab: shadowNameField
                            KeyNavigation.left: shadowNameField
                            KeyNavigation.right: shadowTwField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[2] && lastRow.children[2].children[0]) {
                                        focusAndSelect(lastRow.children[2].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowTwField)
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
                                    focusAndSelect(shadowNameField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                            
                            onTextChanged: {
                                // Update name and calculated values when hw changes
                                if (!root.isUpdatingShadowRow) {
                                    Qt.callLater(function() {
                                        shadowRow.updateShadowRowValues()
                                    })
                                }
                            }
                        }
                    }
                    
                    // tw column
                    Rectangle {
                        width: columnWidths[3]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowTwField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 1 }
                            color: "#666" // Gray text to distinguish from data rows
                            
                            KeyNavigation.tab: shadowBfProfilesField
                            KeyNavigation.backtab: shadowHwField
                            KeyNavigation.left: shadowHwField
                            KeyNavigation.right: shadowBfProfilesField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[3] && lastRow.children[3].children[0]) {
                                        focusAndSelect(lastRow.children[3].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowBfProfilesField)
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
                                    focusAndSelect(shadowHwField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                            
                            onTextChanged: {
                                // Update name and calculated values when tw changes
                                if (!root.isUpdatingShadowRow) {
                                    Qt.callLater(function() {
                                        shadowRow.updateShadowRowValues()
                                    })
                                }
                            }
                        }
                    }
                    
                    // bfProfiles column
                    Rectangle {
                        width: columnWidths[4]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowBfProfilesField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 1 }
                            color: "#666" // Gray text to distinguish from data rows
                            
                            KeyNavigation.tab: shadowTfField
                            KeyNavigation.backtab: shadowTwField
                            KeyNavigation.left: shadowTwField
                            KeyNavigation.right: shadowTfField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[4] && lastRow.children[4].children[0]) {
                                        focusAndSelect(lastRow.children[4].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowTfField)
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
                                    focusAndSelect(shadowTwField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                            
                            onTextChanged: {
                                // Update name and calculated values when bf changes
                                if (!root.isUpdatingShadowRow) {
                                    Qt.callLater(function() {
                                        shadowRow.updateShadowRowValues()
                                    })
                                }
                            }
                        }
                    }
                    
                    // tf column
                    Rectangle {
                        width: columnWidths[5]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowTfField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 1 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowAreaField
                            KeyNavigation.backtab: shadowBfProfilesField
                            KeyNavigation.left: shadowBfProfilesField
                            KeyNavigation.right: shadowAreaField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[5] && lastRow.children[5].children[0]) {
                                        focusAndSelect(lastRow.children[5].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowAreaField)
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
                                    focusAndSelect(shadowBfProfilesField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                            
                            onTextChanged: {
                                // Update name and calculated values when tf changes
                                if (!root.isUpdatingShadowRow) {
                                    Qt.callLater(function() {
                                        shadowRow.updateShadowRowValues()
                                    })
                                }
                            }
                        }
                    }
                    
                    // Area column
                    Rectangle {
                        width: columnWidths[6]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowAreaField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowEField
                            KeyNavigation.backtab: shadowTfField
                            KeyNavigation.left: shadowTfField
                            KeyNavigation.right: shadowEField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[6] && lastRow.children[6].children[0]) {
                                        focusAndSelect(lastRow.children[6].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowEField)
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
                                    focusAndSelect(shadowTfField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // e column
                    Rectangle {
                        width: columnWidths[7]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowEField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowWField
                            KeyNavigation.backtab: shadowAreaField
                            KeyNavigation.left: shadowAreaField
                            KeyNavigation.right: shadowWField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[7] && lastRow.children[7].children[0]) {
                                        focusAndSelect(lastRow.children[7].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowWField)
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
                                    focusAndSelect(shadowAreaField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // w column
                    Rectangle {
                        width: columnWidths[8]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowWField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowUpperIField
                            KeyNavigation.backtab: shadowEField
                            KeyNavigation.left: shadowEField
                            KeyNavigation.right: shadowUpperIField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[8] && lastRow.children[8].children[0]) {
                                        focusAndSelect(lastRow.children[8].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowUpperIField)
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
                                    focusAndSelect(shadowEField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // upperI column
                    Rectangle {
                        width: columnWidths[9]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowUpperIField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowLowerLField
                            KeyNavigation.backtab: shadowWField
                            KeyNavigation.left: shadowWField
                            KeyNavigation.right: shadowLowerLField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[9] && lastRow.children[9].children[0]) {
                                        focusAndSelect(lastRow.children[9].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowLowerLField)
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
                                    focusAndSelect(shadowWField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // lowerL column
                    Rectangle {
                        width: columnWidths[10]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowLowerLField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: IntValidator { bottom: 0 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowTbField
                            KeyNavigation.backtab: shadowUpperIField
                            KeyNavigation.left: shadowUpperIField
                            KeyNavigation.right: shadowTbField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[10] && lastRow.children[10].children[0]) {
                                        focusAndSelect(lastRow.children[10].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowTbField)
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
                                    focusAndSelect(shadowUpperIField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // tb column
                    Rectangle {
                        width: columnWidths[11]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowTbField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 1 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowBfBracketsField
                            KeyNavigation.backtab: shadowLowerLField
                            KeyNavigation.left: shadowLowerLField
                            KeyNavigation.right: shadowBfBracketsField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[11] && lastRow.children[11].children[0]) {
                                        focusAndSelect(lastRow.children[11].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowBfBracketsField)
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
                                    focusAndSelect(shadowLowerLField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // bfBrackets column
                    Rectangle {
                        width: columnWidths[12]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowBfBracketsField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: IntValidator { bottom: 0 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowTbfField
                            KeyNavigation.backtab: shadowTbField
                            KeyNavigation.left: shadowTbField
                            KeyNavigation.right: shadowTbfField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[12] && lastRow.children[12].children[0]) {
                                        focusAndSelect(lastRow.children[12].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    focusAndSelect(shadowTbfField)
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
                                    focusAndSelect(shadowTbField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // tbf column
                    Rectangle {
                        width: columnWidths[13]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        TextInput {
                            id: shadowTbfField
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 10
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            text: "0"
                            validator: DoubleValidator { bottom: 0; decimals: 1 }
                            color: "#666"
                            
                            KeyNavigation.tab: shadowNameField
                            KeyNavigation.backtab: shadowBfBracketsField
                            KeyNavigation.left: shadowBfBracketsField
                            KeyNavigation.right: shadowTbfField
                            
                            Keys.onUpPressed: {
                                if (profileRepeater.count > 0) {
                                    var lastRow = profileRepeater.itemAt(profileRepeater.count - 1)
                                    if (lastRow && lastRow.children[13] && lastRow.children[13].children[0]) {
                                        focusAndSelect(lastRow.children[13].children[0])
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
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
                                    focusAndSelect(shadowBfBracketsField)
                                    event.accepted = true
                                } else {
                                    event.accepted = false
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                saveMouseArea.clicked()
                            }
                        }
                    }
                    
                    // Action column untuk add button
                    Rectangle {
                        width: columnWidths[14]
                        height: 30
                        border.width: 1
                        border.color: "#ddd"
                        color: "#f8f8f8"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Add"
                            font.pixelSize: 10
                            color: "#2196F3"
                            font.bold: true
                            
                            MouseArea {
                                id: saveMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Debug: print values before calling addNewProfile
                                    console.log("Debug - Type:", shadowTypeField.currentText)
                                    console.log("Debug - Name:", shadowNameField.text)
                                    console.log("Debug - Values:", parseFloat(shadowHwField.text) || 0, parseFloat(shadowTwField.text) || 0)
                                    
                                    // Ensure name is not empty and make it unique
                                    var profileName = shadowNameField.text.trim()
                                    if (profileName === "" || profileName === "Bar Test") {
                                        // Generate unique name with timestamp
                                        var now = new Date()
                                        profileName = "Profile_" + now.getTime().toString().slice(-6)
                                    }
                                    
                                    console.log("Final profile name:", profileName)
                                    
                                    var success = addNewProfile(
                                        shadowTypeField.currentText,
                                        profileName,
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
                                    
                                    if (!success) {
                                        console.log("Error: Failed to add profile")
                                        if (profileController) {
                                            console.log("Last error:", profileController.lastError)
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
