import qs.components
import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland

// Blur region shaped like the popout's fill (Background.qml): the inset body
// with its bottom fillets, plus the flared top band and the cove bites that
// carve the shoulders. A plain rounded rect around the wrapper would leave
// blurred strips outside the frost on both sides, since the body now sits one
// flare inside the wrapper.
//
// The dimensions track the wrapper, so every rectangle collapses back to zero
// when no popout is open.
Region {
    id: root

    required property Item wrapper
    required property Item bar
    required property bool invertBottomRounding

    readonly property int flare: wrapper.isDetached ? Appearance.rounding.normal : Config.border.rounding
    readonly property bool open: root.wrapper.width > 0
    // animX/animY, not x/y: the popout wrapper slides itself with a translate
    // of (animX - x), so its content is drawn at animX while x snaps to the
    // final spot. The blurred area has to sit under the fill, which sits
    // under the content.
    readonly property int bodyX: Math.round(root.wrapper.animX + Config.border.thickness + root.flare)
    readonly property int bodyY: Math.round(root.wrapper.animY + root.bar.implicitHeight)
    readonly property int bodyW: Math.max(0, Math.round(root.wrapper.width - root.flare * 2))
    readonly property int bodyH: Math.max(0, Math.round(root.wrapper.height))

    // Base rect: the body, with its bottom fillets. The top corners are left
    // square because the cove bites carve them.
    //
    // Every Region in a boolean chain needs its own rect — an unset one is
    // empty, so Subtract/Intersect would collapse. `intersection` says how a
    // node folds into its *parent's* region, so the carves carry Subtract
    // while the body node and the band stay Combines.
    x: root.bodyX
    y: root.bodyY
    width: root.bodyW
    height: root.open ? root.bodyH : 0
    bottomLeftRadius: root.invertBottomRounding ? 0 : root.flare
    bottomRightRadius: root.invertBottomRounding ? 0 : root.flare

    // Flared top band, running out to both tips.
    Region {
        x: root.bodyX - root.flare
        y: root.bodyY
        width: root.bodyW + root.flare * 2
        height: root.open ? root.flare : 0
    }

    // Top-left cove: this node's rect is the clip that keeps the ellipse to
    // its top half, and the node subtracts the intersection.
    Region {
        intersection: Intersection.Subtract
        x: root.bodyX - root.flare * 2
        y: root.bodyY
        width: root.flare * 4
        height: root.open ? root.flare : 0

        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Intersect
            x: root.bodyX - root.flare * 2
            y: root.bodyY
            width: root.flare * 2
            height: root.open ? root.flare * 2 : 0
        }
    }

    // Top-right cove, mirrored.
    Region {
        intersection: Intersection.Subtract
        x: root.bodyX + root.bodyW - root.flare * 2
        y: root.bodyY
        width: root.flare * 4
        height: root.open ? root.flare : 0

        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Intersect
            x: root.bodyX + root.bodyW
            y: root.bodyY
            width: root.flare * 2
            height: root.open ? root.flare * 2 : 0
        }
    }
}