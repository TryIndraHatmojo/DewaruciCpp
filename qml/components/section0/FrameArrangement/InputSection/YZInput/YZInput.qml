import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 10
    
    // Signal to notify frame drawing to refresh when data changes
    signal dataChanged()
    
    Text {
        text: "Frame Y Z Table"
        font.pixelSize: 14
        font.bold: true
        color: "#34495e"
    }
    
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        border.color: "#bdc3c7"
        border.width: 1
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            // Header Row for Frame YZ
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#34495e"
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 1
                    
                    property var frameYZHeaders: [
                        "Name", 
                        "No", 
                        "Spacing", 
                        "Y [mm]", 
                        "Z [mm]", 
                        "Frame No.", 
                        "F/A", 
                        "Sym.", 
                        "Action"
                    ]
                    
                    Repeater {
                        model: parent.frameYZHeaders
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#34495e"
                            border.color: "#2c3e50"
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
            
            // Data Rows for Frame YZ
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ListView {
                    id: yzList
                    // Track which editable column currently has focus
                    property int focusedColumn: 0
                    model: frameYZController.frameYZList
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 35
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#bdc3c7"
                        border.width: 0.5

                        // Row data shortcut
                        property var row: modelData

                        // Column dependency validation: Y and Z are mutually exclusive
                        // Y has value if not empty string (0 is valid value)
                        property bool yHasValue: yInput.text !== ""
                        // Z has value if not empty string (0 is valid value)  
                        property bool zHasValue: zInput.text !== ""
                        property bool yEnabled: !zHasValue
                        property bool zEnabled: !yHasValue

                        // Focus a specific column editor in this row
                        function focusColumn(col) {
                            if (col === 0) {
                                if (nameInput) { nameInput.forceActiveFocus(); nameInput.selectAll() }
                            } else if (col === 1) {
                                if (noInput) { noInput.forceActiveFocus(); noInput.selectAll() }
                            } else if (col === 2) {
                                if (spacingInput) { spacingInput.forceActiveFocus(); spacingInput.selectAll() }
                            } else if (col === 3) {
                                if (yInput) { yInput.forceActiveFocus(); yInput.selectAll() }
                            } else if (col === 4) {
                                if (zInput) { zInput.forceActiveFocus(); zInput.selectAll() }
                            } else if (col === 5) {
                                if (frameNoInput) { frameNoInput.forceActiveFocus(); frameNoInput.selectAll() }
                            } else if (col === 6) {
                                if (faComboBox) { faComboBox.forceActiveFocus() }
                            } else if (col === 7) {
                                if (symComboBox) { symComboBox.forceActiveFocus() }
                            }
                        }

                        // Commit row update with current editor values
                        function commitUpdate() {
                            if (!row || !row.id) return
                            var nameVal = nameInput.text
                            var noVal = parseInt(noInput.text)
                            if (isNaN(noVal)) noVal = 0
                            var spacingVal = parseFloat(spacingInput.text)
                            if (isNaN(spacingVal)) spacingVal = 0
                            
                            // Handle Y and Z as strings - empty if not filled, numeric if filled
                            var yVal = yInput.text.trim() === "" ? "" : parseFloat(yInput.text) 
                            var zVal = zInput.text.trim() === "" ? "" : parseFloat(zInput.text)
                            
                            var frameNoVal = parseInt(frameNoInput.text)
                            if (isNaN(frameNoVal)) frameNoVal = 0
                            // Pass FA/Sym as their string labels now
                            var faVal = faComboBox.currentText || (row.fa || "F")
                            var symVal = symComboBox.currentText || (row.sym || "P")
                            frameYZController.updateFrameYZ(row.id, nameVal, noVal, spacingVal, yVal, zVal, frameNoVal, faVal, symVal)
                            
                            // Emit signal to notify drawing refresh needed
                            Qt.callLater(function() {
                                dataChanged()
                            })
                        }

                        function moveHorizontal(dir) {
                            var next = Math.max(0, Math.min(7, yzList.focusedColumn + dir))
                            yzList.focusedColumn = next
                            focusColumn(next)
                        }

                        function moveVertical(dir) {
                            var nextIndex = index + dir
                            if (nextIndex < 0) return
                            if (nextIndex >= yzList.count) {
                                // Move to footer (shadow row) when going down from last row
                                if (yzList.footerItem && yzList.footerItem.focusColumn) {
                                    yzList.footerItem.focusColumn(yzList.focusedColumn)
                                }
                                return
                            }
                            yzList.currentIndex = nextIndex
                            var item = yzList.itemAtIndex(nextIndex)
                            if (item && item.focusColumn) {
                                item.focusColumn(yzList.focusedColumn)
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 1
                            
                            // Name
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: nameInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.name) ? row.name : "L0"
                                    font.pixelSize: 10
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 0 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // No
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: noInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.no !== undefined) ? row.no : "0"
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 1 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // Spacing
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: spacingInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.spacing !== undefined) ? row.spacing : "1"
                                    font.pixelSize: 10
                                    validator: DoubleValidator { bottom: 0; decimals: 3 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 2 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // Y [mm]
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: yEnabled ? "transparent" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: yInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.y !== undefined && row.y !== null && row.y !== "") ? String(row.y) : ""
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: yEnabled
                                    color: yEnabled ? "#000000" : "#999999"
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 3 }
                                    onTextChanged: {
                                        // If Y has value (not empty), clear Z
                                        if (yInput.text !== "" && zInput.text !== "") {
                                            zInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!yEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: if (yEnabled) commitUpdate()
                                }
                            }
                            
                            // Z [mm]
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: zEnabled ? "transparent" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: zInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.z !== undefined && row.z !== null && row.z !== "") ? String(row.z) : ""
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: zEnabled
                                    color: zEnabled ? "#000000" : "#999999"
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 4 }
                                    onTextChanged: {
                                        // If Z has value (not empty), clear Y
                                        if (zInput.text !== "" && yInput.text !== "") {
                                            yInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!zEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: if (zEnabled) commitUpdate()
                                }
                            }
                            
                            // Frame No.
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: frameNoInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.frameNo !== undefined) ? row.frameNo : "24"
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 5 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // F/A
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                ComboBox {
                                    id: faComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "F" }, { name: "A" }, { name: "F+A" } ]
                                    textRole: "name"
                                    // Map existing stored values to index heuristically
                                    Component.onCompleted: {
                                        var val = row ? row.fa : "F"
                                        var idx = 0
                                        if (val === "F" || val === "0") idx = 0
                                        else if (val === "A" || val === "1") idx = 1
                                        else if (val === "F+A" || val === "2") idx = 2
                                        currentIndex = idx
                                    }
                                    font.pixelSize: 9
                                    focusPolicy: Qt.TabFocus
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 6 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onActivated: {
                                        if (row && row.id) frameYZController.updateFrameYZFa(row.id, faComboBox.currentText)
                                    }
                                }
                            }
                            
                            // Sym.
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                ComboBox {
                                    id: symComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "P" }, { name: "S" }, { name: "P+S" } ]
                                    textRole: "name"
                                    Component.onCompleted: {
                                        var val = row ? row.sym : "P"
                                        var idx = 0
                                        if (val === "P" || val === "0") idx = 0
                                        else if (val === "S" || val === "1") idx = 1
                                        else if (val === "P+S" || val === "2") idx = 2
                                        currentIndex = idx
                                    }
                                    font.pixelSize: 9
                                    focusPolicy: Qt.TabFocus
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 7 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { moveHorizontal(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { moveHorizontal(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onActivated: {
                                        if (row && row.id) frameYZController.updateFrameYZSym(row.id, symComboBox.currentText)
                                    }
                                }
                            }
                            
                            // Action
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                // Trash icon (like XZInput)
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
                                            if (row && row.id) { frameYZController.deleteFrameYZ(row.id) }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Shadow row footer to add new frame based on last row
                    footer: Rectangle {
                        id: yzShadowRow
                        width: ListView.view.width
                        height: 38
                        color: "#eef6ff"
                        border.color: "#bdc3c7"
                        border.width: 0.5

                        // Shadow state defaults (mirror last row when possible)
                        property string shadowName: "L0"
                        property int shadowNo: 0
                        property double shadowSpacing: 1
                        property double shadowY: 0
                        property double shadowZ: 0
                        property int shadowFrameNo: 0
                        property string shadowFa: "0"
                        property string shadowSym: "0"

                        // Column dependency validation for shadow row
                        // Y has value if not empty string (0 is valid value)
                        property bool shadowYHasValue: shadowYInput.text !== ""
                        // Z has value if not empty string (0 is valid value)
                        property bool shadowZHasValue: shadowZInput.text !== ""
                        property bool shadowYEnabled: !shadowZHasValue
                        property bool shadowZEnabled: !shadowYHasValue

                        function lastData() {
                            var arr = frameYZController.frameYZList || []
                            if (!arr || arr.length === 0) return null
                            return arr[arr.length - 1]
                        }

                        function autoUpdateFromLastRow() {
                            var last = lastData()
                            if (last) {
                                shadowName = (last.name !== undefined) ? last.name : "L0"
                                shadowNo = (last.no !== undefined) ? (parseInt(last.no) || 0) + 1 : 0
                                shadowSpacing = (last.spacing !== undefined) ? (parseFloat(last.spacing) || 1) : 1
                                shadowY = (last.y !== undefined) ? (parseFloat(last.y) || 0) : 0
                                shadowZ = (last.z !== undefined) ? (parseFloat(last.z) || 0) : 0
                                shadowFrameNo = (last.frameNo !== undefined) ? (parseInt(last.frameNo) || 0) + 1 : 0
                                shadowFa = (last.fa !== undefined) ? ("" + last.fa) : "0"
                                shadowSym = (last.sym !== undefined) ? ("" + last.sym) : "0"
                            } else {
                                shadowName = "L0"
                                shadowNo = 0
                                shadowSpacing = 1
                                shadowY = 0
                                shadowZ = 0
                                shadowFrameNo = 0
                                shadowFa = "0"
                                shadowSym = "0"
                            }
                        }

                        function addShadowRow() {
                            // Use current editor texts (properties kept in sync via onTextChanged)
                            var nameVal = shadowNameInput.text || "L0"
                            var noVal = parseInt(shadowNoInput.text); if (isNaN(noVal)) noVal = 0
                            var spacingVal = parseFloat(shadowSpacingInput.text); if (isNaN(spacingVal)) spacingVal = 0
                            
                            // Handle Y and Z as strings - empty if not filled, numeric if filled
                            var yVal = shadowYInput.text.trim() === "" ? "" : parseFloat(shadowYInput.text)
                            var zVal = shadowZInput.text.trim() === "" ? "" : parseFloat(shadowZInput.text)
                            
                            var frameNoVal = parseInt(shadowFrameNoInput.text); if (isNaN(frameNoVal)) frameNoVal = 0
                            var faVal = shadowFaComboBox.currentText || "F"
                            var symVal = shadowSymComboBox.currentText || "P"
                            frameYZController.insertFrameYZ(nameVal, noVal, spacingVal, yVal, zVal, frameNoVal, faVal, symVal)
                            
                            // Emit signal to notify drawing refresh needed
                            Qt.callLater(function() {
                                dataChanged()
                                if (shadowNameInput) { shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll() }
                            })
                        }

                        // Allow external focus routing (from data row) by column index
                        function focusColumn(col) {
                            if (col === 0) {
                                if (shadowNameInput) { shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll() }
                            } else if (col === 1) {
                                if (shadowNoInput) { shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll() }
                            } else if (col === 2) {
                                if (shadowSpacingInput) { shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll() }
                            } else if (col === 3) {
                                if (shadowYInput) { shadowYInput.forceActiveFocus(); shadowYInput.selectAll() }
                            } else if (col === 4) {
                                if (shadowZInput) { shadowZInput.forceActiveFocus(); shadowZInput.selectAll() }
                            } else if (col === 5) {
                                if (shadowFrameNoInput) { shadowFrameNoInput.forceActiveFocus(); shadowFrameNoInput.selectAll() }
                            } else if (col === 6) {
                                if (shadowFaComboBox) { shadowFaComboBox.forceActiveFocus() }
                            } else if (col === 7) {
                                if (shadowSymComboBox) { shadowSymComboBox.forceActiveFocus() }
                            }
                        }

                        Component.onCompleted: autoUpdateFromLastRow()
                        Connections {
                            target: frameYZController
                            function onFrameYZListChanged() { yzShadowRow.autoUpdateFromLastRow() }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 1

                            // Name (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowNameInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowName
                                    font.pixelSize: 10
                                    selectByMouse: true
                                    onTextChanged: yzShadowRow.shadowName = text
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 1; shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 1; shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 0; last.focusColumn(0) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // No (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowNoInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowNo
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onTextChanged: yzShadowRow.shadowNo = parseInt(text) || 0
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 2; shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 0; shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 2; shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 1; last.focusColumn(1) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Spacing (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowSpacingInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowSpacing
                                    font.pixelSize: 10
                                    validator: DoubleValidator { bottom: 0; decimals: 3 }
                                    selectByMouse: true
                                    onTextChanged: yzShadowRow.shadowSpacing = parseFloat(text) || 0
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 3; shadowYInput.forceActiveFocus(); shadowYInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 1; shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 3; shadowYInput.forceActiveFocus(); shadowYInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 2; last.focusColumn(2) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Y [mm] (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: yzShadowRow.shadowYEnabled ? "#ffffff" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowYInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowY
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: yzShadowRow.shadowYEnabled
                                    color: yzShadowRow.shadowYEnabled ? "#000000" : "#999999"
                                    onTextChanged: {
                                        yzShadowRow.shadowY = parseFloat(text) || 0
                                        // If Y has value (not empty), clear Z
                                        if (shadowYInput.text !== "" && shadowZInput.text !== "") {
                                            shadowZInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!yzShadowRow.shadowYEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 4; shadowZInput.forceActiveFocus(); shadowZInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 2; shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 4; shadowZInput.forceActiveFocus(); shadowZInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 3; last.focusColumn(3) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Z [mm] (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: yzShadowRow.shadowZEnabled ? "#ffffff" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowZInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowZ
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: yzShadowRow.shadowZEnabled
                                    color: yzShadowRow.shadowZEnabled ? "#000000" : "#999999"
                                    onTextChanged: {
                                        yzShadowRow.shadowZ = parseFloat(text) || 0
                                        // If Z has value (not empty), clear Y
                                        if (shadowZInput.text !== "" && shadowYInput.text !== "") {
                                            shadowYInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!yzShadowRow.shadowZEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 5; shadowFrameNoInput.forceActiveFocus(); shadowFrameNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 3; shadowYInput.forceActiveFocus(); shadowYInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 5; shadowFrameNoInput.forceActiveFocus(); shadowFrameNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 4; last.focusColumn(4) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Frame No. (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowFrameNoInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowFrameNo
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onTextChanged: yzShadowRow.shadowFrameNo = parseInt(text) || 0
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 6; shadowFaComboBox.forceActiveFocus(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 4; shadowZInput.forceActiveFocus(); shadowZInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 6; shadowFaComboBox.forceActiveFocus(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 5; last.focusColumn(5) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // F/A (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                ComboBox {
                                    id: shadowFaComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "F" }, { name: "A" }, { name: "F+A" } ]
                                    textRole: "name"
                                    Component.onCompleted: {
                                        var v = yzShadowRow.shadowFa
                                        if (v === "F" || v === "0") currentIndex = 0
                                        else if (v === "A" || v === "1") currentIndex = 1
                                        else if (v === "F+A" || v === "2") currentIndex = 2
                                    }
                                    font.pixelSize: 9
                                    onActivated: { yzShadowRow.shadowFa = shadowFaComboBox.currentText }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 7; shadowSymComboBox.forceActiveFocus(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 5; shadowFrameNoInput.forceActiveFocus(); shadowFrameNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 7; shadowSymComboBox.forceActiveFocus(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 6; last.focusColumn(6) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Sym (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                ComboBox {
                                    id: shadowSymComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "P" }, { name: "S" }, { name: "P+S" } ]
                                    textRole: "name"
                                    Component.onCompleted: {
                                        var v = yzShadowRow.shadowSym
                                        if (v === "P" || v === "0") currentIndex = 0
                                        else if (v === "S" || v === "1") currentIndex = 1
                                        else if (v === "P+S" || v === "2") currentIndex = 2
                                    }
                                    font.pixelSize: 9
                                    onActivated: { yzShadowRow.shadowSym = shadowSymComboBox.currentText }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { /* loop to first column */ yzList.focusedColumn = 0; shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 6; shadowFaComboBox.forceActiveFocus(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 0; shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 7; last.focusColumn(7) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Action column (Add) styled like XZInput
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                border.width: 0.5
                                border.color: "#bdc3c7"
                                color: "#f8f8f8"
                                Text {
                                    anchors.centerIn: parent
                                    text: "Add"
                                    font.pixelSize: 10
                                    color: "#2196F3"
                                    font.bold: true
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: yzShadowRow.addShadowRow()
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