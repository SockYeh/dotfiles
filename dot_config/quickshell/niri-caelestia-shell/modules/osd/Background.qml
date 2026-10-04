import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

// OSD panel, centred vertically and flush with the right screen edge. Its fill
// is a plain rounded rectangle with one flare: the top-right corner carries a
// tip that runs *up* the screen edge, the same motif the quick toggles use on
// their top-right, and the only rounded corner inside the shape is the
// top-left one.
//
// The path is built from the panel's top-left corner (startX/startY in
// Backgrounds.qml) so the top edge can run out to the flare before turning up.
ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.border.rounding
    readonly property real flare: rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding

    // Where the top edge has to stop for the flare tip to fit, measured from the
    // panel's top-left corner.
    readonly property real topEdge: wrapper.width - root.flare - root.roundingX

    strokeWidth: -1
    // Same frost as the launcher, notifications and quick toggles. The opaque
    // m3surface this used to be would have hidden the blur entirely.
    fillColor: Colours.frost

    // Flare tip first, exactly as the quick toggles' top-right does it: the arc's
    // start is the corner where the screen edge meets the body's top-right, and
    // Clockwise sweeps it out and up to the tip. Putting the fillet first
    // instead rotates the sweep and turns the tip into a bulge.
    PathMove {
        x: root.topEdge
        y: 0
    }

    PathArc {
        relativeX: root.flare
        relativeY: -root.flare
        radiusX: root.flare
        radiusY: root.flare
        direction: PathArc.Clockwise
    }

    // Down the screen edge to the bottom-right corner, along the bottom edge,
    // up the left side, then the top-left fillet closes the path back onto the
    // top edge.
    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height + root.flare
    }

    PathLine {
        relativeX: -root.wrapper.width
        relativeY: 0
    }

    PathLine {
        relativeX: 0
        relativeY: -(root.wrapper.height - root.rounding)
    }

    PathArc {
        relativeX: root.rounding
        relativeY: -root.rounding
        radiusX: Math.min(root.rounding, root.wrapper.width)
        radiusY: root.rounding
        direction: PathArc.Counterclockwise
    }

    PathLine {
        relativeX: -(root.topEdge - root.rounding)
        relativeY: 0
    }

    Behavior on fillColor {
        CAnim {}
    }
}