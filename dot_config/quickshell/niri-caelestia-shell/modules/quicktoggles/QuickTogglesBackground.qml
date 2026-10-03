import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

// Panel in the bottom-right corner, flush with the right and bottom screen
// edges. Same flare motif as the dashboard, rotated onto the two edges that
// lie along the screen: the bottom edge flares out to the left past the body,
// and the right edge flares up past the top of the panel, each with a concave
// cove. The two inner corners keep plain fillets.
ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.border.rounding
    readonly property real flare: rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    // startX/startY are the screen's bottom-right corner, so the body spans
    // x from startX - width to startX and y from startY - height to startY.
    readonly property real leftEdge: startX - wrapper.width
    readonly property real top: startY - wrapper.height

    strokeWidth: -1
    // Same frost as the launcher, notifications and bar popouts.
    fillColor: Colours.frost

    // Screen corner, left along the bottom edge out past the flared tip, then
    // up the left side, across the top, up the right flare and back down the
    // screen edge to the corner.
    PathMove {
        x: 0
        y: 0
    }

    PathLine {
        relativeX: -(root.wrapper.width + root.flare)
        relativeY: 0
    }

    // Concave cove at the bottom-left shoulder.
    PathArc {
        relativeX: root.flare
        relativeY: -root.roundingY
        radiusX: root.flare
        radiusY: root.roundingY
        direction: PathArc.Counterclockwise
    }

    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY * 2)
    }

    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Clockwise
    }

    PathLine {
        relativeX: root.wrapper.width - root.rounding
        relativeY: 0
    }

    // Concave cove up to the tip of the right flare, then straight back down
    // the screen edge.
    PathArc {
        relativeX: root.rounding
        relativeY: -root.flare
        radiusX: root.rounding
        radiusY: root.flare
        direction: PathArc.Clockwise
    }

    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height + root.flare
    }

    Behavior on fillColor {
        CAnim {}
    }
}