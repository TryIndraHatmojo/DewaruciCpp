import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
    id: root
    focusPolicy: Qt.StrongFocus
    // Allow keyboard focus via Tab to ensure arrow keys work when focused
    activeFocusOnTab: true
    focus: true
    // External callbacks
    property var commitCallback: undefined   // function(text)
    property var redrawCallback: undefined   // function()

    // Internal state
    property string savedValue: ""
    property int lastCommittedIndex: -1
    property bool confirming: false

    // Expose whether dropdown is open
    readonly property bool dropdownOpen: popup && popup.visible

    // Helper to commit current selection to external model and trigger redraw
    function commitSelection() {
        if (lastCommittedIndex === currentIndex) return
        if (commitCallback) commitCallback(currentText)
        lastCommittedIndex = currentIndex
        if (redrawCallback) redrawCallback()
    }

    Component.onCompleted: {
        // Ensure list highlights follow current index if contentItem is a ListView
        try {
            if (popup && popup.contentItem && popup.contentItem.hasOwnProperty("highlightFollowsCurrentItem")) {
                popup.contentItem.highlightFollowsCurrentItem = true
            }
        } catch (e) {
            // no-op
        }
        savedValue = currentText
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            savedValue = currentText
        }
    }

    Keys.onUpPressed: (event) => {
        if (!activeFocus) return
        event.accepted = true // prevent Table/List from handling
        // Move selection up within the ComboBox
        var next = Math.max(0, currentIndex - 1)
        if (next !== currentIndex) {
            currentIndex = next
            // Immediately commit on keyboard-driven change
            commitSelection()
        }
        if (popup && popup.contentItem && popup.contentItem.hasOwnProperty("currentIndex")) {
            popup.contentItem.currentIndex = currentIndex
        }
    }

    Keys.onDownPressed: (event) => {
        if (!activeFocus) return
        event.accepted = true // prevent Table/List from handling
        var cnt = (typeof count === 'number') ? count : (model && model.count ? model.count : 0)
        var next = Math.min(cnt - 1, currentIndex + 1)
        if (next !== currentIndex) {
            currentIndex = next
            // Immediately commit on keyboard-driven change
            commitSelection()
        }
        if (popup && popup.contentItem && popup.contentItem.hasOwnProperty("currentIndex")) {
            popup.contentItem.currentIndex = currentIndex
        }
    }

    Keys.onReturnPressed: (event) => {
        if (!activeFocus) return
        event.accepted = true
        confirming = true
        if (dropdownOpen && popup) popup.close()
        // Commit current selection on Enter/Return
        commitSelection()
        confirming = false
    }

    Keys.onEnterPressed: (event) => {
        root.Keys.onReturnPressed(event)
    }

    Keys.onEscapePressed: (event) => {
        if (!activeFocus) return
        event.accepted = true
        // Restore previous value (by text)
        var oldIdx = currentIndex
        if (savedValue && savedValue.length > 0) {
            // Find index by text
            var idx = -1
            var cnt = (typeof count === 'number') ? count : (model && model.count ? model.count : 0)
            for (var i = 0; i < cnt; ++i) {
                var txt = ""
                if (textRole && model && model[i] && model[i][textRole] !== undefined) txt = model[i][textRole]
                else if (typeof model === 'object' && model.get) txt = model.get(i)
                else if (model && model[i] !== undefined) txt = model[i]
                if (("" + txt) === savedValue) { idx = i; break }
            }
            if (idx >= 0) currentIndex = idx
        } else {
            currentIndex = oldIdx
        }
        if (dropdownOpen && popup) popup.close()
    }

    // Commit when the user activates an item from the popup (mouse/touch or Enter on an item)
    onActivated: {
        commitSelection()
    }

    // Fallback: only commit on index change when we're in an explicit confirming state
    // (to avoid commits on programmatic changes like initialization)
    onCurrentIndexChanged: {
        if (!confirming) return
        commitSelection()
    }
}
