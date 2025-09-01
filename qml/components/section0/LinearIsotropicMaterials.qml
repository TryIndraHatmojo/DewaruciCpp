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
    
    // Function untuk memastikan total lebar kolom tidak melebihi container
    function adjustColumnWidths() {
        var totalWidth = 0
        for (var i = 0; i < columnWidths.length; i++) {
            totalWidth += columnWidths[i]
        }
        
        // Jika total melebihi lebar container, scale down proportionally
        if (totalWidth > root.width - 4) {  // -4 untuk margin
            var scaleFactor = (root.width - 4) / totalWidth
            for (var j = 0; j < columnWidths.length; j++) {
                columnWidths[j] = columnWidths[j] * scaleFactor
            }
        }
    }
    
    // Function untuk resize kolom dengan penyesuaian otomatis kolom lain
    function resizeColumn(columnIndex, newWidth) {
        var minWidth = 50  // Lebar minimum untuk setiap kolom
        var maxContainerWidth = root.width - 4  // Total lebar yang tersedia
        
        // Pastikan newWidth tidak kurang dari minimum
        newWidth = Math.max(minWidth, newWidth)
        
        var newWidths = root.columnWidths.slice()  // Copy array
        var oldWidth = newWidths[columnIndex]
        var widthDifference = newWidth - oldWidth
        
        // Jika tidak ada perubahan, return
        if (Math.abs(widthDifference) < 1) {
            return
        }
        
        // Update kolom yang di-resize
        newWidths[columnIndex] = newWidth
        
        // Hitung sisa space yang tersedia untuk kolom lain
        var remainingWidth = maxContainerWidth - newWidth
        var otherColumnsCount = newWidths.length - 1
        
        if (otherColumnsCount > 0 && remainingWidth > 0) {
            // Hitung total lebar kolom lain saat ini
            var currentOtherColumnsWidth = 0
            for (var i = 0; i < newWidths.length; i++) {
                if (i !== columnIndex) {
                    currentOtherColumnsWidth += newWidths[i]
                }
            }
            
            // Jika ada space untuk kolom lain
            if (currentOtherColumnsWidth > 0) {
                // Distribute remaining width proportionally
                var scale = remainingWidth / currentOtherColumnsWidth
                
                for (var j = 0; j < newWidths.length; j++) {
                    if (j !== columnIndex) {
                        var scaledWidth = newWidths[j] * scale
                        newWidths[j] = Math.max(minWidth, scaledWidth)
                    }
                }
            } else {
                // Jika kolom lain tidak ada lebar, bagi rata
                var averageWidth = Math.max(minWidth, remainingWidth / otherColumnsCount)
                for (var k = 0; k < newWidths.length; k++) {
                    if (k !== columnIndex) {
                        newWidths[k] = averageWidth
                    }
                }
            }
        }
        
        // Update columnWidths
        root.columnWidths = newWidths
    }
    
    // Panggil adjustColumnWidths ketika ukuran berubah
    onWidthChanged: adjustColumnWidths()

    // Component.onCompleted untuk load data dari database
    Component.onCompleted: {
        refreshData()
    }
    
    // Function untuk refresh data dari database
    function refreshData() {
        if (materialDatabase && materialDatabase.isDBConnected()) {
            var materials = materialDatabase.getAllMaterialsForQML()
            tableModel = materials
            console.log("Loaded", materials.length, "materials from database")
        } else {
            console.log("Database not connected, using sample data")
            // Fallback ke data sample jika database tidak tersedia
        }
    }
    
    // Helper function untuk focus + select all
    function focusAndSelect(targetInput) {
        targetInput.forceActiveFocus()
        targetInput.selectAll()
    }
    
    // Function untuk delete material
    function deleteMaterial(index, materialId) {
        if (materialDatabase && materialDatabase.isDBConnected()) {
            if (materialDatabase.removeMaterial(materialId)) {
                console.log("Material deleted successfully")
                refreshData() // Refresh data setelah delete
            } else {
                console.log("Failed to delete material:", materialDatabase.getLastError())
            }
        }
    }
    
    // Function untuk add material baru dari shadow row
    function addNewMaterial(eModulus, gModulus, density, yieldStress, tensileStrength, remark) {
        if (materialDatabase && materialDatabase.isDBConnected()) {
            if (materialDatabase.addMaterial(eModulus, gModulus, density, yieldStress, tensileStrength, remark)) {
                console.log("New material added successfully")
                refreshData() // Refresh data setelah add
                // Reset shadow row ke nilai default
                resetShadowRow()
            } else {
                console.log("Failed to add material:", materialDatabase.getLastError())
            }
        }
    }
    
    // Function untuk reset shadow row ke data terakhir
    function resetShadowRow() {
        if (materialDatabase && materialDatabase.isDBConnected()) {
            var materials = materialDatabase.getAllMaterialsForQML()
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Mat. No."
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
                            startX = mouse.x
                            startWidth = parent.parent.width
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "E-Mod\n[kN/mm²]"
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
                            startX = mouse.x
                            startWidth = parent.parent.width
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "G-Mod\n[kN/mm²]"
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
                            startX = mouse.x
                            startWidth = parent.parent.width
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "M. Density\n[kg/m³]"
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
                            startX = mouse.x
                            startWidth = parent.parent.width
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Y. Stress\n[N/mm²]"
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
                            startX = mouse.x
                            startWidth = parent.parent.width
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Tensile S.\n[N/mm²]"
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
                            startX = mouse.x
                            startWidth = parent.parent.width
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Remark"
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
                            startX = mouse.x
                            startWidth = parent.parent.width
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
                color: "#e3f2fd"
                border.color: "#ddd"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Action"
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
                            if (materialDatabase && materialDatabase.isDBConnected() && materialData.id) {
                                var success = materialDatabase.updateMaterial(
                                    materialData.id,
                                    parseInt(eModInput.text) || 0,
                                    parseInt(gModInput.text) || 0,
                                    parseInt(densityInput.text) || 0,
                                    parseInt(yieldStressInput.text) || 0,
                                    parseInt(tensileStrengthInput.text) || 0,
                                    remarkInput.text || ""
                                )
                                if (success) {
                                    console.log("Material updated successfully")
                                    root.refreshData()
                                } else {
                                    console.log("Failed to update material:", materialDatabase.getLastError())
                                }
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
                                        var prevRow = materialRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[1] && prevRow.children[1].children[0]) {
                                            prevRow.children[1].children[0].forceActiveFocus()
                                            prevRow.children[1].children[0].selectAll()
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        var nextRow = materialRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[1] && nextRow.children[1].children[0]) {
                                            nextRow.children[1].children[0].forceActiveFocus()
                                            nextRow.children[1].children[0].selectAll()
                                        }
                                    } else {
                                        // Go to shadow row
                                        shadowEModInput.forceActiveFocus()
                                        shadowEModInput.selectAll()
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        // If text is highlighted, move cursor to end
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        // If at end, move to next cell
                                        gModInput.forceActiveFocus()
                                        gModInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        // If text is highlighted, move cursor to beginning
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        // Stay in first column - just move to beginning
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
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
                                        var prevRow = materialRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[2] && prevRow.children[2].children[0]) {
                                            prevRow.children[2].children[0].forceActiveFocus()
                                            prevRow.children[2].children[0].selectAll()
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        var nextRow = materialRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[2] && nextRow.children[2].children[0]) {
                                            nextRow.children[2].children[0].forceActiveFocus()
                                            nextRow.children[2].children[0].selectAll()
                                        }
                                    } else {
                                        shadowGModInput.forceActiveFocus()
                                        shadowGModInput.selectAll()
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        // If text is highlighted, move cursor to beginning
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        // If at beginning, move to previous cell
                                        eModInput.forceActiveFocus()
                                        eModInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        // If text is highlighted, move cursor to end
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        // If at end, move to next cell
                                        densityInput.forceActiveFocus()
                                        densityInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
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
                                        var prevRow = materialRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[3] && prevRow.children[3].children[0]) {
                                            prevRow.children[3].children[0].forceActiveFocus()
                                            prevRow.children[3].children[0].selectAll()
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        var nextRow = materialRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[3] && nextRow.children[3].children[0]) {
                                            nextRow.children[3].children[0].forceActiveFocus()
                                            nextRow.children[3].children[0].selectAll()
                                        }
                                    } else {
                                        shadowDensityInput.forceActiveFocus()
                                        shadowDensityInput.selectAll()
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        // If text is highlighted, move cursor to beginning
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        // If at beginning, move to previous cell
                                        gModInput.forceActiveFocus()
                                        gModInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        // If text is highlighted, move cursor to end
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        // If at end, move to next cell
                                        yieldStressInput.forceActiveFocus()
                                        yieldStressInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
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
                                        var prevRow = materialRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[4] && prevRow.children[4].children[0]) {
                                            prevRow.children[4].children[0].forceActiveFocus()
                                            prevRow.children[4].children[0].selectAll()
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        var nextRow = materialRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[4] && nextRow.children[4].children[0]) {
                                            nextRow.children[4].children[0].forceActiveFocus()
                                            nextRow.children[4].children[0].selectAll()
                                        }
                                    } else {
                                        shadowYieldStressInput.forceActiveFocus()
                                        shadowYieldStressInput.selectAll()
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        densityInput.forceActiveFocus()
                                        densityInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        tensileStrengthInput.forceActiveFocus()
                                        tensileStrengthInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
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
                                        var prevRow = materialRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[5] && prevRow.children[5].children[0]) {
                                            prevRow.children[5].children[0].forceActiveFocus()
                                            prevRow.children[5].children[0].selectAll()
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        var nextRow = materialRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[5] && nextRow.children[5].children[0]) {
                                            nextRow.children[5].children[0].forceActiveFocus()
                                            nextRow.children[5].children[0].selectAll()
                                        }
                                    } else {
                                        shadowTensileStrengthInput.forceActiveFocus()
                                        shadowTensileStrengthInput.selectAll()
                                    }
                                }
                                
                                Keys.onLeftPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = 0
                                        event.accepted = true
                                    } else if (cursorPosition <= 0) {
                                        yieldStressInput.forceActiveFocus()
                                        yieldStressInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
                                    }
                                }
                                
                                Keys.onRightPressed: {
                                    if (selectedText.length > 0) {
                                        cursorPosition = text.length
                                        event.accepted = true
                                    } else if (cursorPosition >= text.length) {
                                        remarkInput.forceActiveFocus()
                                        remarkInput.selectAll()
                                        event.accepted = true
                                    } else {
                                        event.accepted = false  // Let default behavior handle cursor movement
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
                                        var prevRow = materialRepeater.itemAt(rowIndex - 1)
                                        if (prevRow && prevRow.children[6] && prevRow.children[6].children[0]) {
                                            prevRow.children[6].children[0].forceActiveFocus()
                                            prevRow.children[6].children[0].selectAll()
                                        }
                                    }
                                }
                                
                                Keys.onDownPressed: {
                                    if (rowIndex < materialRepeater.count - 1) {
                                        var nextRow = materialRepeater.itemAt(rowIndex + 1)
                                        if (nextRow && nextRow.children[6] && nextRow.children[6].children[0]) {
                                            nextRow.children[6].children[0].forceActiveFocus()
                                            nextRow.children[6].children[0].selectAll()
                                        }
                                    } else {
                                        shadowRemarkInput.forceActiveFocus()
                                        shadowRemarkInput.selectAll()
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
                                        event.accepted = false  // Let default behavior handle cursor movement
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
                                        event.accepted = false  // Let default behavior handle cursor movement
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
                                        var materialId = parent.parent.parent.parent.materialData.id
                                        root.deleteMaterial(parent.parent.parent.parent.rowIndex, materialId)
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
                                    event.accepted = false  // Let default behavior handle cursor movement
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
        }
    }

    // Connections untuk mendengarkan perubahan database
    Connections {
        target: materialDatabase
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
            root.refreshData()
        }
        function onError(message) {
            console.log("Database error:", message)
        }
    }
}
