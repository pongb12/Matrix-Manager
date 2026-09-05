/*
 * Main.qml — application shell (MM-003).
 *
 * Fixed sidebar navigation + page container. Deliberately desktop-native:
 * no hero section, no card grid, no marketing layout (AGENT.md rule 13).
 * 1.0.3-1: themed icons in the navigation, a sliding selection indicator,
 * a short enter transition when switching sections, and the guided tour
 * overlay (replayable from Settings → Guide).
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
        { id: "overview",     label: qsTr("Overview"),     icon: "layout-dashboard" },
        { id: "storage",      label: qsTr("Storage"),      icon: "hard-drive" },
        { id: "applications", label: qsTr("Applications"), icon: "package" },
        { id: "cleanup",      label: qsTr("Cleanup"),      icon: "eraser" },
        { id: "largefiles",   label: qsTr("Large Files"),  icon: "file-search" },
        { id: "duplicates",   label: qsTr("Duplicates"),   icon: "copy" },
        { id: "settings",     label: qsTr("Settings"),     icon: "settings" }
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

    // Page lookup by objectName — used by the guided tour to reach a page
    // and prepare it (e.g. select the treemap mode) before its step.
    function findPage(what) {
        for (let i = 0; i < pagesArea.children.length; ++i) {
            const child = pagesArea.children[i]
            if (child.objectName === what)
                return child
        }
        return null
    }

    function openGuide() {
        guideOverlay.openGuide()
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
            objectName: "sidebarNav"
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
                    interactive: false

                    // sliding selection indicator (single element that
                    // glides to the active entry instead of a static bar)
                    Rectangle {
                        z: 100
                        width: 3
                        height: navList.currentItem ? navList.currentItem.height : 0
                        y: navList.currentItem ? navList.currentItem.y : 0
                        color: Theme.accent

                        Behavior on y { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easing } }
                        Behavior on height { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easing } }
                    }

                    delegate: ItemDelegate {
                        id: navDelegate
                        width: navList.width
                        height: 38
                        highlighted: ListView.isCurrentItem

                        background: Rectangle {
                            color: navDelegate.highlighted ? Theme.surfaceElevated
                                 : navDelegate.hovered ? Theme.surfaceSunken
                                 : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        }

                        contentItem: RowLayout {
                            spacing: Theme.spacingMD

                            Item { width: Theme.spacingMD; height: 1 }

                            MIcon {
                                name: modelData.icon
                                size: 17
                                opacity: navDelegate.highlighted ? 1.0 : 0.75

                                Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
                            }
                            Text {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeMD
                                font.weight: navDelegate.highlighted ? Font.DemiBold : Font.Normal
                                color: navDelegate.highlighted ? Theme.textPrimary
                                     : navDelegate.hovered ? Theme.textPrimary
                                     : Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
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
            id: pagesArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: navList.currentIndex
            transform: Translate { id: pageShift; x: 0 }

            OverviewPage {
                objectName: "pageOverview"
                onRequestNavigate: (pageId) => appWindow.navigate(pageId)
            }
            StoragePage { objectName: "pageStorage" }
            ApplicationsPage { objectName: "pageApplications" }
            CleanupPage { objectName: "pageCleanup" }
            LargeFilesPage { objectName: "pageLargeFiles" }
            DuplicatesPage { objectName: "pageDuplicates" }
            SettingsPage { objectName: "pageSettings" }
        }
    }

    // section switch: a short fade + slide that communicates the change
    // without slowing navigation down
    SequentialAnimation {
        id: pageEnter

        PropertyAction { target: pageShift; property: "x"; value: 18 }
        PropertyAction { target: pagesArea; property: "opacity"; value: 0.55 }
        ParallelAnimation {
            NumberAnimation {
                target: pageShift; property: "x"; to: 0
                duration: Theme.durationNormal; easing.type: Theme.easing
            }
            NumberAnimation {
                target: pagesArea; property: "opacity"; to: 1
                duration: Theme.durationNormal; easing.type: Theme.easing
            }
        }
    }
    Connections {
        target: navList
        function onCurrentIndexChanged() { pageEnter.restart() }
    }

    // -------------------------------------------------- guided tour
    MGuideOverlay {
        id: guideOverlay
        anchors.fill: parent
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
