pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Pergamino nocturno: marrones cálidos y letra vainilla

    // colores
    readonly property color bgChip: "#f04a382a"
    readonly property color bgPopup: "#fa4a382a"
    readonly property color bgCell: "#808c6c4e"
    readonly property color line: "#8c6d4f"
    readonly property color fg: "#f6ebcf"
    readonly property color fgMuted: "#d0b992"
    readonly property color accent: "#e2b564"
    readonly property color accent2: "#cf7b55"
    readonly property color ok: "#adc783"
    readonly property color fgOnAccent: "#2d1e12"

    // formas
    readonly property int radius: 14
    readonly property int radiusSmall: 8

    // tipografías
    readonly property string fontSerif: "Cormorant Garamond"
    readonly property string fontUi: "JetBrainsMono Nerd Font"
    readonly property string fontIcons: "JetBrainsMono Nerd Font"

    // tamaños
    readonly property int sizeText: 12
    readonly property int sizeClock: 15
    readonly property int chipHeight: 28
    readonly property var spines: ["#8a3b32", "#3d5566", "#a8793f", "#5e3d52", "#6f4a32"]
    readonly property color wood: "#7a5638"
}
