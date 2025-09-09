import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 10
    
    Component.onCompleted: {
        frameXZController.getFrameXZList()
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
                        
                        property var frameData: modelData
                        
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
                                    text: frameData ? (frameData.frameNumber || "0") : "0"
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
                                    text: frameData ? (frameData.frameSpacing || "1820") : "1820"
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
                                    currentIndex: frameData && frameData.ml === "AFTER" ? 1 : 0
                                    font.pixelSize: 9
                                    onCurrentTextChanged: {
                                        if (frameData && frameData.id) {
                                            frameXZController.updateFrameXZMl(frameData.id, currentText)
                                        }
                                    }
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
                                    text: frameData ? (frameData.xpCoor ? frameData.xpCoor.toFixed(3) : "0.000") : "0.000"
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
                                    text: frameData ? (frameData.xl ? frameData.xl.toFixed(4) : "0.0000") : "0.0000"
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
                                    text: frameData ? (frameData.xllCoor ? frameData.xllCoor.toFixed(3) : "0.000") : "0.000"
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
                                    text: frameData ? (frameData.xllLll ? frameData.xllLll.toFixed(4) : "0.0000") : "0.0000"
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
                                        if (frameData && frameData.id) {
                                            frameXZController.deleteFrameXZ(frameData.id)
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