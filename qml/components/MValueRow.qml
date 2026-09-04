// MValueRow — simple label/value row used in details views.
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme

RowLayout {
    id: valueRow

    property string label: ""
    property string value: ""
    property bool valueMono: false

    spacing: Theme.spacingMD
    Layout.fillWidth: true

    Text {
        text: valueRow.label
        font.pixelSize: Theme.fontSizeMD
        color: Theme.textMuted
        Layout.preferredWidth: 140
        elide: Text.ElideRight
    }
    Text {
        text: valueRow.value
        font.pixelSize: Theme.fontSizeMD
        font.family: valueRow.valueMono ? Theme.monoFamily : Theme.fontFamily
        color: Theme.textPrimary
        Layout.fillWidth: true
        wrapMode: Text.WrapAnywhere
    }
}
