import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    width: parent ? parent.width : 800
    height: 300
    color: "#f5f5f5"
    border.color: "#2196F3"
    border.width: 2
    radius: 8

    property var tableModel: []

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

            Rectangle {
                width: 80
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
            }

            Rectangle {
                width: 100
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
            }

            Rectangle {
                width: 100
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
            }

            Rectangle {
                width: 100
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
            }

            Rectangle {
                width: 100
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
            }

            Rectangle {
                width: 100
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
            }

            Rectangle {
                width: 100
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
            }

            Rectangle {
                width: 80
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

            Column {
                width: scrollView.width
                
                // Data rows
                Repeater {
                    model: root.tableModel
                    delegate: Row {
                        property int rowIndex: index
                        property bool isEven: index % 2 === 0
                        property var materialData: modelData || {}
                        
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
                            width: 80
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
                            width: 100
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
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // G-Modulus - Editable Number Input
                        Rectangle {
                            width: 100
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
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Density - Editable Number Input
                        Rectangle {
                            width: 100
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
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Yield Stress - Editable Number Input
                        Rectangle {
                            width: 100
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
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Tensile Strength - Editable Number Input
                        Rectangle {
                            width: 100
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
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Remark - Editable Text Input
                        Rectangle {
                            width: 100
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
                                
                                onEditingFinished: {
                                    parent.parent.updateMaterial()
                                }
                            }
                        }

                        // Action - Delete Button
                        Rectangle {
                            width: 80
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
                        width: 80
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
                        width: 100
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
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // G-Modulus - Shadow Input
                    Rectangle {
                        width: 100
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
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Density - Shadow Input
                    Rectangle {
                        width: 100
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
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Yield Stress - Shadow Input
                    Rectangle {
                        width: 100
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
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Tensile Strength - Shadow Input
                    Rectangle {
                        width: 100
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
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Remark - Shadow Input
                    Rectangle {
                        width: 100
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
                            
                            Keys.onReturnPressed: {
                                shadowRow.addMaterial()
                            }
                        }
                    }

                    // Action - Add Button
                    Rectangle {
                        width: 80
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
