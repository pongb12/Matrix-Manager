// MEmptyState — meaningful empty state with explanation and next action
// (DOC.md rule 23). Avoids "Nothing here :)".
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme

ColumnLayout {
    id: emptyState

    property string glyph: "◌"
    property string title: ""
    property string description: ""
    default property alias actions: actionsRow.data

    spacing: Theme.spacingSM

    Text {
        text: emptyState.glyph
        font.pixelSize: Theme.fontSizeDisplay + 6
        font.family: Theme.monoFamily
        color: Theme.textMuted
        Layout.alignment: Qt.AlignHCenter
    }
    Text {
        text: emptyState.title
        font.pixelSize: Theme.fontSizeXL
        font.weight: Font.DemiBold
        color: Theme.textPrimary
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
    Text {
        text: emptyState.description
        font.pixelSize: Theme.fontSizeMD
        color: Theme.textSecondary
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.maximumWidth: 420
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }
    RowLayout {
        id: actionsRow
        spacing: Theme.spacingSM
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacingSM
    }
}
