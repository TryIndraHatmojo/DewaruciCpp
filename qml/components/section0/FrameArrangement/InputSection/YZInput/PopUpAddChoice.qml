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

    // API
    // stage: "choice" -> ask user continue vs manual
    //         "select-group" -> choose which group to continue
    property string stage: "choice"
    property string prefix: "L"
    property var groups: [] // [ { startSuffix, endSuffix } ]
    // mode: 'add' when adding new shadow row, 'update' when updating Name
    property string mode: "add"

    signal chooseContinue(int startSuffix) // startSuffix is end+1 of chosen group
    signal chooseManual()
    signal cancelled()

    contentItem: Column {
        spacing: 10
        width: 420

        Text {
            wrapMode: Text.WordWrap
            text: stage === "choice"
                  ? ((root.mode === 'update' ? "Update baris prefix " : "Tambah baris prefix ") + root.prefix + ". Pilih opsi: lanjutkan urutan atau manual.")
                  : "Pilih kelompok untuk dilanjutkan (urutan berikutnya setelah akhir kelompok)."
            font.pixelSize: 12
            color: "#2c3e50"
        }

        // Stage 1: choice
        Column {
            visible: stage === "choice"
            spacing: 6
            Button {
                text: "Lanjutkan urutan"
                onClicked: {
                    // go to select-group stage if ada lebih dari satu grup, kalau tidak langsung gunakan grup satu-satunya
                    if (root.groups && root.groups.length > 1) {
                        root.stage = "select-group"
                    } else {
                        var g = (root.groups && root.groups.length === 1) ? root.groups[0] : null
                        var start = g ? (g.endSuffix + 1) : 0
                        root.chooseContinue(start)
                        root.close()
                    }
                }
            }
            Button {
                text: "Manual input"
                onClicked: {
                    root.chooseManual()
                    root.close()
                }
            }
            Button {
                text: "Batal"
                onClicked: { root.cancelled(); root.close() }
            }
        }

        // Stage 2: select-group
        Column {
            visible: stage === "select-group"
            spacing: 6
            Repeater {
                model: (root.groups && root.groups.length) ? root.groups : []
                delegate: Button {
                    text: "Kelompok: " + root.prefix + modelData.startSuffix + ".." + root.prefix + modelData.endSuffix +
                          "  → lanjut dari " + root.prefix + (modelData.endSuffix + 1)
                    onClicked: {
                        root.chooseContinue(modelData.endSuffix + 1)
                        root.close()
                    }
                }
            }
            Button {
                text: "Kembali"
                onClicked: { root.stage = "choice" }
            }
        }
    }
}
