import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland

// Blur region shaped like the quick toggles fill (QuickTogglesBackground.qml):
// the body with its two inner fillets, the band flaring left along the bottom
// edge, and the band flaring up along the right edge, each with a cove bite at
// the shoulder. Without the bands the flares fall outside the blurred area and
// read as a smear of tint over sharp wallpaper instead of a frosted extension.
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

    // Bottom-left cove.
    Region {
        intersection: Intersection.Subtract
        x: root.bodyX - root.flare * 2
        y: root.bodyY + root.bodyH - root.flare
        width: root.flare * 3
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

    // Band flaring up along the right edge.
    Region {
        x: root.bodyX + root.bodyW - root.flare
        y: root.bodyY - root.flare
        width: root.flare
        height: root.bodyH + root.flare
    }

    // Top-right cove, mirrored onto the vertical band: the clip keeps the
    // ellipse to its left half.
    Region {
        intersection: Intersection.Subtract
        x: root.bodyX + root.bodyW - root.flare
        y: root.bodyY - root.flare * 2
        width: root.flare
        height: root.open ? root.flare * 3 : 0

        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Intersect
            x: root.bodyX + root.bodyW - root.flare * 2
            y: root.bodyY - root.flare * 2
            width: root.flare * 2
            height: root.open ? root.flare * 2 : 0
        }
    }
}