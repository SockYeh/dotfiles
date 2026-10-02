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

    strokeWidth: -1
    // Frosted base: mostly see-through so the compositor's blur behind the
    // panel reads through instead of being hidden under an opaque plate.
    // The drawers group applies transparency.base on top of this, and the
    // cards that hold text are drawn as opaque boxes over it.
    fillColor: Qt.alpha(Colours.palette.m3surface, 0.4)

    // Square top edge: the panel butts straight up against the bar strip so
    // the two read as one continuous base instead of a flared "connector".
    // Only the bottom corners are rounded.
    PathMove {
        x: root.leftEdge
        y: 0
    }

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

    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.roundingY)
    }

    // Close the top edge explicitly.
    PathLine {
        relativeX: -root.wrapper.width
        relativeY: 0
    }

    Behavior on fillColor {
        CAnim {}
    }
}
