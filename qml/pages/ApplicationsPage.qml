/*
 * ApplicationsPage.qml — installed .deb applications (MM-041..MM-043).
 *
 * Human-readable identity first (DOC.md rule 11). Uninstall always goes
 * through the system package manager after explicit confirmation; the GUI
 * itself never runs as root.
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

    property var selectedPackage: null
    // Category browsing (1.0.3-2): "all" or one of the category ids the
    // model derives from dpkg sections (see PackageModel::categoryIdForSection).
    property string selectedCategory: "all"
    readonly property bool searchActive: searchField.text !== ""

    // Feeds the chip row: the "all" entry first, then every category present
    // in the data (id, count, bytes). Re-evaluated whenever the model resets.
    readonly property var categories: {
        const all = {
            id: "all",
            count: PackageService.model.totalCount,
            bytes: PackageService.model.totalInstalledBytes
        }
        return [all].concat(PackageService.model.categorySummary())
    }

    onSelectedCategoryChanged:
        PackageService.model.setCategory(selectedCategory)

    function categoryLabel(id) {
        switch (id) {
        case "accessories": return qsTr("Accessories")
        case "internet":    return qsTr("Internet")
        case "development": return qsTr("Development")
        case "graphics":    return qsTr("Graphics")
        case "multimedia":  return qsTr("Multimedia")
        case "games":       return qsTr("Games")
        case "science":     return qsTr("Science & education")
        case "system":      return qsTr("System")
        case "libraries":   return qsTr("Libraries")
        case "fonts":       return qsTr("Fonts")
        case "desktop":     return qsTr("Desktop")
        default:            return qsTr("Other")
        }
    }

    Component.onCompleted: {
        if (PackageService.model.totalCount === 0 && !PackageService.loading)
            PackageService.refresh()
    }

    Connections {
        target: PackageService

        function onUninstallFinished(success, message) {
            appWindow.showToast(message, success ? "success" : "danger")
            if (success)
                page.selectedPackage = null
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingLG

        MPageHeader {
            iconName: "package"
            title: qsTr("Applications")
            subtitle: qsTr("Installed .deb packages on this system")

            MSearchField {
                id: searchField
                visible: PackageService.model.totalCount > 0
                placeholderText: qsTr("Search packages")
                onTextChanged: PackageService.model.setFilter(text)
            }
            MIconButton {
                objectName: "appsRefresh"
                iconName: "refresh-cw"
                tooltip: qsTr("Refresh list")
                enabled: !PackageService.loading && !PackageService.busy
                onClicked: PackageService.refresh()
            }
        }

        // ------------------------------------------- category chips
        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacingSM
            visible: PackageService.model.totalCount > 0
                     && !PackageService.loading
                     && PackageService.lastError === ""

            Repeater {
                model: page.categories

                delegate: AbstractButton {
                    id: chip
                    required property var modelData
                    readonly property bool active:
                        page.selectedCategory === modelData.id

                    hoverEnabled: true
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 5
                    bottomPadding: 5

                    contentItem: Row {
                        spacing: 6

                        Text {
                            text: chip.modelData.id === "all"
                                  ? qsTr("All")
                                  : page.categoryLabel(chip.modelData.id)
                            font.pixelSize: Theme.fontSizeSM
                            font.weight: chip.active ? Font.DemiBold : Font.Normal
                            color: chip.active ? Theme.onAccent : Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: chipCountText.implicitWidth + 10
                            height: 16
                            radius: 8
                            color: chip.active ? Theme.accentPressed
                                               : Theme.surfaceSunken
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: chipCountText
                                anchors.centerIn: parent
                                text: SystemInfo.formatCount(chip.modelData.count)
                                font.pixelSize: Theme.fontSizeXS
                                color: chip.active ? Theme.onAccent : Theme.textMuted
                            }
                        }
                    }

                    background: Rectangle {
                        radius: height / 2
                        color: chip.active ? Theme.accent
                             : chip.hovered ? Theme.surfaceElevated
                             : Theme.surface
                        border.width: Theme.borderWidth
                        border.color: chip.active ? Theme.accent : Theme.border

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }

                    onClicked: page.selectedCategory = chip.modelData.id
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacingLG

            // --------------------------------------------- list column
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.spacingMD

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: PackageService.model.totalCount > 0
                              ? qsTr("%1 packages · %2 installed size").arg(
                                    SystemInfo.formatCount(PackageService.model.totalCount)).arg(
                                    SystemInfo.formatBytes(PackageService.model.totalInstalledBytes))
                              : qsTr("Installed packages")
                        font.pixelSize: Theme.fontSizeSM
                        color: Theme.textMuted
                        Layout.fillWidth: true
                        visible: !PackageService.loading
                    }
                    Item { Layout.fillWidth: !PackageService.loading }
                    Text {
                        text: qsTr("Sort")
                        font.pixelSize: Theme.fontSizeSM
                        color: Theme.textMuted
                        visible: PackageService.model.totalCount > 0
                    }
                    MSegmented {
                        id: sortSelector
                        visible: PackageService.model.totalCount > 0
                        model: [qsTr("Size"), qsTr("Name"), qsTr("Version")]
                        onActivated: (index) => {
                            PackageService.model.sortBy(
                                index === 1 ? 1 : index === 2 ? 3 : 4,
                                sortDirection.descending)
                        }
                    }
                    MIconButton {
                        id: sortDirection
                        visible: PackageService.model.totalCount > 0
                        property bool descending: true
                        iconName: descending ? "arrow-down" : "arrow-up"
                        tooltip: descending ? qsTr("Descending") : qsTr("Ascending")
                        onClicked: descending = !descending
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: PackageService.loading ? 1
                                : PackageService.model.totalCount === 0 ? 2
                                : PackageService.lastError !== "" ? 3 : 0

                    ListView {
                        id: packageList
                        model: PackageService.model
                        clip: true

                        // Category sections (1.0.3-2). The model sorts by
                        // category rank first, so equal ids are contiguous.
                        // While a search is active the list degrades to flat
                        // results — group counts would not match the shown
                        // subset.
                        section.property: "categoryId"
                        section.criteria: ViewSection.FullString
                        section.delegate: Item {
                            required property string section

                            readonly property var info: {
                                const list = page.categories
                                for (let i = 0; i < list.length; ++i) {
                                    if (list[i].id === section)
                                        return list[i]
                                }
                                return { count: 0, bytes: 0 }
                            }

                            width: packageList.width
                            height: page.searchActive ? 0 : 32
                            visible: !page.searchActive

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 1
                                color: Theme.border
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingSM
                                anchors.verticalCenter: parent.verticalCenter
                                text: page.categoryLabel(parent.section)
                                font.pixelSize: Theme.fontSizeSM
                                font.weight: Font.DemiBold
                                font.capitalization: Font.AllUppercase
                                color: Theme.textMuted
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingSM
                                anchors.verticalCenter: parent.verticalCenter
                                text: SystemInfo.formatCount(info.count)
                                      + "  ·  "
                                      + SystemInfo.formatBytes(info.bytes)
                                font.pixelSize: Theme.fontSizeXS
                                font.family: Theme.monoFamily
                                color: Theme.textMuted
                            }
                        }

                        delegate: MListItem {
                            width: packageList.width
                            title: displayName
                            subtitle: packageName + "  ·  " + version + "  ·  " + architecture
                            selected: page.selectedPackage !== null
                                      && page.selectedPackage.packageName === packageName
                            onClicked: page.selectedPackage = PackageService.model.get(index)
                            trailing: Component {
                                Text {
                                    text: SystemInfo.formatBytes(size)
                                    font.pixelSize: Theme.fontSizeMD
                                    font.family: Theme.monoFamily
                                    color: Theme.textSecondary
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {}
                    }

                    // Loading
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MLoadingState {
                            anchors.centerIn: parent
                            label: qsTr("Reading installed packages…")
                            detail: "dpkg-query -W"
                        }
                    }

                    // Empty system (unlikely but honest)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MEmptyState {
                            anchors.centerIn: parent
                            title: qsTr("No installed packages found")
                            description: qsTr("dpkg-query returned no packages with 'installed' status.")
                            iconName: "package"
                        }
                    }

                    // Error
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        MErrorState {
                            anchors.centerIn: parent
                            title: qsTr("Could not list packages")
                            message: PackageService.lastError
                            details: PackageService.lastError
                            onRetry: PackageService.refresh()
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.border
                visible: page.selectedPackage !== null
            }

            // --------------------------------------------- details panel
            MCard {
                visible: page.selectedPackage !== null
                Layout.preferredWidth: 320
                Layout.maximumWidth: 360
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLG
                    spacing: Theme.spacingMD

                    Text {
                        text: page.selectedPackage !== null ? page.selectedPackage.displayName : ""
                        font.pixelSize: Theme.fontSizeXL
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    MValueRow { label: qsTr("Package"); value: page.selectedPackage !== null ? page.selectedPackage.packageName : ""; valueMono: true }
                    MValueRow { label: qsTr("Version"); value: page.selectedPackage !== null ? page.selectedPackage.version : ""; valueMono: true }
                    MValueRow { label: qsTr("Architecture"); value: page.selectedPackage !== null ? page.selectedPackage.architecture : ""; valueMono: true }
                    MValueRow { label: qsTr("Installed size"); value: page.selectedPackage !== null ? SystemInfo.formatBytes(page.selectedPackage.size) : "" }
                    MValueRow { label: qsTr("Section"); value: page.selectedPackage !== null ? page.selectedPackage.section : ""; valueMono: true }

                    Text {
                        text: page.selectedPackage !== null ? page.selectedPackage.summary : ""
                        font.pixelSize: Theme.fontSizeMD
                        color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        visible: text !== ""
                    }

                    Item { Layout.fillHeight: true }

                    MDestructiveButton {
                        text: qsTr("Uninstall…")
                        Layout.fillWidth: true
                        enabled: !PackageService.busy
                        onClicked: uninstallDialog.openFor(page.selectedPackage)
                    }
                }
            }
        }

        // --------------------------------------- uninstall progress
        MCard {
            visible: PackageService.busy
            Layout.fillWidth: true
            implicitHeight: uninstallProgress.implicitHeight + Theme.spacingLG * 2

            ColumnLayout {
                id: uninstallProgress
                anchors.fill: parent
                anchors.margins: Theme.spacingLG
                spacing: Theme.spacingSM

                Text {
                    text: qsTr("Package operation in progress")
                    font.pixelSize: Theme.fontSizeLG
                    font.weight: Font.DemiBold
                    color: Theme.textPrimary
                }
                Text {
                    text: qsTr("Authorization may be requested through the system security dialog. The operation runs with the system package manager; do not close the window.")
                    font.pixelSize: Theme.fontSizeSM
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                MProgressBar {
                    Layout.fillWidth: true
                    indeterminate: true
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90

                    Text {
                        text: PackageService.operationOutput
                        font.pixelSize: Theme.fontSizeXS
                        font.family: Theme.monoFamily
                        color: Theme.textMuted
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }

    // ------------------------------ uninstall confirmation (MM-043)
    MConfirmationDialog {
        id: uninstallDialog

        property var pkg: null

        function openFor(pkg) {
            if (!pkg)
                return
            uninstallDialog.pkg = pkg
            uninstallDialog.title = qsTr("Uninstall package?")
            uninstallDialog.message = qsTr(
                "The package will be removed with the system package manager (apt-get).")
            uninstallDialog.rows = [
                { label: qsTr("Package"), value: pkg.displayName },
                { label: qsTr("Name"), value: pkg.packageName },
                { label: qsTr("Version"), value: pkg.version },
                { label: qsTr("Installed size"), value: SystemInfo.formatBytes(pkg.size) }
            ]
            uninstallDialog.consequence = qsTr(
                "Packages that depend on it may also be removed. Administrator authorization will be requested before the operation starts. Files are never deleted manually.")
            uninstallDialog.confirmText = qsTr("Uninstall")
            open()
        }

        onAccepted: {
            if (pkg && !PackageService.uninstall(pkg.packageName, false))
                appWindow.showToast(qsTr("Cannot start uninstall"), "danger")
        }
    }
}
