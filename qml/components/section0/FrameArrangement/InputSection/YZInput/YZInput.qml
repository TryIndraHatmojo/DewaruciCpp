import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import DewaruciCpp 1.0

ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 10
    
    // Signal to notify frame drawing to refresh when data changes
    signal dataChanged()
    
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
                    id: yzList
                    // Track which editable column currently has focus
                    property int focusedColumn: 0
                    model: frameYZController.frameYZList

                    // Pending operation context for suffix conflict dialog
                    property var pendingOp: null // { mode: 'update'|'insert', id?, prefix, manualStart, no, spacing, y, z, frameNo, fa, sym, originalDigits }
                    property int pendingSuggestedAutoStart: 0
                    property string suffixChoiceReason: "" // 'overlap' | 'out-of-order'
                    property var pendingOnComplete: null

                    // Parse name into {prefix: upper, suffix: int|null, digits: string}
                    function parseNameParts(name) {
                        var t = String(name || "")
                        var m = /^([A-Za-z]*)(\d*)$/.exec(t)
                        var prefix = (m && m[1]) ? m[1].toUpperCase() : ""
                        var digits = (m && m[2]) ? m[2] : ""
                        var suffix = digits.length ? parseInt(digits) : null
                        return { prefix: prefix, suffix: suffix, digits: digits }
                    }

                    // Collect and MERGE existing ranges for a prefix, excluding a row id if provided
                    function collectRanges(prefix, excludeId) {
                        var arr = frameYZController.frameYZList || []
                        var ranges = []
                        for (var i = 0; i < arr.length; ++i) {
                            var it = arr[i]
                            if (!it || !it.name) continue
                            var p = parseNameParts(it.name)
                            if (p.prefix !== prefix) continue
                            if (excludeId && it.id === excludeId) continue
                            var start = (p.suffix !== null && !isNaN(p.suffix)) ? p.suffix : 0
                            var cnt = parseInt(it.no); if (isNaN(cnt) || cnt <= 0) continue // skip empty
                            var end = start + (cnt - 1)
                            ranges.push({ start: start, end: end })
                        }
                        // sort by start
                        ranges.sort(function(a,b){ return a.start - b.start })
                        // merge overlapping or adjacent ranges into disjoint groups
                        var merged = []
                        for (var j = 0; j < ranges.length; ++j) {
                            var r = ranges[j]
                            if (merged.length === 0) {
                                merged.push({ start: r.start, end: r.end })
                            } else {
                                var last = merged[merged.length - 1]
                                if (r.start <= last.end + 1) {
                                    // overlap or adjacent, extend
                                    if (r.end > last.end) last.end = r.end
                                } else {
                                    merged.push({ start: r.start, end: r.end })
                                }
                            }
                        }
                        return merged
                    }

                    function rangesOverlap(start, end, ranges) {
                        for (var i = 0; i < ranges.length; ++i) {
                            var r = ranges[i]
                            if (Math.max(start, r.start) <= Math.min(end, r.end)) return true
                        }
                        return false
                    }

                    function maxEnd(ranges) {
                        var m = -1
                        for (var i = 0; i < ranges.length; ++i) m = Math.max(m, ranges[i].end)
                        return m
                    }

                    // Find the smallest non-overlapping start >= 0 for a given range length
                    function findNextAvailableStart(no, ranges) {
                        var len = Math.max(0, parseInt(no) || 0)
                        if (len === 0) return 0
                        var cur = 0
                        for (var i = 0; i < ranges.length; ++i) {
                            var r = ranges[i]
                            // if there is enough space before this range, return cur
                            if (cur + len - 1 < r.start) return cur
                            // otherwise push cur to after this range
                            if (cur <= r.end) cur = r.end + 1
                        }
                        // after all ranges, cur is the first available spot
                        return cur
                    }

                    function isOutOfOrder(manualStart, ranges) {
                        var last = maxEnd(ranges)
                        return manualStart < (last + 1)
                    }

                    function buildName(prefix, start, originalDigits) {
                        // Keep digits as plain decimal; ignore original zero-padding for now
                        return String(prefix || "") + String(start)
                    }

                    function saveUpdate(rowId, nameVal, noVal, spacingVal, yVal, zVal, frameNoVal, faVal, symVal) {
                        frameYZController.updateFrameYZ(rowId, nameVal, noVal, spacingVal, yVal, zVal, frameNoVal, faVal, symVal)
                        Qt.callLater(function(){ dataChanged() })
                    }

                    function saveInsert(nameVal, noVal, spacingVal, yVal, zVal, frameNoVal, faVal, symVal) {
                        frameYZController.insertFrameYZ(nameVal, noVal, spacingVal, yVal, zVal, frameNoVal, faVal, symVal)
                        Qt.callLater(function(){ dataChanged() })
                    }

                    function performPendingSave(keepManual) {
                        if (!pendingOp) return
                        var op = pendingOp
                        var ranges = collectRanges(op.prefix, op.mode === 'update' ? op.id : null)
                        var start = (keepManual && op.manualStart !== null && op.manualStart !== undefined) ? op.manualStart : findNextAvailableStart(op.no, ranges)
                        var nameVal = buildName(op.prefix, start, op.originalDigits)
                        if (op.mode === 'update') {
                            saveUpdate(op.id, nameVal, op.no, op.spacing, op.y, op.z, op.frameNo, op.fa, op.sym)
                        } else {
                            saveInsert(nameVal, op.no, op.spacing, op.y, op.z, op.frameNo, op.fa, op.sym)
                        }
                        // Complete callback if provided (e.g., refocus shadow row)
                        if (pendingOnComplete && typeof pendingOnComplete === 'function') {
                            Qt.callLater(function(){ try { pendingOnComplete() } catch(e){} })
                        }
                        pendingOp = null
                        pendingOnComplete = null
                        pendingSuggestedAutoStart = 0
                        suffixChoiceReason = ""
                        if (suffixChoicePopup.visible) suffixChoicePopup.close()
                    }

                    // Expose small helpers for external popup handlers if needed
                    function setPendingStartSuffix(s) { if (pendingOp) pendingOp.manualStart = parseInt(s) }
                    function setPendingIgnoreOrder(b) { if (pendingOp) pendingOp.ignoreOrder = !!b }

                    // Unified save with rules: may save immediately or prompt if manual out-of-order/overlap
                    function handleSaveWithRules(op, onComplete) {
                        pendingOnComplete = onComplete || null
                        var ranges = collectRanges(op.prefix, op.mode === 'update' ? op.id : null)
                        // Decide manual vs auto
                        if (op.manualStart === null || op.manualStart === undefined) {
                            // Auto: pick first available and save
                            var autoStart = findNextAvailableStart(op.no, ranges)
                            var nameVal = buildName(op.prefix, autoStart, op.originalDigits)
                            if (op.mode === 'update') saveUpdate(op.id, nameVal, op.no, op.spacing, op.y, op.z, op.frameNo, op.fa, op.sym)
                            else saveInsert(nameVal, op.no, op.spacing, op.y, op.z, op.frameNo, op.fa, op.sym)
                            if (pendingOnComplete && typeof pendingOnComplete === 'function') {
                                Qt.callLater(function(){ try { pendingOnComplete() } catch(e){} })
                            }
                            pendingOnComplete = null
                            return
                        }
                        // Manual start provided: check order and overlaps
                        var start = op.manualStart
                        var end = start + Math.max(0, (parseInt(op.no) || 0) - 1)
                        var overlap = rangesOverlap(start, end, ranges)
                        var outOfOrder = isOutOfOrder(start, ranges)
                        var ignoreOrder = !!op.ignoreOrder
                        var orderBlocked = ignoreOrder ? false : outOfOrder
                        if (!overlap && !orderBlocked) {
                            var nameDirect = buildName(op.prefix, start, op.originalDigits)
                            if (op.mode === 'update') saveUpdate(op.id, nameDirect, op.no, op.spacing, op.y, op.z, op.frameNo, op.fa, op.sym)
                            else saveInsert(nameDirect, op.no, op.spacing, op.y, op.z, op.frameNo, op.fa, op.sym)
                            if (pendingOnComplete && typeof pendingOnComplete === 'function') {
                                Qt.callLater(function(){ try { pendingOnComplete() } catch(e){} })
                            }
                            pendingOnComplete = null
                            return
                        }
                        // Need prompt
                        pendingOp = op
                        pendingSuggestedAutoStart = findNextAvailableStart(op.no, ranges)
                        if (op.mode === 'update') {
                            // For updating Name: show choice popup (Continue vs Manual typed)
                            var groups = []
                            for (var gi=0; gi<ranges.length; ++gi) groups.push({ startSuffix: ranges[gi].start, endSuffix: ranges[gi].end })
                            addChoicePopup.prefix = op.prefix
                            addChoicePopup.mode = 'update'
                            addChoicePopup.groups = groups
                            addChoicePopup.stage = 'choice'
                            addChoicePopup.open()
                            return
                        }
                        // Insert flow: use suffixChoicePopup (legacy) for conflict/out-of-order
                        suffixChoiceReason = overlap ? 'overlap' : 'out-of-order'
                        suffixChoicePopup.prefix = op.prefix
                        suffixChoicePopup.manualStartSuffix = start
                        suffixChoicePopup.suggestedStartSuffix = pendingSuggestedAutoStart
                        suffixChoicePopup.suggestedCount = op.no
                        var confl = []
                        for (var i=0;i<ranges.length;++i) {
                            confl.push({ startSuffix: ranges[i].start, endSuffix: ranges[i].end, reason: '' })
                        }
                        suffixChoicePopup.conflictingRanges = confl
                        suffixChoicePopup.open()
                    }
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 35
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#bdc3c7"
                        border.width: 0.5

                        // Row data shortcut
                        property var row: modelData

                        // Column dependency validation: Y and Z are mutually exclusive
                        // Y has value if not empty string (0 is valid value)
                        property bool yHasValue: yInput.text !== ""
                        // Z has value if not empty string (0 is valid value)  
                        property bool zHasValue: zInput.text !== ""
                        property bool yEnabled: !zHasValue
                        property bool zEnabled: !yHasValue

                        // Is the target column enabled for this row?
                        function isColumnEnabled(col) {
                            if (col === 3) return yEnabled
                            if (col === 4) return zEnabled
                            return true
                        }

                        // Focus a specific column editor in this row (skips to paired Y/Z if disabled)
                        function focusColumn(col) {
                            var targetCol = col
                            if (targetCol === 3 && !yEnabled && zEnabled) targetCol = 4
                            else if (targetCol === 4 && !zEnabled && yEnabled) targetCol = 3
                            yzList.focusedColumn = targetCol
                            if (targetCol === 0) {
                                if (nameInput) { nameInput.forceActiveFocus(); nameInput.selectAll() }
                            } else if (targetCol === 1) {
                                if (noInput) { noInput.forceActiveFocus(); noInput.selectAll() }
                            } else if (targetCol === 2) {
                                if (spacingInput) { spacingInput.forceActiveFocus(); spacingInput.selectAll() }
                            } else if (targetCol === 3) {
                                if (yInput) { yInput.forceActiveFocus(); yInput.selectAll() }
                            } else if (targetCol === 4) {
                                if (zInput) { zInput.forceActiveFocus(); zInput.selectAll() }
                            } else if (targetCol === 5) {
                                if (frameNoInput) { frameNoInput.forceActiveFocus(); frameNoInput.selectAll() }
                            } else if (targetCol === 6) {
                                if (faComboBox) { faComboBox.forceActiveFocus() }
                            } else if (targetCol === 7) {
                                if (symComboBox) { symComboBox.forceActiveFocus() }
                            }
                        }

                        // Commit row update with current editor values
                        function commitUpdate() {
                            if (!row || !row.id) return
                            var inputName = String(nameInput.text || "")
                            var modelName = String(row.name || "")
                            var noVal = parseInt(noInput.text); if (isNaN(noVal)) noVal = 0
                            var spacingVal = parseFloat(spacingInput.text); if (isNaN(spacingVal)) spacingVal = 0
                            var yVal = yInput.text.trim() === "" ? "" : parseFloat(yInput.text)
                            var zVal = zInput.text.trim() === "" ? "" : parseFloat(zInput.text)
                            var frameNoVal = parseInt(frameNoInput.text); if (isNaN(frameNoVal)) frameNoVal = 0
                            var faVal = faComboBox.currentText || (row.fa || "F")
                            var symVal = symComboBox.currentText || (row.sym || "P")

                            if (inputName === modelName) {
                                // Name tidak berubah -> commit langsung kolom lain, tanpa popup/rules
                                yzList.saveUpdate(row.id, modelName, noVal, spacingVal, yVal, zVal, frameNoVal, faVal, symVal)
                                return
                            }

                            // Name berubah -> jalankan rules (dapat memunculkan popup jika perlu)
                            var parts = yzList.parseNameParts(inputName)
                            var prefix = parts.prefix && parts.prefix.length > 0 ? parts.prefix : "L"
                            var manualStart = parts.suffix // may be null
                            yzList.handleSaveWithRules({
                                mode: 'update',
                                id: row.id,
                                prefix: prefix,
                                manualStart: manualStart,
                                no: noVal,
                                spacing: spacingVal,
                                y: yVal,
                                z: zVal,
                                frameNo: frameNoVal,
                                fa: faVal,
                                sym: symVal,
                                originalDigits: parts.digits
                            })
                        }

                        // Move horizontally across cells, skipping disabled Y/Z, wrapping across rows
                        function moveHorizontal(dir) {
                            var col = yzList.focusedColumn
                            var rowIdx = index
                            var maxCol = 7
                            for (var step = 0; step < 16; ++step) { // safety bound
                                col = col + dir
                                if (col > maxCol) { col = 0; rowIdx += 1 }
                                else if (col < 0) { col = maxCol; rowIdx -= 1 }

                                if (rowIdx < 0) {
                                    return // out of bounds upwards, stop
                                }
                                if (rowIdx >= yzList.count) {
                                    // Move to footer on rightward navigation
                                    if (dir > 0 && yzList.footerItem && yzList.footerItem.focusColumn) {
                                        yzList.footerItem.focusColumn(0)
                                    }
                                    return
                                }

                                var item = yzList.itemAtIndex(rowIdx)
                                if (!item) {
                                    // Make row current and schedule focus when it instantiates
                                    yzList.currentIndex = rowIdx
                                    var targetCol = col
                                    Qt.callLater(function() {
                                        var it = yzList.itemAtIndex(rowIdx)
                                        if (it && it.focusColumn) {
                                            yzList.focusedColumn = targetCol
                                            it.focusColumn(targetCol)
                                        }
                                    })
                                    return
                                }
                                var enabled = true
                                if (col === 3) enabled = item.yEnabled
                                else if (col === 4) enabled = item.zEnabled
                                if (enabled) {
                                    if (rowIdx !== index) {
                                        yzList.currentIndex = rowIdx
                                    }
                                    yzList.focusedColumn = col
                                    item.focusColumn(col)
                                    return
                                }
                            }
                        }

                        function moveVertical(dir) {
                            var nextIndex = index + dir
                            if (nextIndex < 0) return
                            if (nextIndex >= yzList.count) {
                                // Move to footer (shadow row) when going down from last row
                                if (yzList.footerItem && yzList.footerItem.focusColumn) {
                                    yzList.footerItem.focusColumn(yzList.focusedColumn)
                                }
                                return
                            }
                            yzList.currentIndex = nextIndex
                            var item = yzList.itemAtIndex(nextIndex)
                            var targetCol = yzList.focusedColumn
                            if (item && item.focusColumn) {
                                // If targeting Y/Z and disabled in that row, switch to the paired column
                                if (targetCol === 3 && !item.yEnabled && item.zEnabled) targetCol = 4
                                else if (targetCol === 4 && !item.zEnabled && item.yEnabled) targetCol = 3
                                item.focusColumn(targetCol)
                            } else {
                                // Schedule when item becomes available
                                (function(nextIndexCopy, targetColCopy){
                                    Qt.callLater(function(){
                                        var it = yzList.itemAtIndex(nextIndexCopy)
                                        if (it && it.focusColumn) {
                                            if (targetColCopy === 3 && !it.yEnabled && it.zEnabled) targetColCopy = 4
                                            else if (targetColCopy === 4 && !it.zEnabled && it.yEnabled) targetColCopy = 3
                                            it.focusColumn(targetColCopy)
                                        }
                                    })
                                })(nextIndex, targetCol)
                            }
                        }

                        // Handle left/right within cell: first collapse selection to edge, then move caret, then move cell at boundary
                        function handleLeftRight(input, col, dir, commit) {
                            // dir: -1 left, 1 right; commit: function to commit changes before leaving cell
                            var textLen = input.text ? input.text.length : 0
                            var hasSel = input.selectionStart !== input.selectionEnd
                            if (hasSel) {
                                var edge = dir < 0 ? Math.min(input.selectionStart, input.selectionEnd) : Math.max(input.selectionStart, input.selectionEnd)
                                input.cursorPosition = edge
                                input.deselect()
                                return true // handled, don't move focus yet
                            }
                            if (dir < 0) {
                                if (input.cursorPosition > 0) {
                                    return false // let default move caret left
                                } else {
                                    if (commit) commit()
                                    moveHorizontal(-1)
                                    return true
                                }
                            } else {
                                if (input.cursorPosition < textLen) {
                                    return false // let default move caret right
                                } else {
                                    if (commit) commit()
                                    moveHorizontal(1)
                                    return true
                                }
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 1
                            
                            // Name (editable prefix)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: nameInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.name) ? row.name : "L0"
                                    font.pixelSize: 10
                                    readOnly: false
                                    enabled: true
                                    color: "#000000"
                                    selectByMouse: true
                                    // Allow editing prefix freely; backend will recompute suffix on refresh
                                    // Only sanitize user edits; use programmaticChange guard
                                    property bool programmaticChange: false
                                    onTextChanged: {
                                        // Only sanitize while user is actively editing; keep model-provided text otherwise
                                        if (!nameInput.activeFocus || programmaticChange) return
                                        // Allow letters (prefix) + optional digits (manual start)
                                        var t = nameInput.text || ""
                                        var m = /^([A-Za-z]*)(\d*)/.exec(t)
                                        var prefix = (m && m[1]) ? m[1].toUpperCase() : ""
                                        var digits = (m && m[2]) ? m[2].replace(/[^0-9]/g, "") : ""
                                        var rebuilt = prefix + digits
                                        if (rebuilt !== t) nameInput.text = rebuilt
                                    }
                                    onEditingFinished: commitUpdate()
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 0 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var handled = handleLeftRight(nameInput, 0, -1, commitUpdate)
                                            event.accepted = handled
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var handled2 = handleLeftRight(nameInput, 0, 1, commitUpdate)
                                            event.accepted = handled2
                                        }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    // onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // No
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: noInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.no !== undefined) ? row.no : "0"
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 1 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var handled = handleLeftRight(noInput, 1, -1, commitUpdate)
                                            event.accepted = handled
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var handled2 = handleLeftRight(noInput, 1, 1, commitUpdate)
                                            event.accepted = handled2
                                        }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // Spacing
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: spacingInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.spacing !== undefined) ? row.spacing : "1"
                                    font.pixelSize: 10
                                    validator: DoubleValidator { bottom: 0; decimals: 3 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 2 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var handled = handleLeftRight(spacingInput, 2, -1, commitUpdate)
                                            event.accepted = handled
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var handled2 = handleLeftRight(spacingInput, 2, 1, commitUpdate)
                                            event.accepted = handled2
                                        }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // Y [mm]
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: yEnabled ? "transparent" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: yInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.y !== undefined && row.y !== null && row.y !== "") ? String(row.y) : ""
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: yEnabled
                                    color: yEnabled ? "#000000" : "#999999"
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 3 }
                                    onTextChanged: {
                                        // If Y has value (not empty), clear Z
                                        if (yInput.text !== "" && zInput.text !== "") {
                                            zInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!yEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var handled = handleLeftRight(yInput, 3, -1, commitUpdate)
                                            event.accepted = handled
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var handled2 = handleLeftRight(yInput, 3, 1, commitUpdate)
                                            event.accepted = handled2
                                        }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: if (yEnabled) commitUpdate()
                                }
                            }
                            
                            // Z [mm]
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: zEnabled ? "transparent" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: zInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.z !== undefined && row.z !== null && row.z !== "") ? String(row.z) : ""
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: zEnabled
                                    color: zEnabled ? "#000000" : "#999999"
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 4 }
                                    onTextChanged: {
                                        // If Z has value (not empty), clear Y
                                        if (zInput.text !== "" && yInput.text !== "") {
                                            yInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!zEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var handled = handleLeftRight(zInput, 4, -1, commitUpdate)
                                            event.accepted = handled
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var handled2 = handleLeftRight(zInput, 4, 1, commitUpdate)
                                            event.accepted = handled2
                                        }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: if (zEnabled) commitUpdate()
                                }
                            }
                            
                            // Frame No.
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                TextInput {
                                    id: frameNoInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: (row && row.frameNo !== undefined) ? row.frameNo : "24"
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 5 }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { commitUpdate(); moveHorizontal(event.modifiers & Qt.ShiftModifier ? -1 : 1); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var handled = handleLeftRight(frameNoInput, 5, -1, commitUpdate)
                                            event.accepted = handled
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var handled2 = handleLeftRight(frameNoInput, 5, 1, commitUpdate)
                                            event.accepted = handled2
                                        }
                                        else if (event.key === Qt.Key_Up) { commitUpdate(); moveVertical(-1); event.accepted = true }
                                        else if (event.key === Qt.Key_Down) { commitUpdate(); moveVertical(1); event.accepted = true }
                                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { commitUpdate(); moveHorizontal(1); event.accepted = true }
                                    }
                                    onEditingFinished: commitUpdate()
                                }
                            }
                            
                            // F/A
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                CustomComboBox {
                                    id: faComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "F" }, { name: "A" }, { name: "F+A" } ]
                                    textRole: "name"
                                    
                                    property string savedValue: ""
                                    property bool dropdownOpen: popup.visible
                                    
                                    // Map existing stored values to index heuristically
                                    Component.onCompleted: {
                                        var val = row ? row.fa : "F"
                                        var idx = 0
                                        if (val === "F" || val === "0") idx = 0
                                        else if (val === "A" || val === "1") idx = 1
                                        else if (val === "F+A" || val === "2") idx = 2
                                        currentIndex = idx
                                        savedValue = currentText
                                    }
                                    font.pixelSize: 9
                                    focusPolicy: Qt.TabFocus
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 6 }

                                    // Write-through to DB and redraw
                                    commitCallback: function(txt) {
                                        // Commit entire row using the same path as other columns
                                        if (row && row.id) {
                                            commitUpdate()
                                        }
                                    }
                                    redrawCallback: function() {
                                        moveHorizontal(1)
                                    }
                                }
                            }
                            
                            // Sym.
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                CustomComboBox {
                                    id: symComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "P" }, { name: "S" }, { name: "P+S" } ]
                                    textRole: "name"
                                    
                                    property string savedValue: ""
                                    property bool dropdownOpen: popup.visible
                                    
                                    Component.onCompleted: {
                                        var val = row ? row.sym : "P"
                                        var idx = 0
                                        if (val === "P" || val === "0") idx = 0
                                        else if (val === "S" || val === "1") idx = 1
                                        else if (val === "P+S" || val === "2") idx = 2
                                        currentIndex = idx
                                        savedValue = currentText
                                    }
                                    font.pixelSize: 9
                                    focusPolicy: Qt.TabFocus
                                    onActiveFocusChanged: if (activeFocus) { yzList.currentIndex = index; yzList.focusedColumn = 7 }

                                    commitCallback: function(txt) {
                                        // Commit entire row using the same path as other columns
                                        if (row && row.id) {
                                            commitUpdate()
                                        }
                                    }
                                    redrawCallback: function() {
                                        moveHorizontal(1)
                                    }
                                }
                            }
                            
                            // Action
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "transparent"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                
                                // Trash icon (like XZInput)
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 18
                                    color: "transparent"

                                    // Trash lid
                                    Rectangle {
                                        width: 14
                                        height: 2
                                        color: "#f44336"
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    // Trash handle
                                    Rectangle {
                                        width: 6
                                        height: 2
                                        color: "#f44336"
                                        anchors.top: parent.top
                                        anchors.topMargin: -2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    // Trash body
                                    Rectangle {
                                        width: 12
                                        height: 14
                                        color: "#f44336"
                                        anchors.top: parent.top
                                        anchors.topMargin: 2
                                        anchors.horizontalCenter: parent.horizontalCenter

                                        // Vertical lines inside trash
                                        Rectangle { width: 1; height: 10; color: "white"; anchors.left: parent.left; anchors.leftMargin: 3; anchors.top: parent.top; anchors.topMargin: 2 }
                                        Rectangle { width: 1; height: 10; color: "white"; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 2 }
                                        Rectangle { width: 1; height: 10; color: "white"; anchors.right: parent.right; anchors.rightMargin: 3; anchors.top: parent.top; anchors.topMargin: 2 }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: { parent.scale = 1.1 }
                                        onExited: { parent.scale = 1.0 }
                                        onClicked: {
                                            if (row && row.id) { frameYZController.deleteFrameYZ(row.id) }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Shadow row footer to add new frame based on last row
                    footer: Rectangle {
                        id: yzShadowRow
                        width: ListView.view.width
                        height: 38
                        color: "#eef6ff"
                        border.color: "#bdc3c7"
                        border.width: 0.5

                        // Shadow state defaults (mirror last row when possible)
                        // shadowName stores only the PREFIX (letters), suffix is auto-generated by backend based on No
                        property string shadowName: "L"
                        property int shadowNo: 0
                        property double shadowSpacing: 1
                        property double shadowY: 0
                        property double shadowZ: 0
                        property int shadowFrameNo: 0
                        property string shadowFa: "0"
                        property string shadowSym: "0"
                        // Flag to indicate AddChoice popup was opened by footer (shadow row) flow
                        property bool activeAddFlow: false

                        // Column dependency validation for shadow row
                        // Y has value if not empty string (0 is valid value)
                        property bool shadowYHasValue: shadowYInput.text !== ""
                        // Z has value if not empty string (0 is valid value)
                        property bool shadowZHasValue: shadowZInput.text !== ""
                        property bool shadowYEnabled: !shadowZHasValue
                        property bool shadowZEnabled: !shadowYHasValue

                        function lastData() {
                            var arr = frameYZController.frameYZList || []
                            if (!arr || arr.length === 0) return null
                            return arr[arr.length - 1]
                        }

                        // Helper: extract uppercase letter prefix from a name string
                        function extractPrefix(str) {
                            var m = /^([A-Za-z]*)/.exec(str || "")
                            return (m && m[1]) ? m[1].toUpperCase() : ""
                        }

                        // Determine default prefix for the shadow row: user's typed prefix if any, else last-row prefix, else "L"
                        function computeDefaultPrefix() {
                            var typed = shadowNameInput && shadowNameInput.text ? extractPrefix(String(shadowNameInput.text)) : ""
                            if (typed && typed.length > 0) return typed
                            var arr = frameYZController.frameYZList || []
                            if (arr && arr.length > 0) {
                                var last = arr[arr.length - 1]
                                var lname = (last && last.name) ? String(last.name) : "L"
                                var lp = extractPrefix(lname)
                                if (lp && lp.length > 0) return lp
                            }
                            return "L"
                        }

                        function autoUpdateFromLastRow() {
                            var last = lastData()
                            if (last) {
                                // Keep only PREFIX in the input; suffix is generated automatically in backend
                                shadowName = computeDefaultPrefix()
                                shadowNo = (last.no !== undefined) ? (parseInt(last.no) || 0) : 0
                                shadowSpacing = (last.spacing !== undefined) ? (parseFloat(last.spacing) || 1) : 1
                                shadowY = (last.y !== undefined) ? (parseFloat(last.y) || 0) : 0
                                shadowZ = (last.z !== undefined) ? (parseFloat(last.z) || 0) : 0
                                shadowFrameNo = (last.frameNo !== undefined) ? (parseInt(last.frameNo) || 0) + 1 : 0
                                shadowFa = (last.fa !== undefined) ? ("" + last.fa) : "0"
                                shadowSym = (last.sym !== undefined) ? ("" + last.sym) : "0"
                            } else {
                                shadowName = "L"
                                shadowNo = 0
                                shadowSpacing = 1
                                shadowY = 0
                                shadowZ = 0
                                shadowFrameNo = 0
                                shadowFa = "0"
                                shadowSym = "0"
                            }
                        }

                        // Pending fields for add flow
                        property string pendingPrefix: ""
                        property int pendingNo: 0
                        property real pendingSpacing: 0
                        property var pendingY: ""
                        property var pendingZ: ""
                        property int pendingFrameNo: 0
                        property string pendingFa: "F"
                        property string pendingSym: "P"

                        function addShadowRow() {
                            // Gather current editor texts; only PREFIX is taken from name input
                            var prefix = computeDefaultPrefix()
                            var noVal = parseInt(shadowNoInput.text); if (isNaN(noVal)) noVal = 0
                            var spacingVal = parseFloat(shadowSpacingInput.text); if (isNaN(spacingVal)) spacingVal = 0
                            var yVal = shadowYInput.text.trim() === "" ? "" : parseFloat(shadowYInput.text)
                            var zVal = shadowZInput.text.trim() === "" ? "" : parseFloat(shadowZInput.text)
                            var frameNoVal = parseInt(shadowFrameNoInput.text); if (isNaN(frameNoVal)) frameNoVal = 0
                            var faVal = shadowFaComboBox.currentText || "F"
                            var symVal = shadowSymComboBox.currentText || "P"

                            // store pending
                            pendingPrefix = prefix
                            pendingNo = noVal
                            pendingSpacing = spacingVal
                            pendingY = yVal
                            pendingZ = zVal
                            pendingFrameNo = frameNoVal
                            pendingFa = faVal
                            pendingSym = symVal

                            // compute groups for this prefix
                            var ranges = yzList.collectRanges(prefix, null)
                            var groups = []
                            for (var i=0;i<ranges.length;++i) {
                                groups.push({ startSuffix: ranges[i].start, endSuffix: ranges[i].end })
                            }

                            addChoicePopup.prefix = prefix
                            addChoicePopup.mode = 'add'
                            addChoicePopup.groups = groups
                            addChoicePopup.stage = "choice"
                            activeAddFlow = true
                            addChoicePopup.open()
                        }

                        // Allow external focus routing (from data row) by column index
                        function focusColumn(col) {
                            if (col === 0) {
                                if (shadowNameInput) { shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll() }
                            } else if (col === 1) {
                                if (shadowNoInput) { shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll() }
                            } else if (col === 2) {
                                if (shadowSpacingInput) { shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll() }
                            } else if (col === 3) {
                                if (shadowYInput) { shadowYInput.forceActiveFocus(); shadowYInput.selectAll() }
                            } else if (col === 4) {
                                if (shadowZInput) { shadowZInput.forceActiveFocus(); shadowZInput.selectAll() }
                            } else if (col === 5) {
                                if (shadowFrameNoInput) { shadowFrameNoInput.forceActiveFocus(); shadowFrameNoInput.selectAll() }
                            } else if (col === 6) {
                                if (shadowFaComboBox) { shadowFaComboBox.forceActiveFocus() }
                            } else if (col === 7) {
                                if (shadowSymComboBox) { shadowSymComboBox.forceActiveFocus() }
                            }
                        }

                        Component.onCompleted: autoUpdateFromLastRow()
                        Connections {
                            target: frameYZController
                            function onFrameYZListChanged() { yzShadowRow.autoUpdateFromLastRow() }
                        }

                        // Handle addChoicePopup signals
                        Connections {
                            target: addChoicePopup
                            function onChooseContinue(startSuffix) {
                                // Shadow-row flow: only act if this footer initiated the popup
                                if (yzShadowRow.activeAddFlow === true) {
                                    yzList.handleSaveWithRules({
                                        mode: 'insert',
                                        prefix: yzShadowRow.pendingPrefix,
                                        manualStart: startSuffix,
                                        no: yzShadowRow.pendingNo,
                                        spacing: yzShadowRow.pendingSpacing,
                                        y: yzShadowRow.pendingY,
                                        z: yzShadowRow.pendingZ,
                                        frameNo: yzShadowRow.pendingFrameNo,
                                        fa: yzShadowRow.pendingFa,
                                        sym: yzShadowRow.pendingSym,
                                        originalDigits: "",
                                        ignoreOrder: true
                                    }, function(){ if (shadowNameInput) { shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll() } })
                                    yzShadowRow.activeAddFlow = false
                                }
                            }
                            function onChooseManual() {
                                if (yzShadowRow.activeAddFlow === true) {
                                    manualNamePopup.prefix = yzShadowRow.pendingPrefix
                                    manualNamePopup.mode = 'add'
                                    var ranges2 = yzList.collectRanges(yzShadowRow.pendingPrefix, null)
                                    manualNamePopup.defaultSuffix = yzList.findNextAvailableStart(yzShadowRow.pendingNo, ranges2)
                                    manualNamePopup.presetSuffix = -1
                                    manualNamePopup.open()
                                }
                            }
                            function onCancelled() {
                                yzShadowRow.activeAddFlow = false
                            }
                        }

                        // Handle manualNamePopup return
                        Connections {
                            target: manualNamePopup
                            function onAccepted(suffix) {
                                if (yzShadowRow.activeAddFlow === true) {
                                    yzList.handleSaveWithRules({
                                        mode: 'insert',
                                        prefix: yzShadowRow.pendingPrefix,
                                        manualStart: suffix,
                                        no: yzShadowRow.pendingNo,
                                        spacing: yzShadowRow.pendingSpacing,
                                        y: yzShadowRow.pendingY,
                                        z: yzShadowRow.pendingZ,
                                        frameNo: yzShadowRow.pendingFrameNo,
                                        fa: yzShadowRow.pendingFa,
                                        sym: yzShadowRow.pendingSym,
                                        originalDigits: ""
                                    }, function(){ if (shadowNameInput) { shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll() } })
                                    yzShadowRow.activeAddFlow = false
                                }
                            }
                            function onCancelled() { yzShadowRow.activeAddFlow = false }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 1

                            // Name (shadow; user can edit prefix)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowNameInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    // Show and edit PREFIX only (letters). Suffix will be selected via popup flow.
                                    text: yzShadowRow.shadowName && yzShadowRow.shadowName.length > 0 ? yzShadowRow.shadowName : yzShadowRow.computeDefaultPrefix()
                                    font.pixelSize: 10
                                    readOnly: false
                                    enabled: true
                                    color: "#000000"
                                    selectByMouse: true
                                    // Sanitize to letters only; uppercase letters, strip digits/others
                                    onTextChanged: {
                                        var t = shadowNameInput.text || ""
                                        var m = /^([A-Za-z]*)/.exec(t)
                                        var prefix = (m && m[1]) ? m[1].toUpperCase() : ""
                                        var rebuilt = prefix
                                        if (rebuilt !== t) shadowNameInput.text = rebuilt
                                        yzShadowRow.shadowName = prefix && prefix.length > 0 ? rebuilt : yzShadowRow.computeDefaultPrefix()
                                    }
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 1; shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var tlen = shadowNameInput.text ? shadowNameInput.text.length : 0
                                            if (shadowNameInput.selectionStart !== shadowNameInput.selectionEnd) {
                                                shadowNameInput.cursorPosition = Math.min(shadowNameInput.selectionStart, shadowNameInput.selectionEnd)
                                                shadowNameInput.deselect(); event.accepted = true
                                            } else if (shadowNameInput.cursorPosition > 0) {
                                                event.accepted = false
                                            } else {
                                                // wrap to last column of last data row
                                                if (yzList.count > 0) {
                                                    var last = yzList.itemAtIndex(yzList.count - 1)
                                                    if (last && last.focusColumn) { yzList.focusedColumn = 7; last.focusColumn(7) }
                                                }
                                                event.accepted = true
                                            }
                                        }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 1; shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 0; last.focusColumn(0) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // No (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowNoInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowNo
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onTextChanged: yzShadowRow.shadowNo = parseInt(text) || 0
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 2; shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var hasSel = shadowNoInput.selectionStart !== shadowNoInput.selectionEnd
                                            if (hasSel) { shadowNoInput.cursorPosition = Math.min(shadowNoInput.selectionStart, shadowNoInput.selectionEnd); shadowNoInput.deselect(); event.accepted = true }
                                            else if (shadowNoInput.cursorPosition > 0) { event.accepted = false }
                                            else { yzList.focusedColumn = 0; shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var tlen = shadowNoInput.text ? shadowNoInput.text.length : 0
                                            if (shadowNoInput.selectionStart !== shadowNoInput.selectionEnd) { shadowNoInput.cursorPosition = Math.max(shadowNoInput.selectionStart, shadowNoInput.selectionEnd); shadowNoInput.deselect(); event.accepted = true }
                                            else if (shadowNoInput.cursorPosition < tlen) { event.accepted = false }
                                            else { yzList.focusedColumn = 2; shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 1; last.focusColumn(1) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Spacing (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowSpacingInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowSpacing
                                    font.pixelSize: 10
                                    validator: DoubleValidator { bottom: 0; decimals: 3 }
                                    selectByMouse: true
                                    onTextChanged: yzShadowRow.shadowSpacing = parseFloat(text) || 0
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 3; shadowYInput.forceActiveFocus(); shadowYInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var hasSel = shadowSpacingInput.selectionStart !== shadowSpacingInput.selectionEnd
                                            if (hasSel) { shadowSpacingInput.cursorPosition = Math.min(shadowSpacingInput.selectionStart, shadowSpacingInput.selectionEnd); shadowSpacingInput.deselect(); event.accepted = true }
                                            else if (shadowSpacingInput.cursorPosition > 0) { event.accepted = false }
                                            else { yzList.focusedColumn = 1; shadowNoInput.forceActiveFocus(); shadowNoInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var tlen = shadowSpacingInput.text ? shadowSpacingInput.text.length : 0
                                            if (shadowSpacingInput.selectionStart !== shadowSpacingInput.selectionEnd) { shadowSpacingInput.cursorPosition = Math.max(shadowSpacingInput.selectionStart, shadowSpacingInput.selectionEnd); shadowSpacingInput.deselect(); event.accepted = true }
                                            else if (shadowSpacingInput.cursorPosition < tlen) { event.accepted = false }
                                            else { yzList.focusedColumn = 3; shadowYInput.forceActiveFocus(); shadowYInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 2; last.focusColumn(2) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Y [mm] (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: yzShadowRow.shadowYEnabled ? "#ffffff" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowYInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowY
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: yzShadowRow.shadowYEnabled
                                    color: yzShadowRow.shadowYEnabled ? "#000000" : "#999999"
                                    onTextChanged: {
                                        yzShadowRow.shadowY = parseFloat(text) || 0
                                        // If Y has value (not empty), clear Z
                                        if (shadowYInput.text !== "" && shadowZInput.text !== "") {
                                            shadowZInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!yzShadowRow.shadowYEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 4; shadowZInput.forceActiveFocus(); shadowZInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var hasSel = shadowYInput.selectionStart !== shadowYInput.selectionEnd
                                            if (hasSel) { shadowYInput.cursorPosition = Math.min(shadowYInput.selectionStart, shadowYInput.selectionEnd); shadowYInput.deselect(); event.accepted = true }
                                            else if (shadowYInput.cursorPosition > 0) { event.accepted = false }
                                            else { yzList.focusedColumn = 2; shadowSpacingInput.forceActiveFocus(); shadowSpacingInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var tlen = shadowYInput.text ? shadowYInput.text.length : 0
                                            if (shadowYInput.selectionStart !== shadowYInput.selectionEnd) { shadowYInput.cursorPosition = Math.max(shadowYInput.selectionStart, shadowYInput.selectionEnd); shadowYInput.deselect(); event.accepted = true }
                                            else if (shadowYInput.cursorPosition < tlen) { event.accepted = false }
                                            else { yzList.focusedColumn = 4; shadowZInput.forceActiveFocus(); shadowZInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 3; last.focusColumn(3) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Z [mm] (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: yzShadowRow.shadowZEnabled ? "#ffffff" : "#f0f0f0"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowZInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowZ
                                    font.pixelSize: 10
                                    validator: DoubleValidator { decimals: 3 }
                                    selectByMouse: true
                                    enabled: yzShadowRow.shadowZEnabled
                                    color: yzShadowRow.shadowZEnabled ? "#000000" : "#999999"
                                    onTextChanged: {
                                        yzShadowRow.shadowZ = parseFloat(text) || 0
                                        // If Z has value (not empty), clear Y
                                        if (shadowZInput.text !== "" && shadowYInput.text !== "") {
                                            shadowYInput.text = ""
                                        }
                                    }
                                    Keys.onPressed: {
                                        if (!yzShadowRow.shadowZEnabled) { event.accepted = true; return }
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 5; shadowFrameNoInput.forceActiveFocus(); shadowFrameNoInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) {
                                            var hasSel = shadowZInput.selectionStart !== shadowZInput.selectionEnd
                                            if (hasSel) { shadowZInput.cursorPosition = Math.min(shadowZInput.selectionStart, shadowZInput.selectionEnd); shadowZInput.deselect(); event.accepted = true }
                                            else if (shadowZInput.cursorPosition > 0) { event.accepted = false }
                                            else { yzList.focusedColumn = 3; shadowYInput.forceActiveFocus(); shadowYInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Right) {
                                            var tlen = shadowZInput.text ? shadowZInput.text.length : 0
                                            if (shadowZInput.selectionStart !== shadowZInput.selectionEnd) { shadowZInput.cursorPosition = Math.max(shadowZInput.selectionStart, shadowZInput.selectionEnd); shadowZInput.deselect(); event.accepted = true }
                                            else if (shadowZInput.cursorPosition < tlen) { event.accepted = false }
                                            else { yzList.focusedColumn = 5; shadowFrameNoInput.forceActiveFocus(); shadowFrameNoInput.selectAll(); event.accepted = true }
                                        }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 4; last.focusColumn(4) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // Frame No. (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                TextInput {
                                    id: shadowFrameNoInput
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    text: yzShadowRow.shadowFrameNo
                                    font.pixelSize: 10
                                    validator: IntValidator { bottom: 0 }
                                    selectByMouse: true
                                    onTextChanged: yzShadowRow.shadowFrameNo = parseInt(text) || 0
                                    Keys.onPressed: {
                                        if (event.key === Qt.Key_Tab) { yzList.focusedColumn = 6; shadowFaComboBox.forceActiveFocus(); event.accepted = true }
                                        else if (event.key === Qt.Key_Left) { yzList.focusedColumn = 4; shadowZInput.forceActiveFocus(); shadowZInput.selectAll(); event.accepted = true }
                                        else if (event.key === Qt.Key_Right) { yzList.focusedColumn = 6; shadowFaComboBox.forceActiveFocus(); event.accepted = true }
                                        else if (event.key === Qt.Key_Up) {
                                            if (yzList.count > 0) {
                                                var last = yzList.itemAtIndex(yzList.count - 1)
                                                if (last && last.focusColumn) { yzList.focusedColumn = 5; last.focusColumn(5) }
                                            }
                                            event.accepted = true
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { yzShadowRow.addShadowRow(); event.accepted = true }
                                    }
                                }
                            }

                            // F/A (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                CustomComboBox {
                                    id: shadowFaComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "F" }, { name: "A" }, { name: "F+A" } ]
                                    textRole: "name"
                                    
                                    property string savedValue: ""
                                    property bool dropdownOpen: popup.visible
                                    
                                    Component.onCompleted: {
                                        var v = yzShadowRow.shadowFa
                                        if (v === "F" || v === "0") currentIndex = 0
                                        else if (v === "A" || v === "1") currentIndex = 1
                                        else if (v === "F+A" || v === "2") currentIndex = 2
                                        savedValue = currentText
                                    }
                                    font.pixelSize: 9
                                    commitCallback: function(txt) { yzShadowRow.shadowFa = txt }
                                    redrawCallback: function() { yzList.focusedColumn = 7; shadowSymComboBox.forceActiveFocus() }
                                }
                            }

                            // Sym (shadow)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#ffffff"
                                border.color: "#bdc3c7"
                                border.width: 0.5
                                CustomComboBox {
                                    id: shadowSymComboBox
                                    anchors.centerIn: parent
                                    width: parent.width - 4
                                    height: parent.height - 4
                                    model: [ { name: "P" }, { name: "S" }, { name: "P+S" } ]
                                    textRole: "name"
                                    
                                    property string savedValue: ""
                                    property bool dropdownOpen: popup.visible
                                    
                                    Component.onCompleted: {
                                        var v = yzShadowRow.shadowSym
                                        if (v === "P" || v === "0") currentIndex = 0
                                        else if (v === "S" || v === "1") currentIndex = 1
                                        else if (v === "P+S" || v === "2") currentIndex = 2
                                        savedValue = currentText
                                    }
                                    font.pixelSize: 9
                                    commitCallback: function(txt) { yzShadowRow.shadowSym = txt }
                                    redrawCallback: function() { yzList.focusedColumn = 0; shadowNameInput.forceActiveFocus(); shadowNameInput.selectAll() }
                                }
                            }

                            // Action column (Add) styled like XZInput
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                border.width: 0.5
                                border.color: "#bdc3c7"
                                color: "#f8f8f8"
                                Text {
                                    anchors.centerIn: parent
                                    text: "Add"
                                    font.pixelSize: 10
                                    color: "#2196F3"
                                    font.bold: true
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: yzShadowRow.addShadowRow()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dialog to choose between keeping manual suffix or switching to auto to avoid conflict/out-of-order
    // Modular popup component for suffix decisions
    PopUpSuffix {
        id: suffixChoicePopup
        onAcceptedAuto: function(continueFromName, startSuffix) { yzList.performPendingSave(false) }
        onAcceptedManual: function(startSuffix) { yzList.performPendingSave(true) }
        onCancelled: function() { /* no-op */ }
    }

    // Popup to choose add flow: continue sequence or manual, and select group
    PopUpAddChoice {
        id: addChoicePopup
    }

    // Popup to enter manual suffix for shadow row
    PopUpManualName {
        id: manualNamePopup
    }

    // Handle Name update flow using AddChoice popup when conflicts occur
    Connections {
        target: addChoicePopup
        function onChooseContinue(startSuffix) {
            // If a pending update operation exists, treat this as continue-sequence for update
            if (yzList.pendingOp && yzList.pendingOp.mode === 'update') {
                var op0 = yzList.pendingOp
                yzList.handleSaveWithRules({
                    mode: 'update',
                    id: op0.id,
                    prefix: op0.prefix,
                    manualStart: startSuffix,
                    no: op0.no,
                    spacing: op0.spacing,
                    y: op0.y,
                    z: op0.z,
                    frameNo: op0.frameNo,
                    fa: op0.fa,
                    sym: op0.sym,
                    originalDigits: op0.originalDigits,
                    ignoreOrder: true
                })
            }
        }
        function onChooseManual() {
            if (yzList.pendingOp && yzList.pendingOp.mode === 'update') {
                // Show manual popup; prefer the digits user typed earlier, fallback to next available
                manualNamePopup.prefix = yzList.pendingOp.prefix
                manualNamePopup.mode = 'update'
                var ranges3 = yzList.collectRanges(yzList.pendingOp.prefix, yzList.pendingOp.id)
                var typed = (yzList.pendingOp.manualStart !== null && yzList.pendingOp.manualStart !== undefined) ? yzList.pendingOp.manualStart : null
                manualNamePopup.defaultSuffix = yzList.findNextAvailableStart(yzList.pendingOp.no, ranges3)
                manualNamePopup.presetSuffix = (typed !== null ? typed : manualNamePopup.defaultSuffix)
                manualNamePopup.open()
            }
        }
    }
    Connections {
        target: manualNamePopup
        function onAccepted(suffix) {
            if (yzList.pendingOp && yzList.pendingOp.mode === 'update') {
                var op0 = yzList.pendingOp
                yzList.handleSaveWithRules({
                    mode: 'update',
                    id: op0.id,
                    prefix: op0.prefix,
                    manualStart: suffix,
                    no: op0.no,
                    spacing: op0.spacing,
                    y: op0.y,
                    z: op0.z,
                    frameNo: op0.frameNo,
                    fa: op0.fa,
                    sym: op0.sym,
                    originalDigits: op0.originalDigits
                })
            }
        }
    }
}