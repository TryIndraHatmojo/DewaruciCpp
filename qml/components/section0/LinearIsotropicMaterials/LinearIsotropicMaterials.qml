import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: parent ? parent.width - 20 : 800  // Width sama dengan parent minus margin 20px (10px kiri + 10px kanan)
    height: parent ? parent.height * 0.45 : 300  // Height 45% dari screen
    anchors.centerIn: parent  // Center dalam parent untuk margin yang merata
    color: "#f5f5f5"
    border.color: "#2196F3"
    border.width: 2
    radius: 8

    property var tableModel: []
    // track updates initiated locally to avoid refreshing and losing focus
    property int _lastLocalUpdatedId: 0
    
    // Flag untuk prevent automatic recalculation during manual resize
    property bool isManuallyResizing: false
    
    // Timer untuk debounce resize calculations
    Timer {
        id: resizeTimer
        interval: 16 // ~60 FPS untuk smooth update
        running: false
        repeat: false
        onTriggered: {
            if (!isManuallyResizing) {
                adjustColumnWidths()
            }
        }
    }
    
    // Property untuk menyimpan lebar kolom yang dapat di-resize
    property var columnWidths: [
        root.width * 0.10,  // Mat. No. - 10%
        root.width * 0.12,  // E-Mod - 12%
        root.width * 0.12,  // G-Mod - 12%
        root.width * 0.12,  // Density - 12%
        root.width * 0.12,  // Y. Stress - 12%
        root.width * 0.12,  // Tensile S. - 12%
        root.width * 0.19,  // Remark - 19%
        root.width * 0.11   // Action - 11%
    ]
    
    // Function untuk memastikan total lebar kolom selalu sama dengan parent width
    function adjustColumnWidths() {
        var targetWidth = root.width - 4  // -4 untuk margin
        var totalWidth = 0
        var minWidth = 50
        
        // Calculate current total width
        for (var i = 0; i < columnWidths.length; i++) {
            totalWidth += columnWidths[i]
        }
        
        // If total width doesn't match target (with 1px tolerance)
        if (Math.abs(totalWidth - targetWidth) > 1) {
            // Recalculate proportionally while respecting minimum widths
            var newColumnWidths = [
                targetWidth * 0.10,  // Mat. No. - 10%
                targetWidth * 0.12,  // E-Mod - 12%
                targetWidth * 0.12,  // G-Mod - 12%
                targetWidth * 0.12,  // Density - 12%
                targetWidth * 0.12,  // Y. Stress - 12%
                targetWidth * 0.12,  // Tensile S. - 12%
                targetWidth * 0.19,  // Remark - 19%
                targetWidth * 0.11   // Action - 11%
            ]
            
            // Apply minimum width constraints
            for (var j = 0; j < newColumnWidths.length; j++) {
                if (newColumnWidths[j] < minWidth) {
                    newColumnWidths[j] = minWidth
                }
            }
            
            // If minimum constraints cause overflow, scale down proportionally
            var totalAfterMin = 0
            for (var k = 0; k < newColumnWidths.length; k++) {
                totalAfterMin += newColumnWidths[k]
            }
            
            if (totalAfterMin > targetWidth) {
                var scaleFactor = targetWidth / totalAfterMin
                for (var l = 0; l < newColumnWidths.length; l++) {
                    var scaledWidth = newColumnWidths[l] * scaleFactor
                    newColumnWidths[l] = Math.max(scaledWidth, minWidth)
                }
            }
            
            columnWidths = newColumnWidths
        }
    }
    
    // Function untuk resize kolom dengan mempertahankan total lebar sama dengan parent
    function resizeColumn(columnIndex, newWidth) {
        var minWidth = 50  // Lebar minimum untuk setiap kolom
        var targetTotalWidth = root.width - 4  // Total lebar yang harus dipertahankan
        
        // Pastikan newWidth tidak kurang dari minimum
        newWidth = Math.max(minWidth, newWidth)
        
        // Calculate current total width
        var currentTotal = 0
        for (var i = 0; i < columnWidths.length; i++) {
            currentTotal += columnWidths[i]
        }
        
        // Calculate the difference from changing this column
        var widthDifference = newWidth - columnWidths[columnIndex]
        var newTotal = currentTotal + widthDifference
        
        var newColumnWidths = columnWidths.slice()
        newColumnWidths[columnIndex] = newWidth
        
        // If total width doesn't match target, redistribute the difference to other columns
        if (Math.abs(newTotal - targetTotalWidth) > 1) { // 1px tolerance
            var redistributionAmount = targetTotalWidth - newTotal
            var redistributableColumns = []
            
            // Find columns that can be redistributed (excluding the column being resized)
            for (var j = 0; j < newColumnWidths.length; j++) {
                if (j !== columnIndex) {
                    redistributableColumns.push(j)
                }
            }
            
            if (redistributableColumns.length > 0) {
                var amountPerColumn = redistributionAmount / redistributableColumns.length
                
                // Redistribute the difference among other columns
                for (var k = 0; k < redistributableColumns.length; k++) {
                    var colIndex = redistributableColumns[k]
                    var newColWidth = newColumnWidths[colIndex] + amountPerColumn
                    
                    // Ensure the redistributed width doesn't go below minimum
                    newColumnWidths[colIndex] = Math.max(newColWidth, minWidth)
                }
            }
        }
        
        // Update columnWidths
        root.columnWidths = newColumnWidths
    }
    
    // Handler untuk auto-recalculate column widths ketika table width berubah
    onWidthChanged: {
        if (width > 0 && !isManuallyResizing) {
            // Use timer to debounce rapid resize events
            resizeTimer.restart()
        }
    }

    // Component.onCompleted untuk load data dari database
    Component.onCompleted: {
        refreshData()
    }
    
    // Function untuk refresh data dari database
    function refreshData() {
        var api = materialsApi()
        if (api) {
            var materials = api.getAllMaterialsForQML()
            // Validasi data - pastikan setiap item memiliki id
            var validMaterials = []
            for (var i = 0; i < materials.length; i++) {
                if (materials[i] && materials[i].id !== undefined) {
                    validMaterials.push(materials[i])
                } else {
                    console.warn("Skipping invalid material data at index", i)
                }
            }
            tableModel = validMaterials
            console.log("Loaded", validMaterials.length, "valid materials from database")
        } else {
            console.log("Material model not available, using sample data")
            tableModel = [] // Set ke array kosong jika model tidak tersedia
        }
    }

    // Helper untuk memilih API controller vs model
    function materialsApi() {
        return materialController ? materialController : (materialModel ? materialModel : null)
    }
    
    // Helper function untuk focus + select all
    function focusAndSelect(targetInput) {
        targetInput.forceActiveFocus()
        targetInput.selectAll()
    }

    // Track the globally active focus item; when a TextInput is focused,
    // disable the ScrollView/flickable interactive behavior so arrow keys
    // do not scroll the view while editing.
    property var activeFocusedItem: Qt.application.activeFocusItem
    onActiveFocusedItemChanged: {
        try {
            var af = activeFocusedItem
            // Detect TextInput-like objects by presence of cursorPosition property
            var isTextInput = af && af.cursorPosition !== undefined
            if (scrollView && scrollView.contentItem) {
                scrollView.contentItem.interactive = !isTextInput
            }
        } catch (e) {
            // ignore runtime errors
            console.warn('Error toggling scroll interactivity:', e)
        }
    }

    // Centralized helper to focus a specific cell by row and column index
    // colIndex mapping: 0=MatNo,1=E-Mod,2=G-Mod,3=Density,4=Y.Stress,5=Tensile,6=Remark
    function focusCell(rowIdx, colIdx) {
        if (rowIdx < 0) return
        if (colIdx < 1) colIdx = 1 // first editable column is 1
        if (materialRepeater && materialRepeater.count > rowIdx) {
            var row = materialRepeater.itemAt(rowIdx)
            if (!row) return
            // children layout: 0=MatNo,1=E-Mod,2=G-Mod,3=Density,4=YieldStress,5=Tensile,6=Remark,7=Action
            var cell = row.children[colIdx]
            if (cell && cell.children && cell.children[0]) {
                var input = cell.children[0]
                input.forceActiveFocus()
                input.selectAll()
            }
        }
    }
    
    // Function untuk delete material
    function deleteMaterial(index, materialId) {
        var api = materialsApi()
        if (api) {
            if (api.removeMaterial(materialId)) {
                console.log("Material deleted successfully")
                refreshData() // Refresh data setelah delete
            } else {
                console.log("Failed to delete material:", api.getLastError())
            }
        }
    }
    
    // Function untuk add material baru dari shadow row
    function addNewMaterial(eModulus, gModulus, density, yieldStress, tensileStrength, remark) {
        var api = materialsApi()
        if (api) {
            if (api.addMaterial(eModulus, gModulus, density, yieldStress, tensileStrength, remark)) {
                console.log("New material added successfully")
                refreshData() // Refresh data setelah add
                // Reset shadow row ke nilai default
                resetShadowRow()
            } else {
                console.log("Failed to add material:", api.getLastError())
            }
        }
    }
    
    // Function untuk reset shadow row ke data terakhir
    function resetShadowRow() {
        var api = materialsApi()
        if (api) {
            var materials = api.getAllMaterialsForQML()
            if (materials.length > 0) {
                var lastMaterial = materials[materials.length - 1]
                shadowRow.resetToLastData(lastMaterial)
            }
        }
    }

    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: "#2196F3"
        radius: 6
        
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 6
            color: "#2196F3"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 0

            Text {
                text: "Linear Isotropic Materials"
                color: "white"
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            // Help button (question mark icon)
            Rectangle {
                width: 24
                height: 24
                color: "transparent"
                border.color: "white"
                border.width: 2
                radius: 12

                Text {
                    anchors.centerIn: parent
                    text: "?"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Help for Linear Isotropic Materials")
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
            height: 35
            clip: true  // Clip jika melebihi container

            Rectangle {
                width: root.columnWidths[0]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Mat. No."
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }
                
                // Resize handle
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 4
                    color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startX
                        property real startWidth
                        
                        onPressed: {
                            isManuallyResizing = true
                            startX = mouse.x
                            startWidth = parent.parent.width
                        }
                        
                        onReleased: {
                            isManuallyResizing = false
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouse.x - startX
                                var newWidth = Math.max(50, startWidth + delta)
                                root.resizeColumn(0, newWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: root.columnWidths[1]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "E-Mod\n[kN/mm²]"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Resize handle
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 4
                    color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startX
                        property real startWidth
                        
                        onPressed: {
                            isManuallyResizing = true
                            startX = mouse.x
                            startWidth = parent.parent.width
                        }
                        
                        onReleased: {
                            isManuallyResizing = false
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouse.x - startX
                                var newWidth = Math.max(50, startWidth + delta)
                                root.resizeColumn(1, newWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: root.columnWidths[2]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "G-Mod\n[kN/mm²]"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Resize handle
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 4
                    color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startX
                        property real startWidth
                        
                        onPressed: {
                            isManuallyResizing = true
                            startX = mouse.x
                            startWidth = parent.parent.width
                        }
                        
                        onReleased: {
                            isManuallyResizing = false
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouse.x - startX
                                var newWidth = Math.max(50, startWidth + delta)
                                root.resizeColumn(2, newWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: root.columnWidths[3]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "M. Density\n[kg/m³]"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Resize handle
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 4
                    color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startX
                        property real startWidth
                        
                        onPressed: {
                            isManuallyResizing = true
                            startX = mouse.x
                            startWidth = parent.parent.width
                        }
                        
                        onReleased: {
                            isManuallyResizing = false
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouse.x - startX
                                var newWidth = Math.max(50, startWidth + delta)
                                root.resizeColumn(3, newWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: root.columnWidths[4]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Y. Stress\n[N/mm²]"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Resize handle
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 4
                    color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startX
                        property real startWidth
                        
                        onPressed: {
                            isManuallyResizing = true
                            startX = mouse.x
                            startWidth = parent.parent.width
                        }
                        
                        onReleased: {
                            isManuallyResizing = false
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouse.x - startX
                                var newWidth = Math.max(50, startWidth + delta)
                                root.resizeColumn(4, newWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: root.columnWidths[5]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Tensile S.\n[N/mm²]"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Resize handle
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 4
                    color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startX
                        property real startWidth
                        
                        onPressed: {
                            isManuallyResizing = true
                            startX = mouse.x
                            startWidth = parent.parent.width
                        }
                        
                        onReleased: {
                            isManuallyResizing = false
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouse.x - startX
                                var newWidth = Math.max(50, startWidth + delta)
                                root.resizeColumn(5, newWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: root.columnWidths[6]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Remark"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                
                // Resize handle
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: parent.height - 4
                    color: "transparent"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        
                        property real startX
                        property real startWidth
                        
                        onPressed: {
                            isManuallyResizing = true
                            startX = mouse.x
                            startWidth = parent.parent.width
                        }
                        
                        onReleased: {
                            isManuallyResizing = false
                        }
                        
                        onPositionChanged: {
                            if (pressed) {
                                var delta = mouse.x - startX
                                var newWidth = Math.max(50, startWidth + delta)
                                root.resizeColumn(6, newWidth)
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: root.columnWidths[7]
                height: parent.height
                color: "#1e4a6b"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Action"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
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
            // Prevent ScrollView from taking keyboard focus; let children handle keys
            focusPolicy: Qt.NoFocus
            
            // Hanya scroll vertical
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: scrollView.width
                
                // Fungsi untuk menghitung total lebar kolom
                function getTotalColumnWidth() {
                    var total = 0
                    for (var i = 0; i < columnWidths.length; i++) {
                        total += columnWidths[i]
                    }
                    return Math.min(total, scrollView.width)  // Pastikan tidak melebihi container
                }
                
                // Data rows
                Repeater {
                    id: materialRepeater
                    model: root.tableModel
                    delegate: Row {
                        property int rowIndex: index
                        property bool isEven: index % 2 === 0
                        property var materialData: modelData || {}
                        width: parent.width  // Batasi lebar sesuai parent
                        clip: true  // Clip jika melebihi container
                        
                        function updateMaterial() {
                            var api = materialsApi()
                            if (!api || !materialData.id) return

                            // Read new values from inputs
                            var newEM = parseInt(eModInput.text) || 0
                            var newG = parseInt(gModInput.text) || 0
                            var newDensity = parseInt(densityInput.text) || 0
                            var newYield = parseInt(yieldStressInput.text) || 0
                            var newTensile = parseInt(tensileStrengthInput.text) || 0
                            var newRemark = remarkInput.text || ""

                            // Normalize existing values for comparison
                            var oldEM = materialData.eMod !== undefined ? (parseInt(materialData.eMod) || 0) : 0
                            var oldG = materialData.gMod !== undefined ? (parseInt(materialData.gMod) || 0) : 0
                            var oldDensity = materialData.density !== undefined ? (parseInt(materialData.density) || 0) : 0
                            var oldYield = materialData.yieldStress !== undefined ? (parseInt(materialData.yieldStress) || 0) : 0
                            var oldTensile = materialData.tensileStrength !== undefined ? (parseInt(materialData.tensileStrength) || 0) : 0
                            var oldRemark = materialData.remark !== undefined ? materialData.remark : ""

                            // If nothing changed, skip update/commit
                            if (newEM === oldEM && newG === oldG && newDensity === oldDensity &&
                                newYield === oldYield && newTensile === oldTensile && newRemark === oldRemark) {
                                // no change -> do nothing
                                return
                            }

                            // Mark this id as locally-updated so Connections handler can ignore the following signal
                            root._lastLocalUpdatedId = materialData.id

                            var success = api.updateMaterial(
                                materialData.id,
                                newEM,
                                newG,
                                newDensity,
                                newYield,
                                newTensile,
                                newRemark
                            )
                            if (success) {
                                console.log("Material updated successfully")
                                // Update the in-memory materialData so UI stays consistent without a full refresh
                                materialData.eMod = newEM
                                materialData.gMod = newG
                                materialData.density = newDensity
                                materialData.yieldStress = newYield
                                materialData.tensileStrength = newTensile
                                materialData.remark = newRemark
                                // leave focus where it is; Connections will ignore the matching update signal
                            } else {
                                console.log("Failed to update material:", api.getLastError ? api.getLastError() : "unknown")
                                // Clear the local marker on failure
                                if (root._lastLocalUpdatedId === materialData.id) root._lastLocalUpdatedId = 0
                            }
                        }

                        // Mat No - Disabled (Abu-abu)
                        Rectangle {
                            width: root.columnWidths[0]
                            height: 30
                            color: "#e0e0e0" // Abu-abu untuk disabled
                            border.color: "#ddd"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: (rowIndex + 1).toString() // Auto increment Mat No
                                font.pixelSize: 11
                                color: "#666" // Warna teks abu-abu
                            }
                        }

                        // E-Modulus - Editable Number Input
                        Rectangle {
                            width: root.columnWidths[1]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: eModInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: materialData.eMod || ""
                                font.pixelSize: 11
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: IntValidator { bottom: 0 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: gModInput
                                KeyNavigation.backtab: remarkInput // Previous row's last cell or this row's last cell
                                KeyNavigation.up: eModInput // Will be set dynamically to previous row
                                KeyNavigation.down: eModInput // Will be set dynamically to next row
                                KeyNavigation.left: eModInput // Stay in same cell (first column)
                                KeyNavigation.right: gModInput
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        root.focusCell(rowIndex - 1, 1)
                                        event.accepted = true
                                    }
                                }

                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        root.focusCell(rowIndex + 1, 1)
                                        event.accepted = true
                                    } else {
                                        shadowEModInput.forceActiveFocus()
                                        shadowEModInput.selectAll()
                                        event.accepted = true
                                    }
                                }

                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        root.focusCell(rowIndex, 2)
                                        event.accepted = true
                                    } else {
                                        // move cursor right inside the input and consume event
                                        cursorPosition = Math.min(text.length, cursorPosition + 1)
                                        event.accepted = true
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
                                        // move cursor left inside the input and consume event
                                        cursorPosition = Math.max(0, cursorPosition - 1)
                                        event.accepted = true
                                    }
                                }
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // G-Modulus - Editable Number Input
                        Rectangle {
                            width: root.columnWidths[2]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: gModInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: materialData.gMod || ""
                                font.pixelSize: 11
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: IntValidator { bottom: 0 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: densityInput
                                KeyNavigation.backtab: eModInput
                                KeyNavigation.left: eModInput
                                KeyNavigation.right: densityInput
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        root.focusCell(rowIndex - 1, 2)
                                        event.accepted = true
                                    }
                                }

                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        root.focusCell(rowIndex + 1, 2)
                                        event.accepted = true
                                    } else {
                                        shadowGModInput.forceActiveFocus()
                                        shadowGModInput.selectAll()
                                        event.accepted = true
                                    }
                                }

                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        root.focusCell(rowIndex, 1)
                                        event.accepted = true
                                    } else {
                                        cursorPosition = Math.max(0, cursorPosition - 1)
                                        event.accepted = true
                                    }
                                }

                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        root.focusCell(rowIndex, 3)
                                        event.accepted = true
                                    } else {
                                        cursorPosition = Math.min(text.length, cursorPosition + 1)
                                        event.accepted = true
                                    }
                                }
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Density - Editable Number Input
                        Rectangle {
                            width: root.columnWidths[3]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: densityInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: materialData.density || ""
                                font.pixelSize: 11
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: IntValidator { bottom: 0 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: yieldStressInput
                                KeyNavigation.backtab: gModInput
                                KeyNavigation.left: gModInput
                                KeyNavigation.right: yieldStressInput
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        root.focusCell(rowIndex - 1, 3)
                                        event.accepted = true
                                    }
                                }

                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        root.focusCell(rowIndex + 1, 3)
                                        event.accepted = true
                                    } else {
                                        shadowDensityInput.forceActiveFocus()
                                        shadowDensityInput.selectAll()
                                        event.accepted = true
                                    }
                                }

                                Keys.onLeftPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = 0
                                            event.accepted = true
                                        } else if (cursorPosition <= 0) {
                                            root.focusCell(rowIndex, 2)
                                            event.accepted = true
                                        } else {
                                            cursorPosition = Math.max(0, cursorPosition - 1)
                                            event.accepted = true
                                        }
                                }

                                Keys.onRightPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = text.length
                                            event.accepted = true
                                        } else if (cursorPosition >= text.length) {
                                            root.focusCell(rowIndex, 4)
                                            event.accepted = true
                                        } else {
                                            cursorPosition = Math.min(text.length, cursorPosition + 1)
                                            event.accepted = true
                                        }
                                }
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Yield Stress - Editable Number Input
                        Rectangle {
                            width: root.columnWidths[4]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: yieldStressInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: materialData.yieldStress || ""
                                font.pixelSize: 11
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: IntValidator { bottom: 0 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: tensileStrengthInput
                                KeyNavigation.backtab: densityInput
                                KeyNavigation.left: densityInput
                                KeyNavigation.right: tensileStrengthInput
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        root.focusCell(rowIndex - 1, 4)
                                        event.accepted = true
                                    }
                                }

                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        root.focusCell(rowIndex + 1, 4)
                                        event.accepted = true
                                    } else {
                                        shadowYieldStressInput.forceActiveFocus()
                                        shadowYieldStressInput.selectAll()
                                        event.accepted = true
                                    }
                                }

                                Keys.onLeftPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = 0
                                            event.accepted = true
                                        } else if (cursorPosition <= 0) {
                                            root.focusCell(rowIndex, 3)
                                            event.accepted = true
                                        } else {
                                            cursorPosition = Math.max(0, cursorPosition - 1)
                                            event.accepted = true
                                        }
                                }

                                Keys.onRightPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = text.length
                                            event.accepted = true
                                        } else if (cursorPosition >= text.length) {
                                            root.focusCell(rowIndex, 5)
                                            event.accepted = true
                                        } else {
                                            cursorPosition = Math.min(text.length, cursorPosition + 1)
                                            event.accepted = true
                                        }
                                }
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Tensile Strength - Editable Number Input
                        Rectangle {
                            width: root.columnWidths[5]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: tensileStrengthInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: materialData.tensileStrength || ""
                                font.pixelSize: 11
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                validator: IntValidator { bottom: 0 }
                                selectByMouse: true
                                
                                KeyNavigation.tab: remarkInput
                                KeyNavigation.backtab: yieldStressInput
                                KeyNavigation.left: yieldStressInput
                                KeyNavigation.right: remarkInput
                                Keys.onUpPressed: {
                                    if (rowIndex > 0) {
                                        root.focusCell(rowIndex - 1, 5)
                                        event.accepted = true
                                    }
                                }

                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        root.focusCell(rowIndex + 1, 5)
                                        event.accepted = true
                                    } else {
                                        shadowTensileStrengthInput.forceActiveFocus()
                                        shadowTensileStrengthInput.selectAll()
                                        event.accepted = true
                                    }
                                }

                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        root.focusCell(rowIndex, 4)
                                        event.accepted = true
                                    } else {
                                        // move cursor left within this input
                                        cursorPosition = Math.max(0, cursorPosition - 1)
                                        event.accepted = true
                                    }
                                }

                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        root.focusCell(rowIndex, 6)
                                        event.accepted = true
                                    } else {
                                        // move cursor right within this input
                                        cursorPosition = Math.min(text.length, cursorPosition + 1)
                                        event.accepted = true
                                    }
                                }
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Remark - Editable Text Input
                        Rectangle {
                            width: root.columnWidths[6]
                            height: 30
                            color: parent.isEven ? "white" : "#f9f9f9"
                            border.color: "#ddd"
                            border.width: 1
                            
                            TextInput {
                                id: remarkInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: materialData.remark || ""
                                font.pixelSize: 11
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                
                                // Tab akan pindah ke row berikutnya, kolom pertama
                                KeyNavigation.backtab: tensileStrengthInput
                                KeyNavigation.left: tensileStrengthInput
                                
                                Keys.onUpPressed: {
                                        if (rowIndex > 0) {
                                            root.focusCell(rowIndex - 1, 6)
                                            event.accepted = true
                                        }
                                }
                                
                                Keys.onDownPressed: {
                                        if (rowIndex < materialRepeater.count - 1) {
                                            root.focusCell(rowIndex + 1, 6)
                                            event.accepted = true
                                        } else {
                                            shadowRemarkInput.forceActiveFocus()
                                            shadowRemarkInput.selectAll()
                                            event.accepted = true
                                        }
                                }
                                
                                Keys.onLeftPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = 0
                                            event.accepted = true
                                        } else if (cursorPosition <= 0) {
                                            tensileStrengthInput.forceActiveFocus()
                                            tensileStrengthInput.selectAll()
                                            event.accepted = true
                                        } else {
                                            cursorPosition = Math.max(0, cursorPosition - 1)
                                            event.accepted = true
                                        }
                                }
                                
                                Keys.onRightPressed: {
                                        if (selectedText.length > 0) {
                                            cursorPosition = text.length
                                            event.accepted = true
                                        } else if (cursorPosition >= text.length) {
                                            // Stay in last column - move cursor to end
                                            cursorPosition = text.length
                                            event.accepted = true
                                        } else {
                                            cursorPosition = Math.min(text.length, cursorPosition + 1)
                                            event.accepted = true
                                        }
                                }
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Action - Delete Button
                        Rectangle {
                            width: root.columnWidths[7]
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
                                        // Navigate to the Row that contains materialData
                                        // MouseArea -> Rectangle (trash icon) -> Rectangle (action column) -> Row
                                        var parentRow = parent.parent.parent
                                        
                                        console.log("Delete clicked - checking parent hierarchy:")
                                        console.log("parentRow:", parentRow)
                                        console.log("parentRow.materialData:", parentRow ? parentRow.materialData : "no parent")
                                        
                                        if (parentRow && parentRow.materialData && parentRow.materialData.id !== undefined) {
                                            var materialId = parentRow.materialData.id
                                            var rowIndex = parentRow.rowIndex !== undefined ? parentRow.rowIndex : index
                                            console.log("Deleting material with ID:", materialId, "at row:", rowIndex)
                                            root.deleteMaterial(rowIndex, materialId)
                                        } else {
                                            console.log("Cannot delete: material data not available or id is undefined")
                                            if (parentRow) {
                                                console.log("Available properties:", Object.keys(parentRow))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Shadow Row untuk menambah data baru
                Row {
                    id: shadowRow
                    property bool isShadowRow: true
                    width: parent.width  // Batasi lebar sesuai parent
                    clip: true  // Clip jika melebihi container
                    
                    function resetToLastData(lastMaterial) {
                        shadowEModInput.text = lastMaterial.eMod || ""
                        shadowGModInput.text = lastMaterial.gMod || ""
                        shadowDensityInput.text = lastMaterial.density || ""
                        shadowYieldStressInput.text = lastMaterial.yieldStress || ""
                        shadowTensileStrengthInput.text = lastMaterial.tensileStrength || ""
                        shadowRemarkInput.text = lastMaterial.remark || ""
                    }
                    
                    function addMaterial() {
                        var eModValue = parseInt(shadowEModInput.text) || 0
                        var gModValue = parseInt(shadowGModInput.text) || 0
                        var densityValue = parseInt(shadowDensityInput.text) || 0
                        var yieldStressValue = parseInt(shadowYieldStressInput.text) || 0
                        var tensileStrengthValue = parseInt(shadowTensileStrengthInput.text) || 0
                        var remarkValue = shadowRemarkInput.text || ""
                        
                        root.addNewMaterial(eModValue, gModValue, densityValue, yieldStressValue, tensileStrengthValue, remarkValue)
                    }
                    
                    Component.onCompleted: {
                        // Initialize shadow row dengan data terakhir setelah data load
                        root.resetShadowRow()
                    }

                    // Mat No - Shadow (Auto increment)
                    Rectangle {
                        width: root.columnWidths[0]
                        height: 30
                        color: "#f0f0f0" // Abu-abu terang untuk shadow
                        border.color: "#ddd"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: root.tableModel ? (root.tableModel.length + 1).toString() : "1"
                            font.pixelSize: 11
                            color: "#888"
                            font.italic: true
                        }
                    }

                    // E-Modulus - Shadow Input
                    Rectangle {
                        width: root.columnWidths[1]
                        height: 30
                        color: "#f8f8f8" // Abu-abu terang
                        border.color: "#ddd"
                        border.width: 1
                        
                        TextInput {
                            id: shadowEModInput
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 11
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            validator: IntValidator { bottom: 0 }
                            selectByMouse: true
                            color: "#666"
                            
                            KeyNavigation.tab: shadowGModInput
                            KeyNavigation.right: shadowGModInput
                            
                            Keys.onUpPressed: {
                                if (materialRepeater.count > 0) {
                                    var lastRow = materialRepeater.itemAt(materialRepeater.count - 1)
                                    if (lastRow && lastRow.children[1] && lastRow.children[1].children[0]) {
                                        lastRow.children[1].children[0].forceActiveFocus()
                                        lastRow.children[1].children[0].selectAll()
                                    }
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    shadowGModInput.forceActiveFocus()
                                    shadowGModInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.min(text.length, cursorPosition + 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onLeftPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = 0
                                    event.accepted = true
                                } else if (cursorPosition <= 0) {
                                    // Stay in first column - move cursor to beginning  
                                    cursorPosition = 0
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.max(0, cursorPosition - 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // G-Modulus - Shadow Input
                    Rectangle {
                        width: root.columnWidths[2]
                        height: 30
                        color: "#f8f8f8"
                        border.color: "#ddd"
                        border.width: 1
                        
                        TextInput {
                            id: shadowGModInput
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 11
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            validator: IntValidator { bottom: 0 }
                            selectByMouse: true
                            color: "#666"
                            
                            KeyNavigation.tab: shadowDensityInput
                            KeyNavigation.backtab: shadowEModInput
                            KeyNavigation.left: shadowEModInput
                            KeyNavigation.right: shadowDensityInput
                            
                            Keys.onUpPressed: {
                                if (materialRepeater.count > 0) {
                                    var lastRow = materialRepeater.itemAt(materialRepeater.count - 1)
                                    if (lastRow && lastRow.children[2] && lastRow.children[2].children[0]) {
                                        lastRow.children[2].children[0].forceActiveFocus()
                                        lastRow.children[2].children[0].selectAll()
                                    }
                                }
                            }
                            
                            Keys.onLeftPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = 0
                                    event.accepted = true
                                } else if (cursorPosition <= 0) {
                                    shadowEModInput.forceActiveFocus()
                                    shadowEModInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.max(0, cursorPosition - 1)
                                    event.accepted = true  // consume
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    shadowDensityInput.forceActiveFocus()
                                    shadowDensityInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.min(text.length, cursorPosition + 1)
                                    event.accepted = true  // consume
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Density - Shadow Input
                    Rectangle {
                        width: root.columnWidths[3]
                        height: 30
                        color: "#f8f8f8"
                        border.color: "#ddd"
                        border.width: 1
                        
                        TextInput {
                            id: shadowDensityInput
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 11
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            validator: IntValidator { bottom: 0 }
                            selectByMouse: true
                            color: "#666"
                            
                            KeyNavigation.tab: shadowYieldStressInput
                            KeyNavigation.backtab: shadowGModInput
                            KeyNavigation.left: shadowGModInput
                            KeyNavigation.right: shadowYieldStressInput
                            
                            Keys.onUpPressed: {
                                if (materialRepeater.count > 0) {
                                    var lastRow = materialRepeater.itemAt(materialRepeater.count - 1)
                                    if (lastRow && lastRow.children[3] && lastRow.children[3].children[0]) {
                                        lastRow.children[3].children[0].forceActiveFocus()
                                        lastRow.children[3].children[0].selectAll()
                                    }
                                }
                            }
                            
                            Keys.onLeftPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = 0
                                    event.accepted = true
                                } else if (cursorPosition <= 0) {
                                    shadowGModInput.forceActiveFocus()
                                    shadowGModInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.max(0, cursorPosition - 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    shadowYieldStressInput.forceActiveFocus()
                                    shadowYieldStressInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.min(text.length, cursorPosition + 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Yield Stress - Shadow Input
                    Rectangle {
                        width: root.columnWidths[4]
                        height: 30
                        color: "#f8f8f8"
                        border.color: "#ddd"
                        border.width: 1
                        
                        TextInput {
                            id: shadowYieldStressInput
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 11
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            validator: IntValidator { bottom: 0 }
                            selectByMouse: true
                            color: "#666"
                            
                            KeyNavigation.tab: shadowTensileStrengthInput
                            KeyNavigation.backtab: shadowDensityInput
                            KeyNavigation.left: shadowDensityInput
                            KeyNavigation.right: shadowTensileStrengthInput
                            
                            Keys.onUpPressed: {
                                if (materialRepeater.count > 0) {
                                    var lastRow = materialRepeater.itemAt(materialRepeater.count - 1)
                                    if (lastRow && lastRow.children[4] && lastRow.children[4].children[0]) {
                                        lastRow.children[4].children[0].forceActiveFocus()
                                        lastRow.children[4].children[0].selectAll()
                                    }
                                }
                            }
                            
                            Keys.onLeftPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = 0
                                    event.accepted = true
                                } else if (cursorPosition <= 0) {
                                    shadowDensityInput.forceActiveFocus()
                                    shadowDensityInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.max(0, cursorPosition - 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    shadowTensileStrengthInput.forceActiveFocus()
                                    shadowTensileStrengthInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.min(text.length, cursorPosition + 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Tensile Strength - Shadow Input
                    Rectangle {
                        width: root.columnWidths[5]
                        height: 30
                        color: "#f8f8f8"
                        border.color: "#ddd"
                        border.width: 1
                        
                        TextInput {
                            id: shadowTensileStrengthInput
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 11
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            validator: IntValidator { bottom: 0 }
                            selectByMouse: true
                            color: "#666"
                            
                            KeyNavigation.tab: shadowRemarkInput
                            KeyNavigation.backtab: shadowYieldStressInput
                            KeyNavigation.left: shadowYieldStressInput
                            KeyNavigation.right: shadowRemarkInput
                            
                            Keys.onUpPressed: {
                                if (materialRepeater.count > 0) {
                                    var lastRow = materialRepeater.itemAt(materialRepeater.count - 1)
                                    if (lastRow && lastRow.children[5] && lastRow.children[5].children[0]) {
                                        lastRow.children[5].children[0].forceActiveFocus()
                                    }
                                }
                            }
                            
                            Keys.onLeftPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = 0
                                    event.accepted = true
                                } else if (cursorPosition <= 0) {
                                    shadowYieldStressInput.forceActiveFocus()
                                    shadowYieldStressInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.max(0, cursorPosition - 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    shadowRemarkInput.forceActiveFocus()
                                    shadowRemarkInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.min(text.length, cursorPosition + 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Remark - Shadow Input
                    Rectangle {
                        width: root.columnWidths[6]
                        height: 30
                        color: "#f8f8f8"
                        border.color: "#ddd"
                        border.width: 1
                        
                        TextInput {
                            id: shadowRemarkInput
                            anchors.fill: parent
                            anchors.margins: 2
                            font.pixelSize: 11
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            color: "#666"
                            
                            KeyNavigation.tab: shadowEModInput
                            KeyNavigation.backtab: shadowTensileStrengthInput
                            KeyNavigation.left: shadowTensileStrengthInput
                            
                            Keys.onUpPressed: {
                                if (materialRepeater.count > 0) {
                                    var lastRow = materialRepeater.itemAt(materialRepeater.count - 1)
                                    if (lastRow && lastRow.children[6] && lastRow.children[6].children[0]) {
                                        lastRow.children[6].children[0].forceActiveFocus()
                                    }
                                }
                            }
                            
                            Keys.onLeftPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = 0
                                    event.accepted = true
                                } else if (cursorPosition <= 0) {
                                    shadowTensileStrengthInput.forceActiveFocus()
                                    shadowTensileStrengthInput.selectAll()
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.max(0, cursorPosition - 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onRightPressed: {
                                if (selectedText.length > 0) {
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else if (cursorPosition >= text.length) {
                                    // Stay in last column - move cursor to end
                                    cursorPosition = text.length
                                    event.accepted = true
                                } else {
                                    cursorPosition = Math.min(text.length, cursorPosition + 1)
                                    event.accepted = true
                                }
                            }
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Action - Add Button
                    Rectangle {
                        width: root.columnWidths[7]
                        height: 30
                        color: "#f8f8f8"
                        border.color: "#ddd"
                        border.width: 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Add"
                            font.pixelSize: 11
                            color: "#2196F3"
                            font.bold: true
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    shadowRow.addMaterial()
                                }
                            }
                        }
                    }
                }
            }

            // Let children process keys first; ScrollView won't consume arrow keys during editing
            Keys.priority: Keys.AfterItem
            Keys.onPressed: {
                const k = event.key
                const isArrow = (k === Qt.Key_Left || k === Qt.Key_Right || k === Qt.Key_Up || k === Qt.Key_Down)
                if (!isArrow) return
                // If a TextInput is focused, do not accept here; delegate to child handlers
                const af = Qt.application.activeFocusItem
                const isEditing = af && af.cursorPosition !== undefined
                if (isEditing) {
                    event.accepted = false
                }
            }
        }
    }

    // Connections untuk mendengarkan perubahan model
    Connections {
        target: materialController ? materialController : materialModel
        function onMaterialInserted(id) {
            console.log("Material inserted with ID:", id)
            root.refreshData()
        }
        function onMaterialDeleted(id) {
            console.log("Material deleted with ID:", id)
            root.refreshData()
        }
        function onMaterialUpdated(id) {
            console.log("Material updated with ID:", id)
            // If this update was initiated locally, ignore the signal to avoid losing focus
            if (root._lastLocalUpdatedId && root._lastLocalUpdatedId === id) {
                console.log("Ignoring local update signal for id:", id)
                root._lastLocalUpdatedId = 0
                return
            }
            root.refreshData()
        }
        function onError(message) {
            console.log("Model error:", message)
        }
    }
}
