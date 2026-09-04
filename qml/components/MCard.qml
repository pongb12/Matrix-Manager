// MCard — restrained surface for grouping related content.
// Used sparingly: hierarchy first, decoration never (AGENT.md rule 13).
// Callers place a layout inside with margins from the Theme spacing scale.
import QtQuick
import MatrixManager.Theme

Rectangle {
    id: card

    property bool elevated: false

    implicitWidth: 200
    implicitHeight: 100
    radius: Theme.radiusLG
    color: elevated ? Theme.surfaceElevated : Theme.surface
    border.width: Theme.borderWidth
    border.color: Theme.border
}
