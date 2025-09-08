import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: frameArrangementPage
    color: "#f5f5f5"
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // Left side - Input Section
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.6
            color: "#ffffff"
            border.color: "#cccccc"
            border.width: 1
            radius: 8
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 20
                
                // Input Section Title
                Text {
                    text: "Input Section"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#2c3e50"
                }
                
                // Frame X Z Table
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10
                    
                    Text {
                        text: "Frame X Z Table"
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
                                        "F. Spacing [mm]", 
                                        "ML", 
                                        "Xp-Coor fr.aft PP [m]", 
                                        "X/L", 
                                        "XLL-Coor fr.aft PLL [m]", 
                                        "XLL/LLL", 
                                        "Action"
                                    ]
                                    
                                    Repeater {
                                        model: parent.frameXZHeaders
                                        
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
                                        border.color: "#bdc3c7"
                                        border.width: 0.5
                                        
                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 1
                                            
                                            // Frame No
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.frameNumber || "0"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // F. Spacing
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.frameSpacing || "1820"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // ML
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                ComboBox {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 4
                                                    height: parent.height - 4
                                                    model: ["FORWARD", "AFTER"]
                                                    currentIndex: 0
                                                    font.pixelSize: 9
                                                }
                                            }
                                            
                                            // Xp-Coor
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.xpCoor || "0.000"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // X/L
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.xl || "0.0000"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // XLL-Coor
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.xllCoor || "0.000"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // XLL/LLL
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.xllLll || "0.0000"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // Action
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Button {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 4
                                                    height: parent.height - 4
                                                    text: "Delete"
                                                    font.pixelSize: 8
                                                    background: Rectangle {
                                                        color: "#e74c3c"
                                                        radius: 2
                                                    }
                                                    contentItem: Text {
                                                        text: parent.text
                                                        color: "#ffffff"
                                                        font.pixelSize: parent.font.pixelSize
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                    onClicked: {
                                                        if (modelData.id) {
                                                            frameXZController.deleteFrameXZ(modelData.id)
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
                }
                
                // Frame Y Z Table
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10
                    
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
                                    model: frameYZModel
                                    
                                    delegate: Rectangle {
                                        width: ListView.view.width
                                        height: 35
                                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                                        border.color: "#bdc3c7"
                                        border.width: 0.5
                                        
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
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: name || "L0"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // No
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: no || "0"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // Spacing
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: spacing || "1"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // Y [mm]
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: y || "0"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // Z [mm]
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: z || "0"
                                                    font.pixelSize: 10
                                                }
                                            }
                                            
                                            // Frame No.
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: frameNo || "24"
                                                    font.pixelSize: 10
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
                                                    anchors.centerIn: parent
                                                    width: parent.width - 4
                                                    height: parent.height - 4
                                                    model: ["F+A"]
                                                    currentIndex: 0
                                                    font.pixelSize: 9
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
                                                    anchors.centerIn: parent
                                                    width: parent.width - 4
                                                    height: parent.height - 4
                                                    model: ["P+S"]
                                                    currentIndex: 0
                                                    font.pixelSize: 9
                                                }
                                            }
                                            
                                            // Action
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: "transparent"
                                                border.color: "#bdc3c7"
                                                border.width: 0.5
                                                
                                                Button {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 4
                                                    height: parent.height - 4
                                                    text: "Delete"
                                                    font.pixelSize: 8
                                                    background: Rectangle {
                                                        color: "#e74c3c"
                                                        radius: 2
                                                    }
                                                    contentItem: Text {
                                                        text: parent.text
                                                        color: "#ffffff"
                                                        font.pixelSize: parent.font.pixelSize
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                    onClicked: {
                                                        if (id) {
                                                            frameYZModel.deleteFrame(id)
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
                }
            }
        }
        
        // Right side - Graph Sections
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.4
            spacing: 20
            
            // Frame X Z Graph
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ffffff"
                border.color: "#cccccc"
                border.width: 1
                radius: 8
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    // Header with title and help icon
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "Frame X Z"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#34495e"
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "#3498db"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "?"
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }
                    
                    // Graph area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#f8f9fa"
                        border.color: "#dee2e6"
                        border.width: 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: "No Data."
                            color: "#6c757d"
                            font.pixelSize: 14
                        }
                    }
                    
                    // Expand icon
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        color: "transparent"
                        
                        Rectangle {
                            anchors.right: parent.right
                            width: 16
                            height: 16
                            color: "#95a5a6"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⤢"
                                color: "#ffffff"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
            
            // Frame Y Z Graph
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ffffff"
                border.color: "#cccccc"
                border.width: 1
                radius: 8
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    Text {
                        text: "Frame Y Z"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#34495e"
                    }
                    
                    Text {
                        text: "Frame No.      :"
                        font.pixelSize: 12
                        color: "#6c757d"
                    }
                    
                    // Graph area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#f8f9fa"
                        border.color: "#dee2e6"
                        border.width: 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: "No Data."
                            color: "#6c757d"
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }
}