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
    property var searchEntries: []
    property var searchSummary: ({})
    property string searchProgressText: ""
    property string activeSearchRoot: ""

    Component.onCompleted: {
        // QA hook: auto-start a scan when requested (automated UI checks).
        if (typeof qaScanPath !== "undefined" && qaScanPath !== "")
            page.startScan(qaScanPath)
        if (typeof qaStorageMode !== "undefined")
            modeSelector.currentIndex = qaStorageMode
    }

    // Mode switch used by the guided tour and QA hooks.
    function setMode(index) {
        modeSelector.currentIndex = index
    }

    // One folder dialog shared by every path field on this page.
    MFolderDialog {
        id: folderDialog
        property var targetField: null
        onAcceptedPath: (path) => {
            if (targetField)
                targetField.text = path
        }
    }

    readonly property bool isHomeScan: lastScanRoot === StorageService.homePath()
    readonly property var knownCategories: [
        "Desktop", "Documents", "Downloads", "Music",
        "Pictures", "Videos", "Public", "Templates", ".cache"
    ]

    DirectoryScanner {
        id: scanner

        onPartialResults: (rootPath, partialEntries) => {
            if (rootPath === page.scanPath) {
                if (partialEntries.length > 0 && !page.qaLogged) {
                    page.qaLogged = true
                    const e = partialEntries[0]
                    if (typeof qaLog !== "undefined")
                        qaLog.log("entry keys=" + Object.keys(e).join(",")
                                  + " files=" + JSON.stringify(e.files)
                                  + " typeof=" + typeof e.files
                                  + " bytes=" + JSON.stringify(e.bytes)
                                  + " typeobytes=" + typeof e.bytes)
                }
                page.entries = partialEntries
                page.sortEntries()
            }
        }

        onProgressChanged: (filesSeen) => {
            progressDetail.text = SystemInfo.formatCount(filesSeen) + qsTr(" files checked")
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

    FileSearcher {
        id: fileSearcher

        // The search card lives in a lazily-instantiated Component, so its
        // ids (searchRoot, searchProgress) are not reachable here. State the
        // page needs is mirrored onto page-level properties instead.
        onProgressChanged: (filesSeen) => {
            page.searchProgressText = SystemInfo.formatCount(filesSeen)
                                      + qsTr(" files checked")
        }

        onPartialResults: (rootPath, results) => {
            if (rootPath === page.activeSearchRoot)
                page.searchEntries = results
        }

        onFinished: (rootPath, results, finishedSummary) => {
            page.searchEntries = results
            page.searchSummary = finishedSummary
            if (finishedSummary.cancelled === true)
                appWindow.showToast(qsTr("Search cancelled"), "neutral")
        }

        onFailed: (rootPath, message) => {
            appWindow.showToast(qsTr("Search failed") + ": " + message, "danger")
        }
    }

    // Search parameters are passed explicitly: the fields live inside the
    // lazily-instantiated search card, whose ids are NOT visible from a
    // function defined on the page root (loader component scope).
    function startSearch(rootPath, nameText, extText, minText, maxText) {
        // Empty fields mean "no limit"; MB fields are converted to bytes.
        const min = minText === undefined || minText.trim() === "" ? 0
                  : Number(minText) * 1024 * 1024
        const max = maxText === undefined || maxText.trim() === "" ? 0
                  : Number(maxText) * 1024 * 1024
        page.searchEntries = []
        page.searchSummary = {}
        page.searchProgressText = ""
        page.activeSearchRoot = rootPath
        fileSearcher.start(rootPath, nameText, extText, min, max)
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
            iconName: "hard-drive"
            title: qsTr("Storage")
            subtitle: qsTr("Explore volumes and directory usage — scanning runs only on your request")
        }

        MSegmented {
            id: modeSelector
            objectName: "storageModes"
            model: [qsTr("Directory usage"), qsTr("Search"), qsTr("Treemap")]
        }

        ScrollView {
            id: pageScroll
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                // Never wider than the scroll viewport: sizing from the
                // page width here made the content overflow past the right
                // window edge (no clipping, cut-off buttons and columns).
                width: pageScroll.width
                spacing: Theme.spacingLG

                // ------------------------------------------------ volumes
                Flow {
                    visible: modeSelector.currentIndex === 0
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
                    visible: modeSelector.currentIndex === 0
                             && page.isHomeScan && page.categoryRows().length > 0
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
                    objectName: "storageControls"
                    visible: modeSelector.currentIndex === 0
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
                            objectName: "storagePathRow"
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
                            MSecondaryButton {
                                text: qsTr("Browse")
                                iconName: "folder-open"
                                enabled: !scanner.running
                                onClicked: {
                                    folderDialog.targetField = pathField
                                    folderDialog.open()
                                }
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
                            // Tall enough for the empty state when idle;
                            // compact while showing results.
                            Layout.preferredHeight: count === 0 ? 190
                                : Math.min(420, Math.max(count * 34, 60))
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
                                    // Integer formatting goes through C++
                                    // SystemInfo.formatCount: QLocale.toString
                                    // from QML is broken on Qt 6.2-6.4 and
                                    // renders "[object Object]".
                                    text: modelData.files > 0
                                            ? SystemInfo.formatCount(modelData.files)
                                            : "—"
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
                                iconName: "hard-drive"
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
                                    SystemInfo.formatCount(page.summary.totalFiles || 0)).arg(
                                    errors).arg(cancelled)
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    active: modeSelector.currentIndex === 1
                    sourceComponent: searchCardComp
                }
                // QA note: the search card auto-starts a scan from its own
                // Component.onCompleted when MM_QA_* variables are present.

                Loader {
                    Layout.fillWidth: true
                    active: modeSelector.currentIndex === 2
                    sourceComponent: treemapCardComp
                }

            }
        }
    }

    Component {
        id: searchCardComp
                MCard {
            objectName: "storageSearchCard"
            width: parent.width
            height: implicitHeight
                    Layout.fillWidth: true
                    implicitHeight: searchCard.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: searchCard
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        Component.onCompleted: {
                            // QA hook (see page comment): ids like searchName
                            // live inside this component's scope.
                            if (typeof qaStorageMode !== "undefined") {
                                if (typeof qaSearchName !== "undefined")
                                    searchName.text = qaSearchName
                                page.startSearch(searchRoot.text, searchName.text,
                                                 searchExt.text, searchMin.text,
                                                 searchMax.text)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSM

                            Text {
                                text: qsTr("Look in")
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textMuted
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38

                                TextField {
                                id: searchRoot
                                anchors.fill: parent
                                text: StorageService.homePath()
                                font.pixelSize: Theme.fontSizeSM
                                font.family: Theme.monoFamily
                                selectByMouse: true
                                color: Theme.textPrimary

                                background: Rectangle {
                                    radius: Theme.radiusMD
                                    color: Theme.surfaceSunken
                                    border.width: searchRoot.activeFocus ? Theme.focusWidth : Theme.borderWidth
                                    border.color: searchRoot.activeFocus ? Theme.focus : Theme.border
                                }

                                onAccepted: page.startSearch(searchRoot.text, searchName.text,
                                                             searchExt.text, searchMin.text,
                                                             searchMax.text)
                                }

                            }
                            MButton {
                                text: fileSearcher.running ? qsTr("Scanning…") : qsTr("Search")
                                enabled: !fileSearcher.running
                                onClicked: page.startSearch(searchRoot.text, searchName.text,
                                                            searchExt.text, searchMin.text,
                                                            searchMax.text)
                            }
                            MSecondaryButton {
                                text: qsTr("Browse")
                                iconName: "folder-open"
                                enabled: !fileSearcher.running
                                onClicked: {
                                    folderDialog.targetField = searchRoot
                                    folderDialog.open()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSM

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38

                                TextField {
                                    id: searchName
                                    anchors.fill: parent
                                    placeholderText: qsTr("Name contains")
                                    font.pixelSize: Theme.fontSizeSM
                                    color: Theme.textPrimary
                                    placeholderTextColor: Theme.textMuted
                                    selectByMouse: true

                                    background: Rectangle {
                                        radius: Theme.radiusMD
                                        color: Theme.surfaceSunken
                                        border.width: searchName.activeFocus ? Theme.focusWidth : Theme.borderWidth
                                        border.color: searchName.activeFocus ? Theme.focus : Theme.border
                                    }
                                }
                            }
                            // Fixed-width fields sit in plain wrapper
                            // Items: a TextField with Layout.preferredWidth
                            // inside a RowLayout triggers a recursive
                            // rearrange loop on Qt 6.2-6.4.
                            Item {
                                Layout.preferredWidth: 130
                                Layout.preferredHeight: 38

                                TextField {
                                    id: searchExt
                                    anchors.fill: parent
                                    placeholderText: qsTr("Extension")
                                    font.pixelSize: Theme.fontSizeSM
                                    color: Theme.textPrimary
                                    placeholderTextColor: Theme.textMuted
                                    selectByMouse: true

                                    background: Rectangle {
                                        radius: Theme.radiusMD
                                        color: Theme.surfaceSunken
                                        border.width: searchExt.activeFocus ? Theme.focusWidth : Theme.borderWidth
                                        border.color: searchExt.activeFocus ? Theme.focus : Theme.border
                                    }
                                }
                            }
                            Item {
                                Layout.preferredWidth: 140
                                Layout.preferredHeight: 38

                                TextField {
                                    id: searchMin
                                    anchors.fill: parent
                                    placeholderText: qsTr("Min size (MB)")
                                    font.pixelSize: Theme.fontSizeSM
                                    color: Theme.textPrimary
                                    placeholderTextColor: Theme.textMuted
                                    selectByMouse: true
                                    validator: IntValidator { bottom: 0 }

                                    background: Rectangle {
                                        radius: Theme.radiusMD
                                        color: Theme.surfaceSunken
                                        border.width: searchMin.activeFocus ? Theme.focusWidth : Theme.borderWidth
                                        border.color: searchMin.activeFocus ? Theme.focus : Theme.border
                                    }
                                }
                            }
                            Item {
                                Layout.preferredWidth: 140
                                Layout.preferredHeight: 38

                                TextField {
                                    id: searchMax
                                    anchors.fill: parent
                                    placeholderText: qsTr("Max size (MB)")
                                    font.pixelSize: Theme.fontSizeSM
                                    color: Theme.textPrimary
                                    placeholderTextColor: Theme.textMuted
                                    selectByMouse: true
                                    validator: IntValidator { bottom: 0 }

                                    background: Rectangle {
                                        radius: Theme.radiusMD
                                        color: Theme.surfaceSunken
                                        border.width: searchMax.activeFocus ? Theme.focusWidth : Theme.borderWidth
                                        border.color: searchMax.activeFocus ? Theme.focus : Theme.border
                                    }
                                }
                            }
                        }

                        RowLayout {
                            visible: fileSearcher.running
                            Layout.fillWidth: true
                            spacing: Theme.spacingMD

                            MProgressBar {
                                Layout.preferredWidth: 180
                                indeterminate: true
                            }
                            Text {
                                text: page.searchProgressText
                                font.pixelSize: Theme.fontSizeSM
                                font.family: Theme.monoFamily
                                color: Theme.textSecondary
                            }
                            MSecondaryButton {
                                text: qsTr("Cancel scan")
                                onClicked: fileSearcher.cancel()
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        ListView {
                            id: searchResults
                            Layout.fillWidth: true
                            Layout.preferredHeight: count === 0 ? 170
                                : Math.min(420, Math.max(count * 44, 60))
                            model: page.searchEntries
                            clip: true
                            spacing: 0

                            delegate: RowLayout {
                                width: searchResults.width
                                height: 44
                                spacing: Theme.spacingMD

                                ColumnLayout {
                                    spacing: 1
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeMD
                                        color: Theme.textPrimary
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: modelData.path
                                        font.pixelSize: Theme.fontSizeXS
                                        font.family: Theme.monoFamily
                                        color: Theme.textMuted
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: SystemInfo.formatBytes(modelData.size)
                                    font.pixelSize: Theme.fontSizeMD
                                    font.family: Theme.monoFamily
                                    color: Theme.textPrimary
                                    horizontalAlignment: Text.AlignRight
                                }

                                MIconButton {
                                    iconName: "external-link"
                                    tooltip: qsTr("Open file")
                                    onClicked: {
                                        if (!LargeFileService.openFile(modelData.path))
                                            appWindow.showToast(qsTr("Could not open %1").arg(modelData.name), "danger")
                                    }
                                }
                                MIconButton {
                                    iconName: "folder"
                                    tooltip: qsTr("Show in folder")
                                    onClicked: {
                                        if (!LargeFileService.showInFolder(modelData.path))
                                            appWindow.showToast(qsTr("Could not open folder"), "danger")
                                    }
                                }
                            }

                            MEmptyState {
                                anchors.centerIn: parent
                                width: parent.width - 48
                                visible: searchResults.count === 0 && !fileSearcher.running
                                         && page.searchSummary.count === undefined
                                title: qsTr("No matches yet")
                                description: qsTr("Type a name fragment or set a size range, then press Search. The scan walks the chosen directory only.")
                                iconName: "search"
                            }
                            MEmptyState {
                                anchors.centerIn: parent
                                width: parent.width - 48
                                visible: !fileSearcher.running
                                         && page.searchSummary.count === 0
                                         && page.searchSummary.cancelled !== true
                                title: qsTr("No files matched the filters")
                                description: qsTr("Adjust the filters or search another location.")
                                iconName: "search"
                            }
                        }

                        Text {
                            visible: page.searchSummary.count !== undefined
                            font.pixelSize: Theme.fontSizeSM
                            font.family: Theme.monoFamily
                            color: Theme.textMuted
                            text: {
                                if (page.searchSummary.count === undefined)
                                    return ""
                                let line = qsTr("%1 matches").arg(
                                    SystemInfo.formatCount(page.searchSummary.count || 0))
                                if (page.searchSummary.truncated === true)
                                    line += qsTr(" · results limited to the first %1").arg(
                                        SystemInfo.formatCount(page.searchSummary.count))
                                if (page.searchSummary.cancelled === true)
                                    line += qsTr(" · cancelled")
                                return line
                            }
                        }
                    }
                }
    }

    Component {
        id: treemapCardComp
                MCard {
            objectName: "treemapCard"
            width: parent.width
            height: implicitHeight
                    Layout.fillWidth: true
                    implicitHeight: treemapCard.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: treemapCard
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        Text {
                            text: qsTr("Treemap")
                            font.pixelSize: Theme.fontSizeLG
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        Text {
                            text: qsTr("Each block is a subdirectory; area is proportional to size. Click to enter, hover for details.")
                            font.pixelSize: Theme.fontSizeXS
                            color: Theme.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        MMTreemap {
                            Layout.fillWidth: true
                            entries: page.entries
                            onActivate: (path) => {
                                page.startScan(path)
                                modeSelector.currentIndex = 0
                            }
                            onHoverInfo: (text) => treemapHover.text = text
                        }
                        Text {
                            id: treemapHover
                            font.pixelSize: Theme.fontSizeSM
                            font.family: Theme.monoFamily
                            color: Theme.textSecondary
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                            visible: text !== ""
                        }
                        Text {
                            visible: page.entries.length === 0
                            text: qsTr("Directory not scanned yet")
                            font.pixelSize: Theme.fontSizeMD
                            color: Theme.textMuted
                        }
                        Text {
                            text: qsTr("Prefer plain numbers? The Directory usage tab shows the same data as a table — the accessible alternative to this view.")
                            font.pixelSize: Theme.fontSizeXS
                            color: Theme.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
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
