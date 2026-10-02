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

    // The top corners flare outward into the wrapper's margin, so the panel
    // reads as growing out of the bar instead of hanging below it.
    readonly property real flare: rounding

    strokeWidth: -1
    // Frosted base: mostly see-through so the compositor's blur behind the
    // panel reads through instead of being hidden under an opaque plate.
    // The drawers group applies transparency.base on top of this, and the
    // cards that hold text are drawn as opaque boxes over it.
    fillColor: Qt.alpha(Colours.palette.m3surface, 0.4)

    // Start at the outer edge of the top-left flare, which lines up with the
    // wrapper's left border because startX is offset by one rounding.
    PathMove {
        x: root.leftEdge - root.flare
        y: 0
    }

    // Outer edge of the left flare.
    PathLine {
        relativeX: 0
        relativeY: root.roundingY
    }

    // Convex shoulder: curves back in to the body's left edge.
    PathArc {
        relativeX: root.flare
        relativeY: -root.roundingY
        radiusX: root.flare
        radiusY: Math.min(root.roundingY, root.wrapper.height)
        direction: PathArc.Clockwise
    }

    // Down the body's left side to the bottom fillet.
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY
    }

    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: Math.min(root.rounding, root.wrapper.height)
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
        radiusY: Math.min(root.rounding, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }

    // Up the body's right side, then mirror the flare for the top-right corner.
    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY)
    }

    PathArc {
        relativeX: root.flare
        relativeY: root.roundingY
        radiusX: root.flare
        radiusY: Math.min(root.roundingY, root.wrapper.height)
        direction: PathArc.Counterclockwise
    }

    // Back up the outer edge of the right flare; closing the path draws the
    // top edge.
    PathLine {
        relativeX: 0
        relativeY: -root.roundingY
    }

    Behavior on fillColor {
        CAnim {}
    }
}
