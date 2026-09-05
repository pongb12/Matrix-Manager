/*
 * Theme.qml — central design token system (MM-010).
 *
 * Every colour, spacing, radius, typography and animation value used by the
 * UI comes from here. No raw hex values are scattered through QML
 * (AGENT.md rule 15, DOC.md rule 21).
 *
 * Design direction (DOC.md rule 18): technical, utilitarian, precise, calm.
 * One restrained green accent on a near-monochrome surface scale. No
 * gradients, no glassmorphism, no AI-purple.
 */
pragma Singleton

import QtQuick
import MatrixManager.Core

QtObject {
    id: root

    readonly property bool dark: SettingsService.effectiveTheme === 2

    // ------------------------------------------------------------------
    // Palettes — semantic colours only.
    // ------------------------------------------------------------------
    readonly property var _darkPalette: ({
        background:      "#121417",
        surface:         "#191D21",
        surfaceElevated: "#21262B",
        surfaceSunken:   "#0C0E10",
        border:          "#2A3037",
        borderStrong:    "#3C434B",
        textPrimary:     "#E6E9EC",
        textSecondary:   "#A7AEB5",
        textMuted:       "#6E767E",
        accent:          "#4C9E7F",
        accentHover:     "#5BAE8E",
        accentPressed:   "#3F8A6F",
        onAccent:        "#0B1310",
        success:         "#4C9E7F",
        warning:         "#C9A227",
        danger:          "#C75450",
        dangerHover:     "#D46561",
        focus:           "#7BBFA2",
        overlay:         "#000000",

        // Ink and lines used ABOVE the dimmed backdrop (guided tour floating
        // cards). The dim layer darkens the UI in both themes, so these stay
        // light even in the light palette.
        overlayText:       "#E6E9EC",
        overlayTextMuted:  "#A7AEB5",
        overlayBorder:     "#FFFFFF",
        overlayAccent:     "#4C9E7F",
        overlayHover:      "#2A3037"
    })

    readonly property var _lightPalette: ({
        background:      "#F3F4F5",
        surface:         "#FFFFFF",
        surfaceElevated: "#FFFFFF",
        surfaceSunken:   "#E8EAEC",
        border:          "#D8DCDF",
        borderStrong:    "#B4BAC0",
        textPrimary:     "#1C2126",
        textSecondary:   "#4E565E",
        textMuted:       "#7A828A",
        accent:          "#2E7D5F",
        accentHover:     "#276C52",
        accentPressed:   "#225C46",
        onAccent:        "#FFFFFF",
        success:         "#2E7D5F",
        warning:         "#8F7014",
        danger:          "#B03A36",
        dangerHover:     "#99322F",
        focus:           "#2E7D5F",
        overlay:         "#000000",

        // Over-dim tokens: the light theme's normal ink is too dark to read
        // on the dimmed backdrop, so floating surfaces flip to light ink.
        // Border/accent follow the tour spec: green outline on light mode.
        overlayText:       "#EDF0F2",
        overlayTextMuted:  "#C6CCD1",
        overlayBorder:     "#2E7D5F",
        overlayAccent:     "#2E7D5F",
        overlayHover:      "#3A4046"
    })

    readonly property var _p: dark ? _darkPalette : _lightPalette

    readonly property color background:      _p.background
    readonly property color surface:         _p.surface
    readonly property color surfaceElevated: _p.surfaceElevated
    readonly property color surfaceSunken:   _p.surfaceSunken
    readonly property color border:          _p.border
    readonly property color borderStrong:    _p.borderStrong
    readonly property color textPrimary:     _p.textPrimary
    readonly property color textSecondary:   _p.textSecondary
    readonly property color textMuted:       _p.textMuted
    readonly property color accent:          _p.accent
    readonly property color accentHover:     _p.accentHover
    readonly property color accentPressed:   _p.accentPressed
    readonly property color onAccent:        _p.onAccent
    readonly property color success:         _p.success
    readonly property color warning:         _p.warning
    readonly property color danger:          _p.danger
    readonly property color dangerHover:     _p.dangerHover
    readonly property color focus:           _p.focus
    readonly property color overlay:         _p.overlay

    // Ink/lines for floating surfaces above the dim layer (1.0.3-3).
    readonly property color overlayText:       _p.overlayText
    readonly property color overlayTextMuted:  _p.overlayTextMuted
    readonly property color overlayBorder:     _p.overlayBorder
    readonly property color overlayAccent:     _p.overlayAccent
    readonly property color overlayHover:      _p.overlayHover

    // Category colours for storage classification (fixed, both themes).
    readonly property var categoryColors: [
        "#4C9E7F", "#7A9E4C", "#4C7F9E", "#9E7A4C",
        "#8E6A9E", "#9E4C5F", "#5F8A9E", "#778088"
    ]

    // ------------------------------------------------------------------
    // Spacing scale
    // ------------------------------------------------------------------
    readonly property int spacingXS: 4
    readonly property int spacingSM: 8
    readonly property int spacingMD: 12
    readonly property int spacingLG: 16
    readonly property int spacingXL: 24
    readonly property int spacingXXL: 32

    // ------------------------------------------------------------------
    // Radius scale — restrained, desktop-appropriate.
    // ------------------------------------------------------------------
    readonly property int radiusSM: 4
    readonly property int radiusMD: 6
    readonly property int radiusLG: 8

    // ------------------------------------------------------------------
    // Typography (MM-011): one family, hierarchy through size and weight.
    // Mono font used for paths, package names and sizes.
    // ------------------------------------------------------------------
    readonly property string fontFamily: ""
    readonly property string monoFamily: SystemInfo.monoFontFamily

    readonly property int fontSizeXS: 11
    readonly property int fontSizeSM: 12
    readonly property int fontSizeMD: 13   // body
    readonly property int fontSizeLG: 14
    readonly property int fontSizeXL: 17
    readonly property int fontSizeXXL: 21
    readonly property int fontSizeDisplay: 26

    // ------------------------------------------------------------------
    // Motion — explains state changes, never decorative (DOC.md rule 22).
    // ------------------------------------------------------------------
    readonly property int durationFast: 120
    readonly property int durationNormal: 180
    readonly property int durationSlow: 260
    readonly property var easing: Easing.OutCubic

    // ------------------------------------------------------------------
    // Component metrics
    // ------------------------------------------------------------------
    readonly property int controlHeight: 34
    readonly property int controlHeightSmall: 28
    readonly property int listItemHeight: 52
    readonly property int borderWidth: 1
    readonly property int focusWidth: 2
}
