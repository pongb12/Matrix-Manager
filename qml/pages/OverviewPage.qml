/*
 * OverviewPage.qml — honest dashboard (MM-060, MM-061).
 *
 * Shows cheap, real data (volumes, cleanup estimates, session activity).
 * Nothing is fabricated; expensive data is loaded on demand with explicit
 * user action. No fake KPI cards (AGENT.md rule 13, DOC.md rule 5).
 */
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Core
import MatrixManager.Theme
import MatrixManager.Components

Page {
    id: page

    signal requestNavigate(string pageId)

    // Cleanup estimates are cheap directory listings; load once on demand.
    property var cleanupEstimates: ({})

    background: null

    function refreshEstimates() {
        const rules = CleanupService.rules()
        let estimates = {}
        for (let i = 0; i < rules.length; ++i) {
            const est = CleanupService.estimate(rules[i].id)
            estimates[rules[i].id] = est
        }
        cleanupEstimates = estimates
    }

    function ruleName(id) {
        return page.ruleI18n[id] || id
    }

    // Translated rule names, keyed by id (retranslate-safe property).
    readonly property var ruleI18n: ({
        "user-trash": qsTr("Trash"),
        "apt-cache": qsTr("APT package cache"),
        "thumbnail-cache": qsTr("Thumbnail cache")
    })

    Component.onCompleted: refreshEstimates()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingLG

        MPageHeader {
            iconName: "layout-dashboard"
            title: qsTr("Overview")
            subtitle: qsTr("Current storage status and activity from this session")

            MIconButton {
                iconName: "refresh-cw"
                tooltip: qsTr("Refresh estimates")
                onClicked: page.refreshEstimates()
            }
        }

        ScrollView {
            id: pageScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: pageScroll.width
                spacing: Theme.spacingLG

                // -------------------------------------- storage row
                RowLayout {
                    spacing: Theme.spacingLG
                    Layout.fillWidth: true

                    // Primary volume
                    MCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 420
                        Layout.maximumWidth: 480
                        Layout.preferredHeight: 150

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingLG
                            spacing: Theme.spacingSM

                            Text {
                                text: qsTr("Storage")
                                font.pixelSize: Theme.fontSizeLG
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }

                            Repeater {
                                model: StorageService.volumes().slice(0, 3)

                                MUsageBar {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    label: modelData.mountPoint + (modelData.isRoot ? qsTr("  (system)") : "")
                                    valueText: SystemInfo.formatBytes(modelData.usedBytes) + " / " + SystemInfo.formatBytes(modelData.totalBytes)
                                    usedFraction: modelData.totalBytes > 0 ? modelData.usedBytes / modelData.totalBytes : 0
                                    legendRight: qsTr("%1 free").arg(SystemInfo.formatBytes(modelData.freeBytes))
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Cleanup opportunities
                    MCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 420
                        Layout.maximumWidth: 480
                        Layout.preferredHeight: 150

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingLG
                            spacing: Theme.spacingSM

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: qsTr("Cleanup opportunities")
                                    font.pixelSize: Theme.fontSizeLG
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                    Layout.fillWidth: true
                                }
                                MButton {
                                    text: qsTr("Open")
                                    onClicked: page.requestNavigate("cleanup")
                                }
                            }

                            Repeater {
                                model: {
                                    const rules = CleanupService.rules()
                                    const out = []
                                    for (let i = 0; i < rules.length; ++i) {
                                        const est = page.cleanupEstimates[rules[i].id]
                                        out.push({
                                            name: page.ruleName(rules[i].id),
                                            bytes: est ? est.bytes : 0
                                        })
                                    }
                                    return out
                                }

                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeMD
                                        color: Theme.textSecondary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: SystemInfo.formatBytes(modelData.bytes)
                                        font.pixelSize: Theme.fontSizeMD
                                        font.family: Theme.monoFamily
                                        color: Theme.textPrimary
                                    }
                                }
                            }

                            Text {
                                text: qsTr("Estimates cover known-safe locations only. Nothing is cleaned without your confirmation.")
                                font.pixelSize: Theme.fontSizeXS
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // -------------------------------------- activity + apps row
                RowLayout {
                    spacing: Theme.spacingLG
                    Layout.fillWidth: true

                    // Session activity (MM-061)
                    MCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 420
                        Layout.maximumWidth: 480
                        Layout.preferredHeight: 190

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingLG
                            spacing: Theme.spacingSM

                            Text {
                                text: qsTr("Session activity")
                                font.pixelSize: Theme.fontSizeLG
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }

                            ListView {
                                id: activityList
                                model: ActivityLog.entries()
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 2

                                delegate: RowLayout {
                                    width: activityList.width
                                    spacing: Theme.spacingSM

                                    Text {
                                        text: Qt.formatTime(modelData.timestamp, "HH:mm")
                                        font.pixelSize: Theme.fontSizeSM
                                        font.family: Theme.monoFamily
                                        color: Theme.textMuted
                                    }
                                    Text {
                                        text: modelData.message
                                        font.pixelSize: Theme.fontSizeMD
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: activityList.count === 0
                                    text: qsTr("No actions yet in this session. Actions you take here will be listed.")
                                    font.pixelSize: Theme.fontSizeMD
                                    color: Theme.textMuted
                                    wrapMode: Text.WordWrap
                                    width: activityList.width
                                }
                            }
                        }
                    }

                    // Applications summary
                    MCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 420
                        Layout.maximumWidth: 480
                        Layout.preferredHeight: 190

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingLG
                            spacing: Theme.spacingSM

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: qsTr("Applications")
                                    font.pixelSize: Theme.fontSizeLG
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                    Layout.fillWidth: true
                                }
                                MButton {
                                    text: qsTr("Open")
                                    onClicked: page.requestNavigate("applications")
                                }
                            }

                            Text {
                                text: PackageService.loading
                                      ? qsTr("Reading installed packages…")
                                      : qsTr("%1 packages installed · %2 on disk").arg(
                                            PackageService.model.totalCount).arg(
                                            SystemInfo.formatBytes(PackageService.model.totalInstalledBytes))
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textSecondary
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                text: qsTr("Package data is read with dpkg-query on demand and is never cached between sessions.")
                                font.pixelSize: Theme.fontSizeXS
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // Deeper tools pointer — no fake "largest files" data here.
                Text {
                    text: qsTr("Looking for space hogs? Use Storage to explore directories and Large Files to find big files by threshold.")
                    font.pixelSize: Theme.fontSizeMD
                    color: Theme.textMuted
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.bottomMargin: Theme.spacingSM
                }
            }
        }
    }
}
