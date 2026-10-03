import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland

// Blur region shaped like the quick toggles fill (QuickTogglesBackground.qml):
// the body with its two left fillets, the band flaring left along the bottom
// edge, and the band flaring up along the right edge. Without those bands the
// flares sit outside the blurred area and read as tint smeared over sharp
// wallpaper. The concave notch at each shoulder is left blurred rather than
// carved back out: it is a thin crescent, and carving it left the flare itself
// unblurred.
Region {
    id: root

    required property Item quicktoggles
    required property Item bar

    readonly property int flare: Config.border.rounding
    readonly property bool open: root.quicktoggles.height > 0
    readonly property int bodyX: Math.round(root.quicktoggles.x + Config.border.thickness)
    readonly property int bodyY: Math.round(root.quicktoggles.y + root.bar.implicitHeight)
    readonly property int bodyW: Math.max(0, Math.round(root.quicktoggles.width))
    readonly property int bodyH: Math.max(0, Math.round(root.quicktoggles.height))

    // The right and bottom edges are flush with the screen, so only the two
    // left corners are filleted.
    x: root.bodyX
    y: root.bodyY
    width: root.bodyW
    height: root.open ? root.bodyH : 0
    topLeftRadius: root.flare
    bottomLeftRadius: root.flare

    // Band flaring left along the bottom edge.
    Region {
        x: root.bodyX - root.flare
        y: root.bodyY + root.bodyH - root.flare
        width: root.flare
        height: root.open ? root.flare : 0
    }

    // Band flaring up along the right edge.
    Region {
        x: root.bodyX + root.bodyW - root.flare
        y: root.bodyY - root.flare
        width: root.flare
        height: root.open ? root.bodyH + root.flare : 0
    }
}