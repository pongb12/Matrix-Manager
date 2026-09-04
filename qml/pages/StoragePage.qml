/*
 * StoragePage.qml — filesystem exploration (MM-020, MM-021, MM-022).
 *
 * Nothing is scanned automatically. The user picks a directory and presses
 * Scan. Results arrive incrementally, remain cancellable and mark entries
 * that could not be read instead of hiding them.
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

    property string scanPath: StorageService.homePath()
    property var entries: []
    property var summary: ({})
    property var lastScanRoot: ""
    property bool sortByName: false
    property bool sortAscending: false

    readonly property bool isHomeScan: lastScanRoot === StorageService.homePath()
    readonly property var knownCategories: [
        "Desktop", "Documents", "Downloads", "Music",
        "Pictures", "Videos", "Public", "Templates", ".cache"
    ]

    DirectoryScanner {
        id: scanner

        onPartialResults: (rootPath, partialEntries) => {
            if (rootPath === page.scanPath) {
                page.entries = partialEntries
                page.sortEntries()
            }
        }

        onProgressChanged: (filesSeen) => {
            progressDetail.text = Qt.locale().toString(filesSeen) + qsTr(" files checked")
        }

        onFinished: (rootPath, finalEntries, summary) => {
            page.lastScanRoot = rootPath
            page.entries = finalEntries
            page.summary = summary
            page.sortEntries()
        }

        onFailed: (rootPath, message) => {
            page.summary = { errorCount: 1 }
            scanErrorDialog.message = message
            scanErrorDialog.open()
        }
    }

    function sortEntries() {
        // Copies so QML re-evaluates the list bindings.
        const list = page.entries.slice()
        if (page.sortByName) {
            list.sort((a, b) => {
                const cmp = a.name.toLowerCase() < b.name.toLowerCase() ? -1
                          : a.name.toLowerCase() > b.name.toLowerCase() ? 1 : 0
                return page.sortAscending ? cmp : -cmp
            })
        } else {
            list.sort((a, b) => {
                if (a.bytes !== b.bytes)
                    return page.sortAscending ? a.bytes - b.bytes : b.bytes - a.bytes
                return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1
            })
        }
        page.entries = list
    }

    function startScan(path) {
        page.scanPath = path
        page.entries = []
        page.summary = {}
        scanner.start(path)
    }

    // Home category breakdown (MM-021). Classification is honest: only
    // well-known top-level directories are grouped; everything else stays
    // under "Other".
    function categoryRows() {
        if (!page.isHomeScan)
            return []
        const known = new Set(page.knownCategories)
        let other = 0
        const rows = []
        for (let i = 0; i < page.entries.length; ++i) {
            const e = page.entries[i]
            if (known.has(e.name))
                rows.push({ name: e.name === ".cache" ? qsTr("Cache") : e.name, bytes: e.bytes })
            else
                other += e.bytes
        }
        rows.push({ name: qsTr("Other"), bytes: other })
        return rows.filter(r => r.bytes > 0)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingLG

        MPageHeader {
            title: qsTr("Storage")
            subtitle: qsTr("Explore volumes and directory usage — scanning runs only on your request")
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: Math.max(implicitWidth, page.availableWidth)
                spacing: Theme.spacingLG

                // ------------------------------------------------ volumes
                Flow {
                    spacing: Theme.spacingMD
                    Layout.fillWidth: true

                    Repeater {
                        model: StorageService.volumes()

                        MCard {
                            required property var modelData
                            width: 320
                            height: 108

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingMD
                                spacing: Theme.spacingXS

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.mountPoint
                                        font.pixelSize: Theme.fontSizeMD
                                        font.weight: Font.DemiBold
                                        font.family: Theme.monoFamily
                                        color: Theme.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    MBadge {
                                        text: modelData.fileSystem
                                        tone: "neutral"
                                    }
                                }

                                MUsageBar {
                                    Layout.fillWidth: true
                                    label: ""
                                    valueText: modelData.usagePercent + "%"
                                    usedFraction: modelData.totalBytes > 0
                                                  ? modelData.usedBytes / modelData.totalBytes : 0
                                    legendLeft: qsTr("%1 used").arg(SystemInfo.formatBytes(modelData.usedBytes))
                                    legendRight: qsTr("%1 free of %2").arg(
                                                     SystemInfo.formatBytes(modelData.freeBytes)).arg(
                                                     SystemInfo.formatBytes(modelData.totalBytes))
                                }
                            }
                        }
                    }
                }

                // ------------------------------------- category overview
                MCard {
                    visible: page.isHomeScan && page.categoryRows().length > 0
                    Layout.fillWidth: true
                    implicitHeight: categoryContent.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: categoryContent
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        Text {
                            text: qsTr("Home folder breakdown")
                            font.pixelSize: Theme.fontSizeLG
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        // Stacked bar
                        Rectangle {
                            id: categoryBar
                            Layout.fillWidth: true
                            height: 14
                            radius: Theme.radiusSM
                            color: Theme.surfaceSunken

                            Row {
                                anchors.fill: parent
                                anchors.margins: 0
                                clip: true

                                Repeater {
                                    model: page.categoryRows()

                                    Rectangle {
                                        required property var modelData
                                        readonly property var rows: page.categoryRows()
                                        readonly property real total: rows.reduce((s, r) => s + r.bytes, 0)
                                        width: total > 0 ? (modelData.bytes / total) * categoryBar.width : 0
                                        height: parent.height
                                        color: Theme.categoryColors[index % Theme.categoryColors.length]
                                    }
                                }
                            }
                        }

                        Flow {
                            spacing: Theme.spacingMD
                            Layout.fillWidth: true

                            Repeater {
                                model: page.categoryRows()

                                RowLayout {
                                    required property var modelData
                                    spacing: 6

                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 2
                                        color: Theme.categoryColors[index % Theme.categoryColors.length]
                                    }
                                    Text {
                                        text: modelData.name + "  " + SystemInfo.formatBytes(modelData.bytes)
                                        font.pixelSize: Theme.fontSizeSM
                                        color: Theme.textSecondary
                                    }
                                }
                            }
                        }
                    }
                }

                // ----------------------------------------- directory tool
                MCard {
                    Layout.fillWidth: true
                    implicitHeight: explorer.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: explorer
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSM

                            Text {
                                text: qsTr("Directory usage")
                                font.pixelSize: Theme.fontSizeLG
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                            }
                            MSecondaryButton {
                                text: qsTr("Up")
                                enabled: page.scanPath !== "/" && !scanner.running
                                onClicked: {
                                    const parentPath =
                                        page.scanPath.substring(0, page.scanPath.lastIndexOf("/")) || "/"
                                    page.startScan(parentPath)
                                }
                            }
                            MButton {
                                text: scanner.running ? qsTr("Scanning…") : qsTr("Scan")
                                enabled: !scanner.running
                                onClicked: page.startScan(page.scanPath)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSM

                            Text {
                                text: qsTr("Path")
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textMuted
                            }
                            TextField {
                                id: pathField
                                Layout.fillWidth: true
                                text: page.scanPath
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
                        }

                        // Scan progress
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

                        // Header (clickable: sort by name or size)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingMD

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: qsTr("Name") + (page.sortByName ? (page.sortAscending ? " \u2191" : " \u2193") : "")
                                    font.pixelSize: Theme.fontSizeSM
                                    font.weight: Font.Medium
                                    color: page.sortByName ? Theme.textSecondary : Theme.textMuted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (page.sortByName)
                                            page.sortAscending = !page.sortAscending
                                        else {
                                            page.sortByName = true
                                            page.sortAscending = true
                                        }
                                        page.sortEntries()
                                    }
                                }
                            }
                            Text {
                                text: qsTr("Files")
                                font.pixelSize: Theme.fontSizeSM
                                font.weight: Font.Medium
                                color: Theme.textMuted
                                Layout.preferredWidth: 70
                                horizontalAlignment: Text.AlignRight
                            }
                            Item {
                                Layout.preferredWidth: 90
                                Layout.fillHeight: true

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: qsTr("Size") + (!page.sortByName ? (page.sortAscending ? " \u2191" : " \u2193") : "")
                                    font.pixelSize: Theme.fontSizeSM
                                    font.weight: Font.Medium
                                    color: !page.sortByName ? Theme.textSecondary : Theme.textMuted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!page.sortByName)
                                            page.sortAscending = !page.sortAscending
                                        else {
                                            page.sortByName = false
                                            page.sortAscending = false
                                        }
                                        page.sortEntries()
                                    }
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        // Rows
                        ListView {
                            id: resultList
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(420, Math.max(count * 34, 60))
                            model: page.entries
                            clip: true
                            spacing: 0

                            delegate: RowLayout {
                                width: resultList.width
                                height: 34
                                spacing: Theme.spacingMD

                                Rectangle {
                                    Layout.preferredWidth: 3
                                    Layout.fillHeight: true
                                    color: modelData.isDir ? Theme.accent : "transparent"
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: modelData.isDir ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (modelData.isDir)
                                                page.startScan(modelData.path)
                                        }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name + (modelData.isSymlink ? qsTr("  → link") : "")
                                        font.pixelSize: Theme.fontSizeMD
                                        font.family: modelData.isDir ? Theme.fontFamily : Theme.monoFamily
                                        color: modelData.isDir ? Theme.textPrimary : Theme.textSecondary
                                        elide: Text.ElideMiddle
                                        width: parent.width
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: Theme.spacingMD
                                        text: modelData.error
                                        font.pixelSize: Theme.fontSizeXS
                                        color: Theme.warning
                                        visible: modelData.error !== ""
                                    }
                                }

                                Text {
                                    text: modelData.files > 0 ? Qt.locale().toString(modelData.files) : "—"
                                    font.pixelSize: Theme.fontSizeSM
                                    font.family: Theme.monoFamily
                                    color: Theme.textMuted
                                    Layout.preferredWidth: 70
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text {
                                    text: SystemInfo.formatBytes(modelData.bytes)
                                    font.pixelSize: Theme.fontSizeMD
                                    font.family: Theme.monoFamily
                                    color: Theme.textPrimary
                                    Layout.preferredWidth: 90
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            MEmptyState {
                                anchors.centerIn: parent
                                visible: resultList.count === 0 && !scanner.running
                                         && page.summary.totalFiles === undefined
                                title: qsTr("Directory not scanned yet")
                                description: qsTr("Choose a directory above and press Scan. Matrix Manager never scans anything on its own — scanning starts only when you ask for it.")
                                glyph: "⌸"
                            }
                        }

                        // Summary
                        Text {
                            visible: page.summary.totalFiles !== undefined
                            font.pixelSize: Theme.fontSizeSM
                            font.family: Theme.monoFamily
                            color: Theme.textMuted
                            text: {
                                if (page.summary.totalFiles === undefined)
                                    return ""
                                const cancelled = page.summary.cancelled
                                              ? qsTr(" · cancelled") : ""
                                const errors = page.summary.errorCount > 0
                                    ? qsTr(" · %1 inaccessible entries").arg(page.summary.errorCount)
                                    : ""
                                return qsTr("%1 total · %2 files%3%4").arg(
                                    SystemInfo.formatBytes(page.summary.totalBytes || 0)).arg(
                                    Qt.locale().toString(page.summary.totalFiles || 0)).arg(
                                    errors).arg(cancelled)
                            }
                        }
                    }
                }
            }
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
                text: qsTr("Scan failed")
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
