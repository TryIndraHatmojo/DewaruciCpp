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
    property string prefix: "L"
    // Start suffix yang dimasukkan user saat manual (untuk ditampilkan di teks dan tombol Manual)
    property int manualStartSuffix: 0
    property int suggestedStartSuffix: 0
    property int suggestedCount: 0
    property var conflictingRanges: [] // array of { startSuffix, endSuffix, reason }

    signal acceptedAuto(string continueFromName, int startSuffix)
    signal acceptedManual(int startSuffix)
    signal cancelled()

    contentItem: Column {
        spacing: 10
        width: 380

        Text {
            wrapMode: Text.WordWrap
            text: {
                const mStart = root.manualStartSuffix
                const cnt = root.suggestedCount
                const mEnd = mStart + Math.max(0, cnt - 1)
                const aStart = root.suggestedStartSuffix
                const aEnd = aStart + Math.max(0, cnt - 1)
                return "Anda memasukkan " + root.prefix + mStart + (cnt > 1 ? (".." + root.prefix + mEnd) : "") + ". "
                     + "Saran otomatis: " + root.prefix + aStart + (cnt > 1 ? (".." + root.prefix + aEnd) : "") + ".";
            }
            font.pixelSize: 12
            color: "#2c3e50"
        }

        // Show conflicts if any
        Repeater {
            model: (conflictingRanges && conflictingRanges.length) ? conflictingRanges : []
            delegate: Text {
                font.pixelSize: 11
                color: "#c0392b"
                text: "Bentrok: " + root.prefix + modelData.startSuffix + ".." + root.prefix + modelData.endSuffix + (modelData.reason ? (" (" + modelData.reason + ")") : "")
            }
        }

        // Candidate actions
        Column {
            spacing: 6
            Button {
                text: "Auto - Lanjutkan dari " + root.prefix + root.suggestedStartSuffix
                onClicked: {
                    root.acceptedAuto(root.prefix + root.suggestedStartSuffix, root.suggestedStartSuffix)
                    root.close()
                }
            }
            Button {
                text: "Gunakan Manual (" + root.prefix + root.manualStartSuffix + ")"
                onClicked: {
                    root.acceptedManual(root.manualStartSuffix)
                    root.close()
                }
            }
            Button {
                text: "Batal"
                onClicked: {
                    root.cancelled()
                    root.close()
                }
            }
        }
    }
}
