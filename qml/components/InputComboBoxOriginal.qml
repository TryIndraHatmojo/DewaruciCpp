import QtQuick 2.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

Item {
    id: container
    property var model: [{"name" : "Role 1"}, {"name" : "Role 2"}, {"name":"Role 3"}]
    property string label: "Name"
    property string unit: ""
    property string value: ""
    property var widthLayout: [0.2, 0.7]
    property alias textRole: combo.textRole
    property alias delegate: combo.delegate
    property alias combo: combo

    property alias editable: combo.editable

    property alias currentIndex: combo.currentIndex
    property alias currentText: combo.currentText

    RowLayout{
        width: parent.width
        Layout.alignment: Qt.AlignHCenter
        height: 40
        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width*widthLayout[0]
            text: label

            font.pointSize: setting.font_size
        }
        Text {
            text: qsTr(":")
            font.pointSize: setting.font_size
        }
        ComboBox{
            id: combo
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width*widthLayout[1]
            model: container.model
            textRole: "name"
            font.pointSize: setting.font_size
            valueRole: combo.textRole
            background: Rectangle {
                implicitWidth: 200
                implicitHeight: 40
                color: "transparent"
                border.color: "transparent"
                Rectangle{
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 1
                    width: parent.width
                    color: "grey"
                }
            }
            delegate:  ItemDelegate {
                width: combo.width
                height: combo.height 
                contentItem: Text {
                    text: {
                        const properties = textRole.split('.');
                        let value = modelData;
                        for (let prop of properties) {
                          value = value[prop];
                        }
                        return value;
                    }
                    font: combo.font
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                highlighted: combo.highlightedIndex === index
            }
            onCurrentTextChanged: {
                value = combo.currentText
            }
            onEditTextChanged: {
                value = editText;
            }
        }
        Text {
            text: unit
            Layout.preferredWidth: parent.width*0.1

            visible: !(unit=="")
            font.pointSize: 8.5
        }
    }
}
