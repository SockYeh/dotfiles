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

    // Screen corner, left along the straight bottom edge, up the left side,
    // across the top, up the right flare and back down the screen edge to the
    // corner.
    PathMove {
        x: 0
        y: 0
    }

    // Square bottom-left corner: the bottom edge runs straight to the body and
    // turns straight up. This corner carries no flare — the band along the
    // bottom read as a lump either way, scooped when its arc turned inward and
    // bulbous when it turned out.
    PathLine {
        relativeX: -root.wrapper.width
        relativeY: 0
    }

    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY)
    }

    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Clockwise
    }

    // Stop one flare short of the screen edge, then scoop up to the tip of
        // the flare. The tip sits on the screen edge, so the flare runs *up*
        // along it rather than out past it.
        PathLine {
            relativeX: root.wrapper.width - root.flare - root.rounding
            relativeY: 0
        }

        PathArc {
            relativeX: root.flare
            relativeY: -root.flare
            radiusX: root.flare
            radiusY: root.flare
            direction: PathArc.Clockwise
        }

    // Straight back down the screen edge, closing the path at the corner.
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height + root.flare
    }

    Behavior on fillColor {
        CAnim {}
    }
}