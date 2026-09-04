/*
 * DuplicatesPage.qml — honest placeholder (MM-003 allows proper empty
 * states for pages whose task is not yet implemented).
 *
 * Duplicate detection is task MM-032 in TASK.md and is intentionally NOT
 * implemented in the MVP. This page says so instead of pretending.
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

    background: null

    MEmptyState {
        anchors.centerIn: parent
        title: qsTr("Duplicate file search is not implemented yet")
        description: qsTr(
            "It is planned as task MM-032 in TASK.md. The planned implementation compares file sizes first and only hashes candidates, so scanning stays fast and deterministic. Meanwhile, the Large Files page can help you reclaim space.")
        glyph: "⧉"

        MButton {
            text: qsTr("Open Large Files")
            onClicked: page.requestNavigate("largefiles")
        }
    }
}
