import QtQuick 2.15
import QtQuick.Controls 2.15

Popup {
    id: root
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    x: (parent ? parent.width : 600) / 2 - width/2
    y: (parent ? parent.height : 400) / 2 - height/2
    padding: 12

    property string prefix: "L"
    property int defaultSuffix: 0
    // mode: 'add' or 'update' to control autofill behavior
    property string mode: "add"
    // If provided (>=0), used to prefill the field when opening in update mode
    property int presetSuffix: -1
    // Error message for validation feedback
    property string errorMessage: ""

    signal accepted(int suffix)
    signal cancelled()

    contentItem: Column {
        spacing: 10
        width: 320

        Text {
            text: "Input suffix manual untuk prefix " + root.prefix
            color: "#2c3e50"
            font.pixelSize: 12
        }

        Row {
            spacing: 6
            Text { text: root.prefix; font.pixelSize: 12 }
            TextField {
                id: suffixField
                width: 180
                placeholderText: String(root.defaultSuffix)
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0 }
            }
        }

        // Validation message
        Text {
            text: root.errorMessage
            color: "#d32f2f"
            visible: root.errorMessage.length > 0
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        Row {
            spacing: 8
            Button {
                text: "OK"
                onClicked: {
                    var raw = suffixField.text.trim()
                    // Validation: must be digits >= 0
                    if (raw === "" && root.mode === 'add') {
                        // In add-manual flow, empty input is allowed -> we will use defaultSuffix
                        raw = String(root.defaultSuffix)
                    }
                    if (!/^\d+$/.test(raw)) {
                        root.errorMessage = "Masukkan angka (0 atau lebih)."
                        suffixField.focus = true
                        suffixField.selectAll()
                        return
                    }
                    var v = parseInt(raw)
                    if (isNaN(v) || v < 0) {
                        root.errorMessage = "Suffix tidak boleh negatif."
                        suffixField.focus = true
                        suffixField.selectAll()
                        return
                    }
                    root.errorMessage = ""
                    root.accepted(v)
                    root.close()
                }
            }
            Button {
                text: "Batal"
                onClicked: { root.cancelled(); root.close() }
            }
        }
    }

    // Autofill behavior each time popup is shown
    onOpened: {
        root.errorMessage = ""
        if (root.mode === 'update') {
            var v = (root.presetSuffix !== undefined && root.presetSuffix >= 0) ? root.presetSuffix : root.defaultSuffix
            suffixField.text = String(v)
            suffixField.selectAll()
        } else {
            suffixField.text = ""
        }
    }
}
