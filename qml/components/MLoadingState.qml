// MLoadingState — loading UI that explains what is happening (DOC.md rule 24).
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Theme

ColumnLayout {
    id: loadingState

    property string label: qsTr("Working…")
    property string detail: ""
    property bool cancellable: false
    signal cancelRequested()

    spacing: Theme.spacingMD

    BusyIndicator {
        running: loadingState.visible
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        text: loadingState.label
        font.pixelSize: Theme.fontSizeLG
        font.weight: Font.Medium
        color: Theme.textPrimary
        Layout.alignment: Qt.AlignHCenter
    }
    Text {
        text: loadingState.detail
        font.pixelSize: Theme.fontSizeSM
        font.family: Theme.monoFamily
        color: Theme.textMuted
        visible: text !== ""
        Layout.alignment: Qt.AlignHCenter
    }

    MSecondaryButton {
        text: qsTr("Cancel")
        visible: loadingState.cancellable
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacingSM
        onClicked: loadingState.cancelRequested()
    }
}
