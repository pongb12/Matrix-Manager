/*
 * Main.qml — application shell (MM-003).
 *
 * Fixed sidebar navigation + page container. Deliberately desktop-native:
 * no hero section, no card grid, no marketing layout (AGENT.md rule 13).
 */
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Core
import MatrixManager.Theme
import MatrixManager.Components
import MatrixManager.Pages

ApplicationWindow {
    id: appWindow

    readonly property var navModel: [
        { id: "overview",     label: qsTr("Overview") },
        { id: "storage",      label: qsTr("Storage") },
        { id: "applications", label: qsTr("Applications") },
        { id: "cleanup",      label: qsTr("Cleanup") },
        { id: "largefiles",   label: qsTr("Large Files") },
        { id: "duplicates",   label: qsTr("Duplicates") },
        { id: "settings",     label: qsTr("Settings") }
    ]

    width: 1180
    height: 760
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    title: qsTr("Matrix Manager")
    color: Theme.background
    font.pixelSize: Theme.fontSizeMD

    function showToast(message, tone) {
        toastHost.show(message, tone || "neutral")
    }

    function navigate(pageId) {
        for (let i = 0; i < navModel.length; ++i) {
            if (navModel[i].id === pageId) {
                navList.currentIndex = i
                return
            }
        }
    }

    // QA hook used by automated UI checks (no effect in normal use).
    function qaShowPage(i) {
        navList.currentIndex = i
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // -------------------------------------------------- sidebar
        Rectangle {
            Layout.preferredWidth: 216
            Layout.fillHeight: true
            color: Theme.surface

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Brand block
                ColumnLayout {
                    Layout.margins: Theme.spacingLG
                    spacing: 2

                    Text {
                        text: qsTr("Matrix Manager")
                        font.pixelSize: Theme.fontSizeLG
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "v" + SystemInfo.appVersion + " · " + SystemInfo.osName
                        font.pixelSize: Theme.fontSizeXS
                        font.family: Theme.monoFamily
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        Layout.maximumWidth: 170
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                // Navigation
                ListView {
                    id: navList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: Theme.spacingSM
                    model: appWindow.navModel
                    currentIndex: 0
                    keyNavigationWraps: true
                    clip: true

                    delegate: ItemDelegate {
                        id: navDelegate
                        width: navList.width
                        height: 38
                        highlighted: ListView.isCurrentItem

                        background: Rectangle {
                            color: navDelegate.highlighted ? Theme.surfaceElevated
                                 : navDelegate.hovered ? Theme.surfaceSunken
                                 : "transparent"

                            Rectangle {
                                width: 3
                                height: parent.height
                                color: navDelegate.highlighted ? Theme.accent : "transparent"
                            }
                        }

                        contentItem: Text {
                            leftPadding: Theme.spacingLG
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.label
                            font.pixelSize: Theme.fontSizeMD
                            font.weight: navDelegate.highlighted ? Font.DemiBold : Font.Normal
                            color: navDelegate.highlighted ? Theme.textPrimary
                                 : navDelegate.hovered ? Theme.textPrimary
                                 : Theme.textSecondary
                        }

                        onClicked: navList.currentIndex = index
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                Text {
                    Layout.margins: Theme.spacingMD
                    text: qsTr("Local only · no network access")
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textMuted
                }
            }
        }

        // Separator
        Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.border }

        // -------------------------------------------------- pages
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: navList.currentIndex

            OverviewPage {
                onRequestNavigate: (pageId) => appWindow.navigate(pageId)
            }
            StoragePage {}
            ApplicationsPage {}
            CleanupPage {}
            LargeFilesPage {}
            DuplicatesPage {
                onRequestNavigate: (pageId) => appWindow.navigate(pageId)
            }
            SettingsPage {}
        }
    }

    // -------------------------------------------------- toast host
    ColumnLayout {
        id: toastHost
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.spacingXL
        spacing: Theme.spacingSM
        z: 100

        function show(message, tone) {
            const item = toastComponent.createObject(toastHost, {
                text: message,
                tone: tone || "neutral"
            })
            if (!item)
                return
            item.visible = true
        }

        Component {
            id: toastComponent
            Control {
                id: toastWrapper

                property var timer: Timer {
                    interval: 4200
                    running: true
                    onTriggered: toastWrapper.destroy()
                }

                opacity: 0
                scale: 0.97
                Component.onCompleted: {
                    toastWrapper.opacity = 1
                    toastWrapper.scale = 1
                }

                Behavior on opacity { NumberAnimation { duration: Theme.durationNormal } }
                Behavior on scale { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easing } }

                contentItem: MToast {}

                background: null
            }
        }
    }
}
