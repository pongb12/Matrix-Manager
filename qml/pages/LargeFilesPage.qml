/*
 * LargeFilesPage.qml — find files above a chosen size threshold (MM-030).
 *
 * Default threshold 500 MB; options 100 MB / 500 MB / 1 GB / 5 GB.
 * Files are never deleted automatically — "Move to trash" requires an
 * explicit confirmation showing target, size and consequence.
 */
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Core
import MatrixManager.Theme
import MatrixManager.Components

Page {
    id: page

    background: null

    property bool hasScanned: false

    readonly property var thresholds: [
        { label: "100 MB", bytes: 100 * 1024 * 1024 },
        { label: "500 MB", bytes: 500 * 1024 * 1024 },
        { label: "1 GB",   bytes: 1024 * 1024 * 1024 },
        { label: "5 GB",   bytes: 5 * 1024 * 1024 * 1024 }
    ]

    Component.onCompleted: {
        const current = SettingsService.largeFileThresholdBytes
        for (let i = 0; i < thresholds.length; ++i) {
            if (thresholds[i].bytes === current) {
                thresholdSelector.currentIndex = i
                updateCustomDisplay(current)
                return
            }
        }
        thresholdSelector.currentIndex = 1 // 500 MB default
        updateCustomDisplay(current > 0 ? current : thresholds[1].bytes)
    }

    function updateCustomDisplay(bytes) {
        if (bytes % (1024 * 1024 * 1024) === 0 && bytes >= 1024 * 1024 * 1024) {
            customUnit.currentIndex = 1
            customValue.value = bytes / (1024 * 1024 * 1024)
        } else {
            customUnit.currentIndex = 0
            customValue.value = Math.max(1, Math.round(bytes / (1024 * 1024)))
        }
    }

    function applyCustomThreshold() {
        const bytes = customValue.value *
                      (customUnit.currentIndex === 1 ? 1024 * 1024 * 1024
                                                     : 1024 * 1024)
        SettingsService.largeFileThresholdBytes = bytes
        thresholdSelector.currentIndex = -1
    }

    MFolderDialog {
        id: folderDialog
        onAcceptedPath: (path) => pathField.text = path
    }

    // LargeFileService is a C++ singleton; results are observed here.
    Connections {
        target: LargeFileService

        function onProgressChanged(filesSeen) {
            progressDetail.text = SystemInfo.formatCount(filesSeen) + qsTr(" files checked")
        }

        function onFinished(rootPath, thresholdBytes, summary) {
            page.hasScanned = true
            if (summary.cancelled === true)
                appWindow.showToast(qsTr("Scan cancelled"), "neutral")
        }

        function onFailed(rootPath, message) {
            appWindow.showToast(message, "danger")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingLG

        MPageHeader {
            iconName: "file-search"
            title: qsTr("Large Files")
            subtitle: qsTr("Find files above a size threshold — nothing is deleted without confirmation")
        }

        // ------------------------------------------------ controls
        MCard {
            objectName: "largeControls"
            Layout.fillWidth: true
            implicitHeight: controls.implicitHeight + Theme.spacingLG * 2

            ColumnLayout {
                id: controls
                anchors.fill: parent
                anchors.margins: Theme.spacingLG
                spacing: Theme.spacingMD

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMD

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

                        background: Rectangle {
                            radius: Theme.radiusMD
                            color: Theme.surfaceSunken
                            border.width: pathField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                            border.color: pathField.activeFocus ? Theme.focus : Theme.border
                        }
                    }
                    MSecondaryButton {
                        text: qsTr("Browse")
                        iconName: "folder-open"
                        enabled: !LargeFileService.running
                        onClicked: folderDialog.open()
                    }
                    MSecondaryButton {
                        text: qsTr("Home")
                        iconName: "home"
                        enabled: !LargeFileService.running
                        onClicked: pathField.text = StorageService.homePath()
                    }
                    MSecondaryButton {
                        text: qsTr("Filesystem")
                        iconName: "database"
                        enabled: !LargeFileService.running
                        onClicked: pathField.text = "/"
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMD

                    Text {
                        text: qsTr("Threshold")
                        font.pixelSize: Theme.fontSizeMD
                        color: Theme.textMuted
                    }
                    MSegmented {
                        id: thresholdSelector
                        model: page.thresholds.map(t => t.label)
                        onActivated: (index) => {
                            SettingsService.largeFileThresholdBytes =
                                page.thresholds[index].bytes
                            updateCustomDisplay(page.thresholds[index].bytes)
                        }
                    }

                    Text {
                        text: qsTr("Custom")
                        font.pixelSize: Theme.fontSizeMD
                        color: Theme.textMuted
                    }
                    SpinBox {
                        id: customValue
                        from: 1
                        to: 99999
                        editable: true
                        // 96 left too little room between the stepper
                        // buttons for the editable value ("500" clipped to
                        // one digit); 136 keeps all five digits readable.
                        implicitWidth: 136
                        font.pixelSize: Theme.fontSizeSM
                        onValueModified: page.applyCustomThreshold()
                    }
                    ComboBox {
                        id: customUnit
                        model: [qsTr("MB"), qsTr("GB")]
                        implicitWidth: 84
                        font.pixelSize: Theme.fontSizeSM
                        onActivated: (index) => page.applyCustomThreshold()
                    }

                    Item { Layout.fillWidth: true }

                    MProgressBar {
                        visible: LargeFileService.running
                    }
                    Text {
                        id: progressDetail
                        visible: LargeFileService.running
                        font.pixelSize: Theme.fontSizeSM
                        font.family: Theme.monoFamily
                        color: Theme.textSecondary
                    }
                    MButton {
                        text: LargeFileService.running ? qsTr("Scanning…") : qsTr("Scan")
                        enabled: !LargeFileService.running
                        onClicked: {
                            LargeFileService.model.setFilter("")
                            LargeFileService.start(pathField.text)
                        }
                    }
                    MSecondaryButton {
                        text: qsTr("Cancel scan")
                        visible: LargeFileService.running
                        onClicked: LargeFileService.cancel()
                    }
                }
            }
        }

        // ------------------------------------------------ results
        MCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingLG
                spacing: Theme.spacingMD

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: LargeFileService.model.count > 0
                              ? qsTr("%1 files · %2 total").arg(
                                    SystemInfo.formatCount(LargeFileService.model.count)).arg(
                                    SystemInfo.formatBytes(LargeFileService.model.totalBytes))
                              : qsTr("Results")
                        font.pixelSize: Theme.fontSizeLG
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }
                    MSearchField {
                        visible: LargeFileService.model.count > 0
                        onTextChanged: LargeFileService.model.setFilter(text)
                        placeholderText: qsTr("Filter by name")
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: LargeFileService.running ? 1 : (LargeFileService.model.count > 0 ? 0 : 2)

                    // Results list
                    ListView {
                        id: resultList
                        model: LargeFileService.model
                        clip: true
                        spacing: 0

                        delegate: Rectangle {
                            width: resultList.width
                            height: 52
                            color: rowMouse.containsMouse ? Theme.surfaceSunken : "transparent"

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.spacingMD
                                anchors.rightMargin: Theme.spacingMD
                                spacing: Theme.spacingMD

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true

                                    Text {
                                        text: name
                                        font.pixelSize: Theme.fontSizeMD
                                        color: Theme.textPrimary
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: path
                                        font.pixelSize: Theme.fontSizeXS
                                        font.family: Theme.monoFamily
                                        color: Theme.textMuted
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }

                                MBadge {
                                    text: fileType
                                    tone: "neutral"
                                }
                                Text {
                                    text: SystemInfo.formatDateTime(modified)
                                    font.pixelSize: Theme.fontSizeSM
                                    font.family: Theme.monoFamily
                                    color: Theme.textMuted
                                    Layout.preferredWidth: 130
                                }
                                Text {
                                    text: SystemInfo.formatBytes(size)
                                    font.pixelSize: Theme.fontSizeMD
                                    font.weight: Font.Medium
                                    font.family: Theme.monoFamily
                                    color: Theme.textPrimary
                                    Layout.preferredWidth: 90
                                    horizontalAlignment: Text.AlignRight
                                }

                                RowLayout {
                                    spacing: Theme.spacingXS

                                    MIconButton {
                                        iconName: "external-link"
                                        tooltip: qsTr("Open file")
                                        onClicked: {
                                            if (!LargeFileService.openFile(path))
                                                appWindow.showToast(qsTr("Could not open %1").arg(name), "danger")
                                        }
                                    }
                                    MIconButton {
                                        iconName: "folder"
                                        tooltip: qsTr("Show in folder")
                                        onClicked: {
                                            if (!LargeFileService.showInFolder(path))
                                                appWindow.showToast(qsTr("Could not open folder"), "danger")
                                        }
                                    }
                                    MIconButton {
                                        iconName: "trash-2"
                                        tooltip: qsTr("Move to trash")
                                        onClicked: deleteDialog.openFor(name, path, size)
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {}
                    }

                    // Scanning
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MLoadingState {
                            anchors.centerIn: parent
                            label: qsTr("Scanning %1…").arg(pathField.text)
                            detail: progressDetail.text
                            cancellable: true
                            onCancelRequested: LargeFileService.cancel()
                        }
                    }

                    // Empty
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MEmptyState {
                            anchors.centerIn: parent
                            visible: !LargeFileService.running
                            title: !page.hasScanned
                                   ? qsTr("No scan yet")
                                   : qsTr("No files above the threshold")
                            description: !page.hasScanned
                                   ? qsTr("Choose a location and threshold, then press Scan. Scanning starts only on your request.")
                                   : qsTr("Try lowering the size threshold or scanning another location.")
                            iconName: "file-search"
                        }
                    }
                }
            }
        }
    }

    // Deletion confirmation — explicit target, size and consequence.
    MConfirmationDialog {
        id: deleteDialog

        function openFor(name, path, size) {
            deleteDialog.title = qsTr("Move file to trash?")
            deleteDialog.message = qsTr("The file will be moved to the system trash.")
            deleteDialog.rows = [
                { label: qsTr("File"), value: name },
                { label: qsTr("Size"), value: SystemInfo.formatBytes(size) },
                { label: qsTr("Location"), value: path }
            ]
            deleteDialog.consequence = qsTr(
                "You can restore the file from the trash until the trash is emptied. Nothing is deleted permanently right now.")
            deleteDialog.confirmText = qsTr("Move to trash")
            deleteDialog.currentPath = path
            deleteDialog.currentName = name
            open()
        }

        property string currentPath: ""
        property string currentName: ""

        onAccepted: {
            if (LargeFileService.moveToTrash(currentPath)) {
                LargeFileService.model.removePath(currentPath)
                appWindow.showToast(qsTr("Moved to trash: %1").arg(currentName), "success")
            } else {
                appWindow.showToast(qsTr("Could not move %1 to the trash").arg(currentName), "danger")
            }
        }
    }
}
