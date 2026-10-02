import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.border.rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    // Body edges, relative to the startX/startY the parent sets. startX is
    // offset by one rounding, so the painted body lines up with the wrapper.
    readonly property real leftEdge: startX + rounding
    readonly property real rightEdge: leftEdge + wrapper.width

    // The top edge runs wider than the body, out to the wrapper's margin, so
    // the panel reads as growing out of the bar instead of hanging below it.
    // The margin is exactly one rounding wide, so the flare can't exceed it.
    readonly property real flare: rounding

    strokeWidth: -1
    // Frosted base: mostly see-through so the compositor's blur behind the
    // panel reads through instead of being hidden under an opaque plate.
    // The drawers group applies transparency.base on top of this, and the
    // cards that hold text are drawn as opaque boxes over it.
    fillColor: Qt.alpha(Colours.palette.m3surface, 0.4)

    // Start at the outer tip of the top-left flare.
    PathMove {
        x: root.leftEdge - root.flare
        y: 0
    }

    // Left shoulder: a concave cove. It leaves the tip sagging down-and-in,
    // so the corner is scooped rather than bulged — the same inward curve the
    // bottom corners use, just set out on the flare. Clockwise puts the arc's
    // centre outside the fill, which is what makes it a cove; the other sweep
    // balloons the shoulder out past the flare width.
    PathArc {
        relativeX: root.flare
        relativeY: root.roundingY
        radiusX: root.flare
        radiusY: root.roundingY
        direction: PathArc.Clockwise
    }

    // Down the body's left side to the bottom fillet.
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }

    // Bottom corners keep the original inward fillets.
    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Counterclockwise
    }

    PathLine {
        relativeX: root.wrapper.width - root.rounding * 2
        relativeY: 0
    }

    PathArc {
        relativeX: root.rounding
        relativeY: -root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Counterclockwise
    }

    // Up the body's right side to the mirrored shoulder.
    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY * 2)
    }

    PathArc {
        relativeX: root.flare
        relativeY: -root.roundingY
        radiusX: root.flare
        radiusY: root.roundingY
        direction: PathArc.Clockwise
    }

    // Closing the path draws the top edge, spanning tip to tip.
    Behavior on fillColor {
        CAnim {}
    }
}
