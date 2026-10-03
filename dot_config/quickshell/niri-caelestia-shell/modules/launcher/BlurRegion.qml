import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland

// Blur region shaped like the launcher's fill (Background.qml): the body with
// its top fillets, plus the band that flares out along the bottom edge. The
// band is what makes the flare read as a frosted extension — without it the
// flare sits over sharp wallpaper while the body behind it is blurred. The
// concave notch at each shoulder is left blurred rather than carved back out:
// it is a thin crescent, and carving it left the flare itself unblurred.
Region {
    id: root

    required property Item launcher
    required property Item bar

    readonly property int flare: Config.border.rounding
    readonly property bool open: root.launcher.height > 0
    readonly property int bodyX: Math.round(root.launcher.x + Config.border.thickness)
    readonly property int bodyY: Math.round(root.launcher.y + root.bar.implicitHeight)
    readonly property int bodyW: Math.max(0, Math.round(root.launcher.width))
    readonly property int bodyH: Math.max(0, Math.round(root.launcher.height))

    x: root.bodyX
    y: root.bodyY
    width: root.bodyW
    height: root.open ? root.bodyH : 0
    topLeftRadius: root.flare
    topRightRadius: root.flare

    // Flared band along the bottom edge, running out to both tips.
    Region {
        x: root.bodyX - root.flare
        y: root.bodyY + root.bodyH - root.flare
        width: root.bodyW + root.flare * 2
        height: root.open ? root.flare : 0
    }
}