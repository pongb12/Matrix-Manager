/*
 * DuplicatesPage.qml — duplicate file detection (MM-032).
 *
 * Files are compared by size first and hashed only when needed, so scans
 * stay fast and deterministic. Groups are displayed with every member;
 * the user selects what to move to the trash and reviews the list before
 * anything happens. Nothing is ever deleted automatically (DOC.md rule 19).
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Core
import MatrixManager.Theme
import MatrixManager.Components

Page {
    id: page

    background: null

    property var groups: []
    property var summary: ({})
    property var selected: ({})

    readonly property int selectedCount: Object.keys(page.selected).length
    readonly property real selectedBytes: {
        let total = 0
        for (const path in page.selected)
            total += page.selected[path]
        return total
    }

    Component.onCompleted: {
        // QA hook: auto-start a duplicate scan (automated UI checks).
        if (typeof qaDupScanPath !== "undefined" && qaDupScanPath !== "")
            page.startScan(qaDupScanPath)
    }

    DuplicateScanner {
        id: scanner

        onProgressChanged: (filesSeen) => {
            progressDetail.text = SystemInfo.formatCount(filesSeen)
                                  + qsTr(" files checked")
        }

        onFinished: (rootPath, resultGroups, scanSummary) => {
            page.groups = resultGroups
            page.summary = scanSummary
            page.selected = {}
        }

        onFailed: (rootPath, message) => {
            page.summary = { errorCount: 1 }
            scanErrorDialog.message = message
            scanErrorDialog.open()
        }
    }

    function startScan(path) {
        page.groups = []
        page.summary = {}
        page.selected = {}
        scanner.start(path)
    }

    function isSelected(path) {
        return page.selected[path] !== undefined
    }

    function setSelected(groupIndex, file, checked) {
        const copy = Object.assign({}, page.selected)
        if (checked)
            copy[file.path] = file.size
        else
            delete copy[file.path]
        page.selected = copy
    }

    function selectAllButOldest(group) {
        const copy = Object.assign({}, page.selected)
        for (let i = 1; i < group.files.length; ++i)
            copy[group.files[i].path] = group.files[i].size
        page.selected = copy
    }

    function removePaths(paths) {
        const gone = {}
        for (let i = 0; i < paths.length; ++i)
            gone[paths[i]] = true
        const remaining = []
        for (let g = 0; g < page.groups.length; ++g) {
            const group = page.groups[g]
            const files = group.files.filter(f => !gone[f.path])
            if (files.length >= 2)
                remaining.push(Object.assign({}, group, { files: files }))
        }
        page.groups = remaining
        page.selected = {}
        page.summary = Object.assign({}, page.summary, {
            groupCount: remaining.length
        })
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingLG

        MPageHeader {
            title: qsTr("Duplicates")
            subtitle: qsTr("Find duplicate files — grouped by content, nothing is deleted automatically")
        }

        ScrollView {
            id: pageScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: pageScroll.width
                spacing: Theme.spacingLG

                // -------------------------------------------- tool card
                MCard {
                    Layout.fillWidth: true
                    implicitHeight: controls.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: controls
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSM

                            Text {
                                text: qsTr("Look in")
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textMuted
                            }
                            TextField {
                                id: pathField
                                Layout.fillWidth: true
                                text: StorageService.homePath()
                                font.pixelSize: Theme.fontSizeSM
                                font.family: Theme.monoFamily
                                selectByMouse: true
                                color: Theme.textPrimary
                                placeholderTextColor: Theme.textMuted

                                background: Rectangle {
                                    radius: Theme.radiusMD
                                    color: Theme.surfaceSunken
                                    border.width: pathField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                                    border.color: pathField.activeFocus ? Theme.focus : Theme.border
                                }

                                onAccepted: page.startScan(text)
                            }
                            MSecondaryButton {
                                text: qsTr("Home")
                                enabled: !scanner.running
                                onClicked: pathField.text = StorageService.homePath()
                            }
                            MButton {
                                text: scanner.running ? qsTr("Scanning…") : qsTr("Scan for duplicates")
                                enabled: !scanner.running
                                onClicked: page.startScan(pathField.text)
                            }
                        }

                        RowLayout {
                            visible: scanner.running
                            Layout.fillWidth: true
                            spacing: Theme.spacingMD

                            MProgressBar {
                                Layout.preferredWidth: 180
                                indeterminate: true
                            }
                            Text {
                                id: progressDetail
                                font.pixelSize: Theme.fontSizeSM
                                font.family: Theme.monoFamily
                                color: Theme.textSecondary
                            }
                            MSecondaryButton {
                                text: qsTr("Cancel scan")
                                onClicked: scanner.cancel()
                            }
                        }
                    }
                }

                // --------------------------------------- results header
                Text {
                    visible: page.groups.length > 0
                    text: qsTr("%1 groups · %2 reclaimable").arg(
                              page.groups.length).arg(
                              SystemInfo.formatBytes(page.summary.reclaimableBytes || 0))
                    font.pixelSize: Theme.fontSizeLG
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }

                // --------------------------------------------- groups
                Repeater {
                    model: page.groups

                    MCard {
                        id: groupCard
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: groupContent.implicitHeight + Theme.spacingLG * 2

                        ColumnLayout {
                            id: groupContent
                            anchors.fill: parent
                            anchors.margins: Theme.spacingLG
                            spacing: Theme.spacingSM

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSM

                                MBadge {
                                    text: qsTr("%1 copies · %2 each").arg(
                                              groupCard.modelData.files.length).arg(
                                              SystemInfo.formatBytes(groupCard.modelData.size))
                                    tone: "neutral"
                                }
                                Text {
                                    text: qsTr("%1 reclaimable").arg(
                                              SystemInfo.formatBytes(groupCard.modelData.wasted))
                                    font.pixelSize: Theme.fontSizeSM
                                    font.family: Theme.monoFamily
                                    color: Theme.textSecondary
                                    Layout.fillWidth: true
                                }
                                MSecondaryButton {
                                    text: qsTr("Select duplicates")
                                    enabled: !scanner.running
                                    onClicked: page.selectAllButOldest(groupCard.modelData)
                                }
                            }

                            Repeater {
                                model: groupCard.modelData.files

                                RowLayout {
                                    id: fileRow
                                    required property var modelData
                                    required property int index
                                    spacing: Theme.spacingSM

                                    MCheckBox {
                                        checked: page.isSelected(fileRow.modelData.path)
                                        enabled: !scanner.running
                                        onToggled: page.setSelected(
                                                       groupCard.index,
                                                       fileRow.modelData, checked)
                                    }
                                    ColumnLayout {
                                        spacing: 1
                                        Layout.fillWidth: true

                                        Text {
                                            text: fileRow.modelData.name
                                                  + (index === 0
                                                     ? qsTr("  · oldest")
                                                     : "")
                                            font.pixelSize: Theme.fontSizeMD
                                            color: index === 0
                                                   ? Theme.textSecondary
                                                   : Theme.textPrimary
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: fileRow.modelData.path
                                            font.pixelSize: Theme.fontSizeXS
                                            font.family: Theme.monoFamily
                                            color: Theme.textMuted
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                        }
                                    }
                                    Text {
                                        text: SystemInfo.formatBytes(
                                                  fileRow.modelData.size)
                                        font.pixelSize: Theme.fontSizeMD
                                        font.family: Theme.monoFamily
                                        color: Theme.textPrimary
                                    }
                                }
                            }
                        }
                    }
                }

                // --------------------------------------------- review bar
                MCard {
                    visible: !scanner.running
                             && (page.groups.length > 0 || page.selectedCount > 0)
                    Layout.fillWidth: true
                    implicitHeight: review.implicitHeight + Theme.spacingLG * 2
                    border.color: page.selectedCount > 0 ? Theme.danger : Theme.border

                    RowLayout {
                        id: review
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            Text {
                                text: page.selectedCount === 0
                                      ? qsTr("Nothing selected")
                                      : qsTr("%1 file(s) selected").arg(page.selectedCount)
                                font.pixelSize: Theme.fontSizeLG
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }
                            Text {
                                text: page.selectedCount === 0
                                      ? qsTr("Select files to move to the trash, then review the list before confirming. The oldest file in each group is a good keep candidate.")
                                      : qsTr("Estimated reclaimable space: %1").arg(
                                            SystemInfo.formatBytes(page.selectedBytes))
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textSecondary
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        MDestructiveButton {
                            text: qsTr("Move to trash…")
                            enabled: page.selectedCount > 0
                            onClicked: trashDialog.openReview()
                        }
                    }
                }

                // ---------------------------------------- empty states
                MEmptyState {
                    visible: !scanner.running && page.groups.length === 0
                             && page.summary.groupCount === undefined
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingXL
                    title: qsTr("No duplicate groups yet")
                    description: qsTr("Choose a directory and press Scan. Files are compared by size first and hashed only when needed.")
                    glyph: "⧉"
                }
                MEmptyState {
                    visible: !scanner.running
                             && page.summary.groupCount === 0
                             && page.summary.cancelled !== true
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingXL
                    title: qsTr("No duplicates found in this location")
                    description: qsTr("Every file compared here has a unique content hash.")
                    glyph: "✓"
                }
            }
        }
    }

    // ------------------------------ trash confirmation
    MConfirmationDialog {
        id: trashDialog

        function openReview() {
            const rows = []
            for (const group of page.groups) {
                for (const file of group.files) {
                    if (page.isSelected(file.path))
                        rows.push({ label: file.name,
                                    value: SystemInfo.formatBytes(file.size) })
                }
            }
            trashDialog.title = qsTr("Move %1 file(s) to trash?").arg(
                                    page.selectedCount)
            trashDialog.message = qsTr("Selected files go to the system trash. You can restore them until the trash is emptied.")
            trashDialog.rows = rows.slice(0, 12)
            trashDialog.consequence = qsTr(
                "The files are moved to the system trash with their contents unchanged. Nothing is deleted permanently right now.")
            trashDialog.confirmText = qsTr("Move to trash")
            open()
        }

        onAccepted: {
            const done = []
            let failures = 0
            for (const path in page.selected) {
                if (LargeFileService.moveToTrash(path))
                    done.push(path)
                else
                    ++failures
            }
            if (done.length > 0) {
                page.removePaths(done)
                appWindow.showToast(qsTr("Moved to trash: %1").arg(
                    SystemInfo.formatCount(done.length)) + qsTr(" files"),
                    "success")
            }
            if (failures > 0)
                appWindow.showToast(qsTr("Could not move %1 to the trash").arg(
                    SystemInfo.formatCount(failures)) + qsTr(" files"), "danger")
        }
    }

    // Error dialog for scan failures.
    Dialog {
        id: scanErrorDialog
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(420, parent ? parent.width - 48 : 420)
        padding: Theme.spacingLG

        property string message: ""

        background: Rectangle {
            color: Theme.surfaceElevated
            radius: Theme.radiusLG
            border.width: Theme.borderWidth
            border.color: Theme.border
        }

        contentItem: ColumnLayout {
            spacing: Theme.spacingMD

            Text {
                text: qsTr("Duplicate scan failed")
                font.pixelSize: Theme.fontSizeXL
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
            Text {
                text: scanErrorDialog.message
                font.pixelSize: Theme.fontSizeMD
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                MButton {
                    text: qsTr("OK")
                    onClicked: scanErrorDialog.close()
                }
            }
        }
    }
}
