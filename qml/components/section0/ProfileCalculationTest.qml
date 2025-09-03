import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: testingPanel
    color: "#f0f0f0"
    border.color: "#cccccc"
    border.width: 1
    radius: 8

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            text: "Profile Calculation Testing"
            font.pixelSize: 16
            font.bold: true
            color: "#2196F3"
        }

        // Input section
        GroupBox {
            title: "Input Parameters"
            Layout.fillWidth: true

            GridLayout {
                columns: 4
                anchors.fill: parent

                Text { text: "hw (mm):" }
                TextField {
                    id: hwInput
                    text: "400"
                    validator: DoubleValidator { bottom: 0 }
                    Layout.preferredWidth: 80
                }

                Text { text: "tw (mm):" }
                TextField {
                    id: twInput
                    text: "26"
                    validator: DoubleValidator { bottom: 0 }
                    Layout.preferredWidth: 80
                }

                Text { text: "bf (mm):" }
                TextField {
                    id: bfInput
                    text: "85"
                    validator: DoubleValidator { bottom: 0 }
                    Layout.preferredWidth: 80
                }

                Text { text: "tf (mm):" }
                TextField {
                    id: tfInput
                    text: "14.7"
                    validator: DoubleValidator { bottom: 0 }
                    Layout.preferredWidth: 80
                }

                Text { text: "Type:" }
                ComboBox {
                    id: typeCombo
                    model: ["Bar", "HP", "T", "FB", "L"]
                    Layout.preferredWidth: 100
                }
            }
        }

        // Calculate button
        Button {
            text: "Calculate Profile Properties"
            Layout.fillWidth: true
            onClicked: {
                if (profileController) {
                    var result = profileController.countingFormula(
                        parseFloat(hwInput.text),
                        parseFloat(twInput.text),
                        parseFloat(bfInput.text),
                        parseFloat(tfInput.text),
                        typeCombo.currentText
                    )
                    
                    if (result && result.length >= 4) {
                        areaResult.text = "Area: " + result[0].toFixed(2) + " cm²"
                        eResult.text = "e: " + result[1].toFixed(2) + " mm"
                        wResult.text = "W: " + result[2].toFixed(2) + " cm³"
                        upperIResult.text = "Upper I: " + result[3].toFixed(2) + " cm⁴"
                    } else {
                        areaResult.text = "Error: Invalid result"
                        eResult.text = ""
                        wResult.text = ""
                        upperIResult.text = ""
                    }
                } else {
                    areaResult.text = "Error: Profile controller not available"
                    eResult.text = ""
                    wResult.text = ""
                    upperIResult.text = ""
                }
            }
        }

        // Results section
        GroupBox {
            title: "Calculation Results"
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 5

                Text {
                    id: areaResult
                    text: "Area: -"
                    font.pixelSize: 12
                }

                Text {
                    id: eResult
                    text: "e: -"
                    font.pixelSize: 12
                }

                Text {
                    id: wResult
                    text: "W: -"
                    font.pixelSize: 12
                }

                Text {
                    id: upperIResult
                    text: "Upper I: -"
                    font.pixelSize: 12
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
