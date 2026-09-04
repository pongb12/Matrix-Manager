/*
 * SettingsPage.qml — only settings with real value (MM-070, MM-071).
 *
 * Theme (system default respected), large-file threshold, destructive
 * confirmation, scan boundary options, About. No unnecessary settings.
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

    Component.onCompleted: {
        themeSelector.currentIndex = SettingsService.theme
        for (let i = 0; i < thresholds.length; ++i) {
            if (thresholds[i].bytes === SettingsService.largeFileThresholdBytes) {
                thresholdSelector.currentIndex = i
                return
            }
        }
        thresholdSelector.currentIndex = 1
    }

    readonly property var thresholds: [
        { label: "100 MB", bytes: 100 * 1024 * 1024 },
        { label: "500 MB", bytes: 500 * 1024 * 1024 },
        { label: "1 GB",   bytes: 1024 * 1024 * 1024 },
        { label: "5 GB",   bytes: 5 * 1024 * 1024 * 1024 }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingLG

        MPageHeader {
            title: qsTr("Settings")
            subtitle: qsTr("Preferences are stored locally on this machine only")
        }

        ScrollView {
            id: pageScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: pageScroll.width
                spacing: Theme.spacingLG

                // ------------------------------------------ appearance
                MCard {
                    Layout.fillWidth: true
                    implicitHeight: appearance.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: appearance
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        Text {
                            text: qsTr("Appearance")
                            font.pixelSize: Theme.fontSizeLG
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        RowLayout {
                            spacing: Theme.spacingMD

                            Text {
                                text: qsTr("Theme")
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textSecondary
                                Layout.preferredWidth: 240
                            }
                            MSegmented {
                                id: themeSelector
                                model: [qsTr("System"), qsTr("Light"), qsTr("Dark")]
                                onActivated: (index) => SettingsService.theme = index
                            }
                        }

                        RowLayout {
                            spacing: Theme.spacingMD

                            Text {
                                text: qsTr("Language")
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textSecondary
                                Layout.preferredWidth: 240
                            }
                            MSegmented {
                                id: languageSelector
                                model: [qsTr("Tiếng Việt"), qsTr("English")]
                                currentIndex: SettingsService.language === "en" ? 1 : 0
                                onActivated: (index) =>
                                    SettingsService.language = (index === 1 ? "en" : "vi")
                            }
                        }
                        Text {
                            text: qsTr("Interface language changes apply immediately.")
                            font.pixelSize: Theme.fontSizeXS
                            color: Theme.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // ------------------------------------------ scanning
                MCard {
                    Layout.fillWidth: true
                    implicitHeight: scanning.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: scanning
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        Text {
                            text: qsTr("Scanning")
                            font.pixelSize: Theme.fontSizeLG
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        RowLayout {
                            spacing: Theme.spacingMD

                            Text {
                                text: qsTr("Default large-file threshold")
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textSecondary
                                Layout.preferredWidth: 240
                            }
                            MSegmented {
                                id: thresholdSelector
                                model: page.thresholds.map(t => t.label)
                                onActivated: (index) => {
                                    SettingsService.largeFileThresholdBytes =
                                        page.thresholds[index].bytes
                                }
                            }
                        }

                        MSwitch {
                            text: qsTr("Follow symbolic links")
                            checked: SettingsService.followSymlinks
                            onToggled: SettingsService.followSymlinks = checked
                        }
                        Text {
                            text: qsTr("Off by default. A symlink can point anywhere, including outside the scanned tree or into a cycle. When enabled, cycle protection is applied.")
                            font.pixelSize: Theme.fontSizeXS
                            color: Theme.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            leftPadding: 38
                        }

                        MSwitch {
                            text: qsTr("Cross filesystem boundaries")
                            checked: SettingsService.crossFilesystems
                            onToggled: SettingsService.crossFilesystems = checked
                        }
                        Text {
                            text: qsTr("Off by default. Scans stay on the filesystem where they started and report mounted volumes as boundaries instead of entering them.")
                            font.pixelSize: Theme.fontSizeXS
                            color: Theme.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            leftPadding: 38
                        }
                    }
                }

                // ------------------------------------------ safety
                MCard {
                    Layout.fillWidth: true
                    implicitHeight: safety.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: safety
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        Text {
                            text: qsTr("Safety")
                            font.pixelSize: Theme.fontSizeLG
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        MSwitch {
                            text: qsTr("Confirm destructive operations")
                            checked: SettingsService.confirmDestructive
                            onToggled: SettingsService.confirmDestructive = checked
                        }
                        Text {
                            text: qsTr("Recommended on. Destructive operations always show explicit targets, sizes and consequences before running. Uninstall and cleanup always require confirmation regardless of this setting.")
                            font.pixelSize: Theme.fontSizeXS
                            color: Theme.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            leftPadding: 38
                        }
                    }
                }

                // ------------------------------------------ about (MM-071)
                MCard {
                    Layout.fillWidth: true
                    implicitHeight: about.implicitHeight + Theme.spacingLG * 2

                    ColumnLayout {
                        id: about
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingSM

                        Text {
                            text: qsTr("About")
                            font.pixelSize: Theme.fontSizeLG
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        MValueRow { label: qsTr("Application"); value: qsTr("Matrix Manager"); Layout.fillWidth: true }
                        MValueRow { label: qsTr("Version"); value: SystemInfo.appVersion; valueMono: true; Layout.fillWidth: true }
                        MValueRow { label: qsTr("Qt version"); value: SystemInfo.qtVersion; valueMono: true; Layout.fillWidth: true }
                        MValueRow { label: qsTr("Operating system"); value: SystemInfo.osName; Layout.fillWidth: true }
                        MValueRow { label: qsTr("Architecture"); value: SystemInfo.architecture; valueMono: true; Layout.fillWidth: true }
                        MValueRow { label: qsTr("Supported platforms"); value: SystemInfo.supportedPlatforms(); Layout.fillWidth: true }
                        MValueRow { label: qsTr("License"); value: qsTr("MIT"); valueMono: true; Layout.fillWidth: true }

                        Text {
                            text: qsTr("Matrix Manager works entirely on this machine. No AI, no background services, no telemetry, no accounts, no network access.")
                            font.pixelSize: Theme.fontSizeMD
                            color: Theme.textSecondary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.spacingSM
                        }
                    }
                }
            }
        }
    }
}
