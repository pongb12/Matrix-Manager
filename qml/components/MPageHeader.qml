// MPageHeader — optional icon, page title, subtitle and right-aligned actions.
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme

RowLayout {
    id: header

    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    default property alias actions: actionsRow.data

    spacing: Theme.spacingMD

    MIcon {
        name: header.iconName
        visible: header.iconName !== ""
        size: 26
        opacity: 0.85
        Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
        spacing: 2
        Layout.fillWidth: true

        Text {
            text: header.title
            font.pixelSize: Theme.fontSizeXXL
            font.weight: Font.DemiBold
            color: Theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: header.subtitle
            font.pixelSize: Theme.fontSizeMD
            color: Theme.textSecondary
            visible: text !== ""
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    RowLayout {
        id: actionsRow
        spacing: Theme.spacingSM
    }
}
