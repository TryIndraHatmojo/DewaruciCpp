import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components/section0"
import "pages"

ApplicationWindow {
    id: mainWindow
    width: 1400
    height: 1000
    visible: true
    title: qsTr("Dewaruci - Naval Architecture Application")

    property int sidebarWidth: 250
    property string currentPage: "materialProfile"

    Rectangle {
        anchors.fill: parent
        color: "#f0f0f0"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
            Rectangle {
                id: sidebar
                Layout.preferredWidth: sidebarWidth
                Layout.fillHeight: true
                color: "#2c3e50"
                border.color: "#34495e"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sidebar Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        color: "#34495e"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Navigation"
                            color: "#ecf0f1"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }

                    // Sidebar Content - Scrollable
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        ColumnLayout {
                            width: sidebar.width
                            spacing: 2

                            // Material and Profile Library Item
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                color: currentPage === "materialProfile" ? "#3498db" : "transparent"
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: currentPage = "materialProfile"
                                    onEntered: parent.color = currentPage === "materialProfile" ? "#3498db" : "#34495e"
                                    onExited: parent.color = currentPage === "materialProfile" ? "#3498db" : "transparent"
                                }
                                
                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15
                                    spacing: 10
                                    
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: "#e74c3c"
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Material and Profile Library"
                                        color: "#ecf0f1"
                                        font.pixelSize: 14
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            // Frame Arrangement Item
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                color: currentPage === "frameArrangement" ? "#3498db" : "transparent"
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: currentPage = "frameArrangement"
                                    onEntered: parent.color = currentPage === "frameArrangement" ? "#3498db" : "#34495e"
                                    onExited: parent.color = currentPage === "frameArrangement" ? "#3498db" : "transparent"
                                }
                                
                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15
                                    spacing: 10
                                    
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: "#f39c12"
                                    }
                                    
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Frame Arrangement"
                                        color: "#ecf0f1"
                                        font.pixelSize: 14
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            // Spacer to push items to top
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }

            // Resize Handle
            Rectangle {
                id: resizeHandle
                Layout.preferredWidth: 6
                Layout.fillHeight: true
                color: "#95a5a6"
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeHorCursor
                    hoverEnabled: true
                    onEntered: parent.color = "#7f8c8d"
                    onExited: parent.color = "#95a5a6"
                    
                    property real startX: 0
                    property real startWidth: 0
                    
                    onPressed: {
                        startX = mouseX
                        startWidth = sidebarWidth
                    }
                    
                    onPositionChanged: {
                        if (pressed) {
                            var newWidth = startWidth + (mouseX - startX)
                            // Limit sidebar width between 150 and 400 pixels
                            sidebarWidth = Math.max(150, Math.min(400, newWidth))
                        }
                    }
                }
            }

            // Main Content Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ecf0f1"

                // Content Stack - shows different pages based on currentPage
                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    anchors.margins: 5
                    
                    sourceComponent: {
                        switch(currentPage) {
                            case "materialProfile":
                                return materialProfileComponent
                            case "frameArrangement":
                                return frameArrangementComponent
                            default:
                                return materialProfileComponent
                        }
                    }
                }
            }
        }
    }

    // Component for Material and Profile Library page
    Component {
        id: materialProfileComponent

        MaterialAndProfileLibrary {
            // The page itself handles layout and child components
            anchors.fill: parent
        }
    }

    // Component for Frame Arrangement page
    Component {
        id: frameArrangementComponent
        
        FrameArrangement {
            
        }
    }
}
