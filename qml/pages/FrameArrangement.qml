import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components/section0/FrameArrangement/InputSection/XZInput"
import "../components/section0/FrameArrangement/InputSection/YZInput"
import "../components/section0/FrameArrangement/Frame" as FrameSection

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
                XZInput {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // Frame Y Z Table
                YZInput {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
            
            // Frame Y Z Graph (extracted component)
            FrameSection.YZFrame {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}