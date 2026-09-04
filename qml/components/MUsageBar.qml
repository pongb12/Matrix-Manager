// MUsageBar — volume usage display: label, value, proportional bar, legend.
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme
import "."

ColumnLayout {
    id: usageBar

    property string label: ""
    property string valueText: ""
    property real usedFraction: 0        // 0..1
    property string legendLeft: ""
    property string legendRight: ""

    spacing: Theme.spacingXS
    Layout.fillWidth: true

    RowLayout {
        spacing: Theme.spacingSM
        Layout.fillWidth: true

        Text {
            text: usageBar.label
            font.pixelSize: Theme.fontSizeMD
            font.weight: Font.Medium
            color: Theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: usageBar.valueText
            font.pixelSize: Theme.fontSizeMD
            font.family: Theme.monoFamily
            color: Theme.textSecondary
        }
    }

    Rectangle {
        id: track
        Layout.fillWidth: true
        height: 8
        radius: height / 2
        color: Theme.surfaceSunken

        Rectangle {
            width: Math.max(0, Math.min(1, usageBar.usedFraction)) * parent.width
            height: parent.height
            radius: parent.radius
            color: usageBar.usedFraction >= 0.95 ? Theme.danger
                 : usageBar.usedFraction >= 0.85 ? Theme.warning
                 : Theme.accent

            Behavior on width { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easing } }
            Behavior on color { ColorAnimation { duration: Theme.durationNormal } }
        }
    }

    RowLayout {
        visible: usageBar.legendLeft !== "" || usageBar.legendRight !== ""
        Layout.fillWidth: true

        Text {
            text: usageBar.legendLeft
            font.pixelSize: Theme.fontSizeSM
            color: Theme.textMuted
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        Text {
            text: usageBar.legendRight
            font.pixelSize: Theme.fontSizeSM
            color: Theme.textMuted
            horizontalAlignment: Text.AlignRight
            // Cap the right legend so the left one keeps usable space with
            // longer (translated) strings; both elide gracefully.
            Layout.maximumWidth: usageBar.width * 0.62
            elide: Text.ElideRight
        }
    }
}
