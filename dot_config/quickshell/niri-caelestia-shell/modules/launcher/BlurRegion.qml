import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland

// Blur region shaped like the launcher's fill (Background.qml): the body with
// its top fillets, the band that flares out along the bottom edge, and the cove
// bites that carve the two bottom shoulders. Without the band the flare falls
// outside the blurred area and reads as a smear of tint over sharp wallpaper
// instead of a frosted extension. Every rectangle collapses when the panel is
// closed.
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

    // Bottom-left cove: this node's rect clips the ellipse to its bottom half,
    // and the node subtracts the intersection.
    Region {
        intersection: Intersection.Subtract
        x: root.bodyX - root.flare * 2
        y: root.bodyY + root.bodyH - root.flare
        width: root.flare * 4
        height: root.open ? root.flare : 0

        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Intersect
            x: root.bodyX - root.flare * 2
            y: root.bodyY + root.bodyH - root.flare * 2
            width: root.flare * 2
            height: root.open ? root.flare * 2 : 0
        }
    }

    // Bottom-right cove, mirrored.
    Region {
        intersection: Intersection.Subtract
        x: root.bodyX + root.bodyW - root.flare * 2
        y: root.bodyY + root.bodyH - root.flare
        width: root.flare * 4
        height: root.open ? root.flare : 0

        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Intersect
            x: root.bodyX + root.bodyW
            y: root.bodyY + root.bodyH - root.flare * 2
            width: root.flare * 2
            height: root.open ? root.flare * 2 : 0
        }
    }
}