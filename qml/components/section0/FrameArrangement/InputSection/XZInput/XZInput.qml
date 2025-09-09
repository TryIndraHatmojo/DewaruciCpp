import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/*
 * XZInput.qml - Editable Frame XZ Table Component
 * 
 * EDITABLE COLUMNS:
 * - Frame No.: Editable integer input with validation
 * - F. Spacing: Editable integer input with validation  
 * - ML: ComboBox with FORWARD/AFTER options
 * 
 * NAVIGATION FEATURES:
 * - Tab/Shift+Tab: Navigate between editable fields
 * - Arrow Keys: Navigate up/down/left/right between cells
 * - Auto-select text when focusing on input fields
 * - Visual feedback with blue highlight on active focus
 * 
 * FUNCTIONALITY:
 * - Real-time updates to database when values change
 * - Proper input validation for numeric fields
 * - Keyboard navigation similar to spreadsheet behavior
 */

ColumnLayout {
    id: rootXZ
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 10
    
    // Helper function untuk focus + select all
    function focusAndSelect(targetInput) {
        if (targetInput) {
            targetInput.forceActiveFocus()
            if (targetInput.selectAll) {
                targetInput.selectAll()
            }
        }
    }
    
    Component.onCompleted: {
        console.log("XZInput component loaded, loading frame data...")
        frameXZController.getFrameXZList()
    }
    
    Connections {
        target: frameXZController
        function onFrameXZListChanged() {
            console.log("Frame XZ list updated, count:", frameXZController.frameXZList.length)
        }
        function onErrorOccurred(error) {
            console.error("Frame XZ Controller Error:", error)
        }
    }

    // --- Helpers to compute and commit updates for a row (non-shadow) ---
    function getPrevFrameFor(number) {
        var arr = frameXZController.frameXZList || []
        var prev = null
        for (var i = 0; i < arr.length; i++) {
            var it = arr[i]
            if (it && it.frameNumber !== undefined && it.frameNumber < number) {
                if (!prev || it.frameNumber > prev.frameNumber) prev = it
            }
        }
        return prev
    }

    function deriveLensFrom(sample) {
        var lpp = 100.0
        var upperL = 105.0
        if (sample && sample.xpCoor && sample.xl && sample.xpCoor > 0 && sample.xl > 0) {
            lpp = sample.xpCoor / sample.xl
        }
        if (sample && sample.xllCoor && sample.xllLll && sample.xllCoor > 0 && sample.xllLll > 0) {
            upperL = sample.xllCoor / sample.xllLll
        }
        return { lpp: lpp, upperL: upperL }
    }

    function computeCoordsFor(prev, number, spacing) {
        var n = parseInt(number) || 0
        var s = parseInt(spacing) || 0
        var xp = 0.0
        var xll = 0.0
        if (n < 0) {
            // Negative frames: xp from number*spacing
            xp = (n * s) / 1000.0
            xll = xp
        } else if (prev) {
            // Use previous row spacing and xp as base
            var prevXp = parseFloat(prev.xpCoor) || 0.0
            var prevNum = parseInt(prev.frameNumber) || 0
            var prevSpacing = parseInt(prev.frameSpacing) || 0
            var diff = n - prevNum
            if (diff < 0) diff = 0
            xp = prevXp + ((diff * prevSpacing) / 1000.0)
            xll = xp
        } else {
            // First non-negative frame without previous: fall back to number*spacing
            xp = (n * s) / 1000.0
            xll = xp
        }
        var lens = deriveLensFrom(prev)
        var xl = lens.lpp > 0 ? (xp / lens.lpp) : 0.0
        var xllLll = lens.upperL > 0 ? (xll / lens.upperL) : 0.0
        return { xp: xp, xl: xl, xll: xll, xllLll: xllLll }
    }

    function updateRow(id, number, spacing, ml) {
        var n = parseInt(number) || 0
        var s = parseInt(spacing) || 0
        if (id === undefined || s <= 0) return
        var prev = getPrevFrameFor(n)
        var coords = computeCoordsFor(prev, n, s)
        var fname = "Frame " + n
        console.log("updateRow ->", id, fname, n, s, ml, coords.xp, coords.xl, coords.xll, coords.xllLll)
        frameXZController.updateFrameXZ(id, fname, n, s, ml || "FORWARD", coords.xp, coords.xl, coords.xll, coords.xllLll)
    }
    
    RowLayout {
        Layout.fillWidth: true
        
        Text {
            text: "Frame X Z Table"
            font.pixelSize: 14
            font.bold: true
            color: "#34495e"
        }
        
        Item { Layout.fillWidth: true }
        
        Button {
            text: "Add Sample Data"
            font.pixelSize: 10
            background: Rectangle {
                color: "#3498db"
                radius: 4
            }
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                font.pixelSize: parent.font.pixelSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                frameXZController.addSampleData()
            }
        }
        
        Button {
            text: "Reset"
            font.pixelSize: 10
            background: Rectangle {
                color: "#e74c3c"
                radius: 4
            }
            contentItem: Text {
                text: parent.text
                color: "#ffffff"
                font.pixelSize: parent.font.pixelSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: {
                frameXZController.resetFrameXZ()
            }
        }
    }
    
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        border.color: "#ddd"
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            // Header Row for Frame XZ
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#34495e"
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 1
                    
                    property var frameXZHeaders: [
                        "Frame No.", 
                        "F. Spacing\n [mm]", 
                        "ML", 
                        "Xp-Coor\n fr.aft PP [m]", 
                        "X/L", 
                        "XLL-Coor\n fr.aft PLL [m]", 
                        "XLL/LLL", 
                        "Action"
                    ]
                    
                    Repeater {
                        model: parent.frameXZHeaders
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#34495e"
                            border.color: "#ddd"
                            border.width: 1
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
            
            // Data Rows for Frame XZ
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ListView {
                    model: frameXZController.frameXZList
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 35
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#ddd"
                        border.width: 1
                        
                        property var frameData: modelData
                        
                        Component.onCompleted: {
                            if (index === 0) {
                                console.log("First frame data:", JSON.stringify(frameData))
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 1
                            
                            // Frame No
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                
                                TextInput {
                                    id: frameNumberInput
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    text: frameData ? (frameData.frameNumber !== undefined ? frameData.frameNumber.toString() : "0") : "0"
                                    font.pixelSize: 10
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    color: "#2c3e50"
                                    
                                    // Rectangle {
                                    //     anchors.fill: parent
                                    //     color: parent.activeFocus ? "#e3f2fd" : "transparent"
                                    //     border.color: parent.activeFocus ? "#2196f3" : "transparent"
                                    //     border.width: parent.activeFocus ? 1 : 0
                                    //     radius: 2
                                    //     z: -1
                                    // }
                                    
                                    KeyNavigation.tab: frameSpacingInput
                                    KeyNavigation.right: frameSpacingInput
                                    KeyNavigation.left: frameNumberInput
                                    
                                    Keys.onUpPressed: {
                                        if (index > 0) {
                                            var prevItem = parent.parent.parent.parent.parent.itemAt(index - 1)
                                            if (prevItem) {
                                                var prevFrameNumberInput = prevItem.children[0].children[1].children[0].children[0]
                                                focusAndSelect(prevFrameNumberInput)
                                            }
                                        }
                                    }
                                    
                                    Keys.onDownPressed: {
                                        var nextIndex = index + 1
                                        var listView = parent.parent.parent.parent.parent
                                        if (nextIndex < listView.count) {
                                            var nextItem = listView.itemAt(nextIndex)
                                            if (nextItem) {
                                                var nextFrameNumberInput = nextItem.children[0].children[1].children[0].children[0]
                                                focusAndSelect(nextFrameNumberInput)
                                            }
                                        }
                                    }
                                    
                                    Keys.onRightPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = text.length
                                            event.accepted = true
                                        } else if (cursorPosition >= text.length) {
                                            focusAndSelect(frameSpacingInput)
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
                                        if (frameData && frameData.id !== undefined) {
                                            var newNumber = parseInt(text) || 0
                                            if (newNumber !== (frameData.frameNumber || 0)) {
                                                var currentSpacing = parseInt(frameSpacingInput.text) || 0
                                                var currentMl = mlComboBox.currentText
                                                updateRow(frameData.id, newNumber, currentSpacing, currentMl)
                                            }
                                        }
                                    }
                                    
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            selectAll()
                                        }
                                    }
                                }
                            }
                            
                            // F. Spacing
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                
                                TextInput {
                                    id: frameSpacingInput
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    text: frameData ? (frameData.frameSpacing !== undefined ? frameData.frameSpacing.toString() : "0") : "0"
                                    font.pixelSize: 10
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    color: "#2c3e50"
                                    
                                    // Rectangle {
                                    //     anchors.fill: parent
                                    //     color: parent.activeFocus ? "#e3f2fd" : "transparent"
                                    //     border.color: parent.activeFocus ? "#2196f3" : "transparent"
                                    //     border.width: parent.activeFocus ? 1 : 0
                                    //     radius: 2
                                    //     z: -1
                                    // }
                                    
                                    KeyNavigation.tab: mlComboBox
                                    KeyNavigation.backtab: frameNumberInput
                                    KeyNavigation.left: frameNumberInput
                                    KeyNavigation.right: mlComboBox
                                    
                                    Keys.onUpPressed: {
                                        if (index > 0) {
                                            var prevItem = parent.parent.parent.parent.parent.itemAt(index - 1)
                                            if (prevItem) {
                                                var prevFrameSpacingInput = prevItem.children[0].children[1].children[1].children[0]
                                                focusAndSelect(prevFrameSpacingInput)
                                            }
                                        }
                                    }
                                    
                                    Keys.onDownPressed: {
                                        var nextIndex = index + 1
                                        var listView = parent.parent.parent.parent.parent
                                        if (nextIndex < listView.count) {
                                            var nextItem = listView.itemAt(nextIndex)
                                            if (nextItem) {
                                                var nextFrameSpacingInput = nextItem.children[0].children[1].children[1].children[0]
                                                focusAndSelect(nextFrameSpacingInput)
                                            }
                                        }
                                    }
                                    
                                    Keys.onRightPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = text.length
                                            event.accepted = true
                                        } else if (cursorPosition >= text.length) {
                                            mlComboBox.forceActiveFocus()
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
                                            focusAndSelect(frameNumberInput)
                                            event.accepted = true
                                        } else {
                                            event.accepted = false
                                        }
                                    }
                                    
                                    onEditingFinished: {
                                        if (frameData && frameData.id !== undefined) {
                                            var newSpacing = parseInt(text) || 0
                                            if (newSpacing !== (frameData.frameSpacing || 0)) {
                                                var currentNumber = parseInt(frameNumberInput.text) || 0
                                                var currentMl = mlComboBox.currentText
                                                updateRow(frameData.id, currentNumber, newSpacing, currentMl)
                                            }
                                        }
                                    }
                                    
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            selectAll()
                                        }
                                    }
                                }
                            }
                            
                            // ML
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                
                                ComboBox {
                                    id: mlComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: ["FORWARD", "AFTER"]
                                    currentIndex: {
                                        if (!frameData || !frameData.ml) return 0
                                        return frameData.ml === "AFTER" ? 1 : 0
                                    }
                                    font.pixelSize: 9
                                    
                                    KeyNavigation.tab: frameNumberInput
                                    KeyNavigation.backtab: frameSpacingInput
                                    KeyNavigation.left: frameSpacingInput
                                    KeyNavigation.right: frameNumberInput
                                    
                                    Keys.onUpPressed: {
                                        if (index > 0) {
                                            var prevItem = parent.parent.parent.parent.parent.itemAt(index - 1)
                                            if (prevItem) {
                                                var prevMlComboBox = prevItem.children[0].children[1].children[2].children[0]
                                                if (prevMlComboBox) {
                                                    prevMlComboBox.forceActiveFocus()
                                                }
                                            }
                                        }
                                        event.accepted = true
                                    }
                                    
                                    Keys.onDownPressed: {
                                        var nextIndex = index + 1
                                        var listView = parent.parent.parent.parent.parent
                                        if (nextIndex < listView.count) {
                                            var nextItem = listView.itemAt(nextIndex)
                                            if (nextItem) {
                                                var nextMlComboBox = nextItem.children[0].children[1].children[2].children[0]
                                                if (nextMlComboBox) {
                                                    nextMlComboBox.forceActiveFocus()
                                                }
                                            }
                                        }
                                        event.accepted = true
                                    }
                                    
                                    Keys.onLeftPressed: {
                                        focusAndSelect(frameSpacingInput)
                                        event.accepted = true
                                    }
                                    
                                    Keys.onRightPressed: {
                                        // Move to next row's Frame Number
                                        var nextIndex = index + 1
                                        var listView = parent.parent.parent.parent.parent
                                        if (nextIndex < listView.count) {
                                            var nextItem = listView.itemAt(nextIndex)
                                            if (nextItem) {
                                                var nextFrameNumberInput = nextItem.children[0].children[1].children[0].children[0]
                                                focusAndSelect(nextFrameNumberInput)
                                            }
                                        }
                                        event.accepted = true
                                    }
                                    
                                    onCurrentTextChanged: {
                                        if (frameData && frameData.id !== undefined) {
                                            var currentNumber = parseInt(frameNumberInput.text) || 0
                                            var currentSpacing = parseInt(frameSpacingInput.text) || 0
                                            updateRow(frameData.id, currentNumber, currentSpacing, currentText)
                                        }
                                    }
                                }
                            }
                            
                            // Xp-Coor
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (!frameData || frameData.xpCoor === undefined) return "0.000"
                                        return typeof frameData.xpCoor === 'number' ? frameData.xpCoor.toFixed(3) : "0.000"
                                    }
                                    font.pixelSize: 10
                                }
                            }
                            
                            // X/L
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (!frameData || frameData.xl === undefined) return "0.0000"
                                        return typeof frameData.xl === 'number' ? frameData.xl.toFixed(4) : "0.0000"
                                    }
                                    font.pixelSize: 10
                                }
                            }
                            
                            // XLL-Coor
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (!frameData || frameData.xllCoor === undefined) return "0.000"
                                        return typeof frameData.xllCoor === 'number' ? frameData.xllCoor.toFixed(3) : "0.000"
                                    }
                                    font.pixelSize: 10
                                }
                            }
                            
                            // XLL/LLL
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (!frameData || frameData.xllLll === undefined) return "0.0000"
                                        return typeof frameData.xllLll === 'number' ? frameData.xllLll.toFixed(4) : "0.0000"
                                    }
                                    font.pixelSize: 10
                                }
                            }
                            
                            // Action
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#ddd"
                                border.width: 1
                                // Trash icon (like ProfileTable)
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
                                        Rectangle { width: 1; height: 10; color: "white"; anchors.left: parent.left; anchors.leftMargin: 3; anchors.top: parent.top; anchors.topMargin: 2 }
                                        Rectangle { width: 1; height: 10; color: "white"; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 2 }
                                        Rectangle { width: 1; height: 10; color: "white"; anchors.right: parent.right; anchors.rightMargin: 3; anchors.top: parent.top; anchors.topMargin: 2 }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { parent.scale = 1.1 }
                                        onExited: { parent.scale = 1.0 }
                                        onClicked: {
                                            if (frameData && frameData.id !== undefined) {
                                                frameXZController.deleteFrameXZ(frameData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Shadow row footer to add new frame based on last row
                    footer: Rectangle {
                        id: shadowRow
                        width: ListView.view ? ListView.view.width : parent.width
                        height: 38
                        color: "#eef6ff"
                        border.color: "#ddd"
                        border.width: 1

                        // Shadow state (defaults mirror last row)
                        property int shadowFrameNumber: 0
                        property int shadowFrameSpacing: 0
                        property string shadowML: "FORWARD"

                        // Helpers to read last row and compute next coords
                        function lastData() {
                            var arr = frameXZController.frameXZList || []
                            if (!arr || arr.length === 0) return null
                            return arr[arr.length - 1]
                        }

                        function deriveLengthsFrom(last) {
                            // Derive ship lengths from last ratios if available, fallback to controller defaults (100, 105)
                            var lpp = 100.0
                            var upperL = 105.0
                            if (last && last.xpCoor && last.xl && last.xpCoor > 0 && last.xl > 0) {
                                lpp = last.xpCoor / last.xl
                            }
                            if (last && last.xllCoor && last.xllLll && last.xllCoor > 0 && last.xllLll > 0) {
                                upperL = last.xllCoor / last.xllLll
                            }
                            return { lpp: lpp, upperL: upperL }
                        }

                        function autoUpdateFromLastRow() {
                            var last = lastData()
                            if (last) {
                                // Default to next frame number and reuse spacing/ml
                                shadowFrameNumber = (last.frameNumber !== undefined ? parseInt(last.frameNumber) : 0) + 1
                                shadowFrameSpacing = (last.frameSpacing !== undefined ? parseInt(last.frameSpacing) : 1820)
                                shadowML = last.ml || "FORWARD"
                            } else {
                                shadowFrameNumber = 0
                                shadowFrameSpacing = 1820
                                shadowML = "FORWARD"
                            }
                        }

                        function addShadowFrame() {
                            var last = lastData()
                            var spacing = parseInt(shadowFrameSpacing) || 0
                            var number = parseInt(shadowFrameNumber) || 0
                            var mlVal = shadowML || "FORWARD"

                            // Compute coordinates based on last data
                            var xp = 0.0
                            var xll = 0.0
                            if (last) {
                                var lastXp = parseFloat(last.xpCoor) || 0.0
                                var lastXll = parseFloat(last.xllCoor) || 0.0
                                var lastNum = parseInt(last.frameNumber) || 0
                                var diff = number - lastNum
                                if (diff < 0) diff = 0
                                var step = (parseInt(spacing) || 0) / 1000.0
                                xp = lastXp + (diff * step)
                                xll = lastXll + (diff * step)
                            } else {
                                xp = 0.0
                                xll = 0.0
                            }

                            var lens = deriveLengthsFrom(last)
                            var xl = lens.lpp > 0 ? (xp / lens.lpp) : 0.0
                            var xllLll = lens.upperL > 0 ? (xll / lens.upperL) : 0.0

                            var frameName = "Frame " + number

                            console.log("Inserting new FrameXZ via shadow row:", frameName, number, spacing, mlVal, xp, xl, xll, xllLll)
                            frameXZController.insertFrameXZ(frameName, number, spacing, mlVal, xp, xl, xll, xllLll)

                            // After insert, refresh defaults from new last row on list change signal
                            Qt.callLater(function() {
                                // Keep focus in shadow row for rapid entry
                                if (shadowFrameNumberInput) {
                                    shadowFrameNumberInput.forceActiveFocus()
                                    shadowFrameNumberInput.selectAll()
                                }
                            })
                        }

                        Component.onCompleted: autoUpdateFromLastRow()
                        Connections {
                            target: frameXZController
                            function onFrameXZListChanged() { shadowRow.autoUpdateFromLastRow() }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 1
                            spacing: 1

                            // Frame No. (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#ddd"
                                border.width: 1
                                TextInput {
                                    id: shadowFrameNumberInput
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    text: shadowRow.shadowFrameNumber.toString()
                                    font.pixelSize: 10
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) selectAll()
                                    onTextChanged: {
                                        shadowRow.shadowFrameNumber = parseInt(text) || 0
                                    }

                                    KeyNavigation.tab: shadowFrameSpacingInput
                                    KeyNavigation.right: shadowFrameSpacingInput
                                    KeyNavigation.left: shadowFrameNumberInput

                                    Keys.onReturnPressed: shadowRow.addShadowFrame()
                                    Keys.onEnterPressed: shadowRow.addShadowFrame()
                                    Keys.onUpPressed: {
                                        // Focus same column in last data row if exists
                                        var lv = shadowRow.ListView.view
                                        if (lv && lv.count > 0) {
                                            var lastItem = lv.itemAt(lv.count - 1)
                                            if (lastItem) {
                                                var inpt = lastItem.children[0].children[1].children[0].children[0]
                                                if (inpt) { inpt.forceActiveFocus(); inpt.selectAll() }
                                            }
                                        }
                                    }
                                }
                            }

                            // F. Spacing (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#ddd"
                                border.width: 1
                                TextInput {
                                    id: shadowFrameSpacingInput
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    text: shadowRow.shadowFrameSpacing.toString()
                                    font.pixelSize: 10
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) selectAll()
                                    onTextChanged: {
                                        shadowRow.shadowFrameSpacing = parseInt(text) || 0
                                    }

                                    KeyNavigation.tab: shadowMlComboBox
                                    KeyNavigation.backtab: shadowFrameNumberInput
                                    KeyNavigation.left: shadowFrameNumberInput
                                    KeyNavigation.right: shadowMlComboBox

                                    Keys.onReturnPressed: shadowRow.addShadowFrame()
                                    Keys.onEnterPressed: shadowRow.addShadowFrame()
                                    Keys.onUpPressed: {
                                        var lv = shadowRow.ListView.view
                                        if (lv && lv.count > 0) {
                                            var lastItem = lv.itemAt(lv.count - 1)
                                            if (lastItem) {
                                                var inpt = lastItem.children[0].children[1].children[1].children[0]
                                                if (inpt) { inpt.forceActiveFocus(); inpt.selectAll() }
                                            }
                                        }
                                    }
                                }
                            }

                            // ML (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#ddd"
                                border.width: 1
                                ComboBox {
                                    id: shadowMlComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: ["FORWARD", "AFTER"]
                                    currentIndex: shadowRow.shadowML === "AFTER" ? 1 : 0
                                    font.pixelSize: 9

                                    KeyNavigation.tab: shadowAddButton
                                    KeyNavigation.backtab: shadowFrameSpacingInput
                                    KeyNavigation.left: shadowFrameSpacingInput
                                    KeyNavigation.right: shadowAddButton

                                    Keys.onReturnPressed: shadowRow.addShadowFrame()
                                    Keys.onEnterPressed: shadowRow.addShadowFrame()
                                    Keys.onUpPressed: {
                                        var lv = shadowRow.ListView.view
                                        if (lv && lv.count > 0) {
                                            var lastItem = lv.itemAt(lv.count - 1)
                                            if (lastItem) {
                                                var cb = lastItem.children[0].children[1].children[2].children[0]
                                                if (cb) cb.forceActiveFocus()
                                            }
                                        }
                                    }

                                    onCurrentIndexChanged: {
                                        shadowRow.shadowML = currentIndex === 1 ? "AFTER" : "FORWARD"
                                    }
                                }
                            }

                            // Xp-Coor (readonly placeholder)
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f9fbff"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }
                            // X/L
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f9fbff"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }
                            // XLL-Coor
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f9fbff"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }
                            // XLL/LLL
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f9fbff"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }

                            // Action column (Add) styled like ProfileTable
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
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
                                        id: shadowAddMouse
                                        anchors.fill: parent
                                        enabled: (shadowRow.shadowFrameSpacing > 0)
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: shadowRow.addShadowFrame()
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