import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland

// Blur region shaped like the dashboard panel's fill. Translucent fills hide
// the wallpaper behind them unless the window behind is blurred, so a region
// matching the panel's body (plus the flared top and cove corners) is
// what keeps the dashboard legible. The flared band and cove bites live here
// — this file is part of the dashboard module, and the dimensions track the
// panel so they collapse back to zero when the panel is not drawn.
//
// QML Region cannot be condense 0-area children to empty, so when the panel
// is closed the band/body are defined at zero height.
Region {
    id: root

    required property Item dashboard
    required property Item bar

    readonly property int flare: Config.border.rounding
    readonly property bool open: root.dashboard.height > 0
    readonly property int bodyX: root.dashboard.x + Config.border.thickness
    readonly property int bodyY: root.dashboard.y + bar.implicitHeight
    readonly property int bodyW: root.dashboard.width

    // The body is the base rect, so the wings only ever exist in the top
    // bandadded below. Bottom corners round off to match the dashboard fill;
    // the top corners are left square because the cove bites carve them.
    //
    // Every Region in a boolean chain needs its own rect — an unset one is
    // empty, so Subtract/Intersect would collapse. And `intersection` says
    // how a node folds into its *parent's* region, so the carves carry
    // Subtract while the body node and the band stay Combines.
    x: root.bodyX
    y: root.bodyY
    width: root.bodyW
    height: root.open ? root.dashboard.height : 0
    bottomLeftRadius: root.flare
    bottomRightRadius: root.flare

    // Flared top band, running out to both tips. Only present while the
    // dashboard is open; the while-closed geometry has zero height.
    Region {
        x: root.bodyX - root.flare
        y: root.bodyY
        width: root.bodyW + root.flare * 2
        height: root.open ? root.flare : 0
    }

    // Top-left cove. This node's own rect is the clip that keeps the
    // ellipse to its top half; the ellipse child intersects with it, and
    // the node subtracts the result.
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
