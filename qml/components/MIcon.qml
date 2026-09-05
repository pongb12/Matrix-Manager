// MIcon — themed SVG icon from the bundled Lucide-derived icon set
// (see resources/icons/LICENSE-NOTES.md). The set ships four ink variants:
// light/dark theme ink plus the matching on-accent ink for filled buttons.
// Icons support the theme; they never carry meaning without a tooltip or
// label nearby (AGENT.md rule 18).
import QtQuick
import MatrixManager.Theme

Image {
    id: icon

    // Icon name without extension, e.g. "folder-open".
    property string name: ""
    property int size: 18
    // "auto"     — ink matching the current theme text colour
    // "onaccent" — ink for icons placed on a filled accent surface
    property string tint: "auto"

    readonly property string _dir: tint === "onaccent"
        ? (Theme.dark ? "onaccent-dark" : "onaccent-light")
        : (Theme.dark ? "dark" : "light")

    width: size
    height: size
    source: name === "" ? "" : "qrc:/icons/" + _dir + "/" + name + ".svg"
    sourceSize: Qt.size(size * 2, size * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true

    // A missing icon file must never render as a broken frame; callers
    // keep their text labels so meaning survives regardless.
    visible: status === Image.Ready
}
