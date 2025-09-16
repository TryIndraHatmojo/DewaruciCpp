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

    // --- Delegate recalculation and persistence to C++ controller ---
    function updateRow(id, number, spacing, ml) {
        var n = parseInt(number) || 0
        var s = parseInt(spacing) || 0
        if (id === undefined || s <= 0) return
        frameXZController.recalcAndUpdateRow(id, n, s, ml || "FORWARD")
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
                    id: frameList
                    // Track which editable column currently has focus (0: Frame No, 1: F. Spacing, 2: ML)
                    property int focusedColumn: 0
                    model: frameXZController.frameXZList
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 35
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#ddd"
                        border.width: 1
                        
                        property var frameData: modelData

                        // Focus the editor for the given column in this row
                        function focusColumn(col) {
                            if (col === 0) {
                                if (frameNumberInput) { frameNumberInput.forceActiveFocus(); frameNumberInput.selectAll() }
                            } else if (col === 1) {
                                if (frameSpacingInput) { frameSpacingInput.forceActiveFocus(); frameSpacingInput.selectAll() }
                            } else {
                                if (mlComboBox) { mlComboBox.forceActiveFocus() }
                            }
                        }
                        
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
                                    color: "#000000"
                                    
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
                                        frameList.currentIndex = Math.max(0, index - 1)
                                        Qt.callLater(function() {
                                            if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                frameList.currentItem.focusColumn(frameList.focusedColumn)
                                            }
                                        })
                                        event.accepted = true
                                    }

                                    Keys.onDownPressed: {
                                        if (index >= frameList.count - 1) {
                                            // jump to shadow row, same column (Frame No.)
                                            frameList.focusedColumn = 0
                                            if (frameList.footerItem && frameList.footerItem.focusColumn) {
                                                frameList.footerItem.focusColumn(0)
                                            }
                                        } else {
                                            frameList.currentIndex = Math.min(frameList.count - 1, index + 1)
                                            Qt.callLater(function() {
                                                if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                    frameList.currentItem.focusColumn(frameList.focusedColumn)
                                                }
                                            })
                                        }
                                        event.accepted = true
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
                                            frameList.focusedColumn = 0
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
                                    color: "#000000"
                                    
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
                                        frameList.currentIndex = Math.max(0, index - 1)
                                        Qt.callLater(function() {
                                            if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                frameList.currentItem.focusColumn(frameList.focusedColumn)
                                            }
                                        })
                                        event.accepted = true
                                    }

                                    Keys.onDownPressed: {
                                        if (index >= frameList.count - 1) {
                                            // jump to shadow row, same column (F. Spacing)
                                            frameList.focusedColumn = 1
                                            if (frameList.footerItem && frameList.footerItem.focusColumn) {
                                                frameList.footerItem.focusColumn(1)
                                            }
                                        } else {
                                            frameList.currentIndex = Math.min(frameList.count - 1, index + 1)
                                            Qt.callLater(function() {
                                                if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                    frameList.currentItem.focusColumn(frameList.focusedColumn)
                                                }
                                            })
                                        }
                                        event.accepted = true
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
                                            frameList.focusedColumn = 1
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
                                        frameList.currentIndex = Math.max(0, index - 1)
                                        Qt.callLater(function() {
                                            if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                frameList.currentItem.focusColumn(frameList.focusedColumn)
                                            }
                                        })
                                        event.accepted = true
                                    }

                                    Keys.onDownPressed: {
                                        if (index >= frameList.count - 1) {
                                            // jump to shadow row, same column (ML)
                                            frameList.focusedColumn = 2
                                            if (frameList.footerItem && frameList.footerItem.focusColumn) {
                                                frameList.footerItem.focusColumn(2)
                                            }
                                        } else {
                                            frameList.currentIndex = Math.min(frameList.count - 1, index + 1)
                                            Qt.callLater(function() {
                                                if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                    frameList.currentItem.focusColumn(frameList.focusedColumn)
                                                }
                                            })
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
                                    
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            frameList.focusedColumn = 2
                                        }
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
                                color: "#f0f0f0"
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
                                color: "#f0f0f0"
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
                                color: "#f0f0f0"
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
                                color: "#f0f0f0"
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
                            var spacing = parseInt(shadowFrameSpacing) || 0
                            var number = parseInt(shadowFrameNumber) || 0
                            var mlVal = shadowML || "FORWARD"
                            var frameName = "Frame " + number
                            frameXZController.insertWithRecalc(frameName, number, spacing, mlVal)
                            Qt.callLater(function() {
                                if (shadowFrameNumberInput) { shadowFrameNumberInput.forceActiveFocus(); shadowFrameNumberInput.selectAll() }
                            })
                        }

                        // Allow external focus routing (from data row) by column index
                        function focusColumn(col) {
                            if (col === 0) {
                                if (shadowFrameNumberInput) { shadowFrameNumberInput.forceActiveFocus(); shadowFrameNumberInput.selectAll() }
                            } else if (col === 1) {
                                if (shadowFrameSpacingInput) { shadowFrameSpacingInput.forceActiveFocus(); shadowFrameSpacingInput.selectAll() }
                            } else if (col === 2) {
                                if (shadowMlComboBox) { shadowMlComboBox.forceActiveFocus() }
                            }
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
                                    Keys.onRightPressed: {
                                        if (shadowFrameSpacingInput) { shadowFrameSpacingInput.forceActiveFocus(); shadowFrameSpacingInput.selectAll() }
                                        event.accepted = true
                                    }
                                    Keys.onUpPressed: {
                                        if (frameList.count > 0) {
                                            frameList.currentIndex = frameList.count - 1
                                            Qt.callLater(function() {
                                                if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                    frameList.currentItem.focusColumn(0)
                                                }
                                            })
                                        }
                                        event.accepted = true
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
                                    Keys.onLeftPressed: {
                                        if (shadowFrameNumberInput) { shadowFrameNumberInput.forceActiveFocus(); shadowFrameNumberInput.selectAll() }
                                        event.accepted = true
                                    }
                                    Keys.onRightPressed: {
                                        if (shadowMlComboBox) { shadowMlComboBox.forceActiveFocus() }
                                        event.accepted = true
                                    }
                                    Keys.onUpPressed: {
                                        if (frameList.count > 0) {
                                            frameList.currentIndex = frameList.count - 1
                                            Qt.callLater(function() {
                                                if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                    frameList.currentItem.focusColumn(1)
                                                }
                                            })
                                        }
                                        event.accepted = true
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

                                    KeyNavigation.tab: shadowFrameNumberInput
                                    KeyNavigation.backtab: shadowFrameSpacingInput
                                    KeyNavigation.left: shadowFrameSpacingInput
                                    KeyNavigation.right: shadowFrameNumberInput

                                    Keys.onReturnPressed: shadowRow.addShadowFrame()
                                    Keys.onEnterPressed: shadowRow.addShadowFrame()
                                    Keys.onLeftPressed: {
                                        if (shadowFrameSpacingInput) { shadowFrameSpacingInput.forceActiveFocus(); shadowFrameSpacingInput.selectAll() }
                                        event.accepted = true
                                    }
                                    Keys.onRightPressed: {
                                        if (shadowFrameNumberInput) { shadowFrameNumberInput.forceActiveFocus(); shadowFrameNumberInput.selectAll() }
                                        event.accepted = true
                                    }
                                    Keys.onUpPressed: {
                                        if (frameList.count > 0) {
                                            frameList.currentIndex = frameList.count - 1
                                            Qt.callLater(function() {
                                                if (frameList.currentItem && frameList.currentItem.focusColumn) {
                                                    frameList.currentItem.focusColumn(2)
                                                }
                                            })
                                        }
                                        event.accepted = true
                                    }

                                    onCurrentIndexChanged: {
                                        shadowRow.shadowML = currentIndex === 1 ? "AFTER" : "FORWARD"
                                    }
                                }
                            }

                            // Xp-Coor (readonly placeholder)
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f0f0f0"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }
                            // X/L
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f0f0f0"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }
                            // XLL-Coor
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f0f0f0"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }
                            // XLL/LLL
                            Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: "#f0f0f0"; border.color: "#ddd"; border.width: 1; Text { anchors.centerIn: parent; font.pixelSize: 10; text: "" } }

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