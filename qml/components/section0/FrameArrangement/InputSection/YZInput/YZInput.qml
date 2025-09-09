import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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