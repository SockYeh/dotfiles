import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

// Centred panel along the bottom of the screen. Same motif as the dashboard
// (modules/dashboard/Background.qml), mirrored: the bottom edge — the one
// lying along the screen — flares out past the body at both corners, with a
// concave cove at each shoulder. The top corners keep plain fillets.
ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.border.rounding
    readonly property real flare: rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    // startX already sits one flare left of the body (see Backgrounds.qml), so
    // the body's left edge is startX + flare, and startY is the panel's bottom.
    readonly property real leftEdge: startX + flare
    readonly property real rightEdge: leftEdge + wrapper.width
    readonly property real bottom: startY
    readonly property real top: startY - wrapper.height

    strokeWidth: -1
    fillColor: Colours.frost

    // Left tip of the flared bottom edge, then up the left side, across the
    // top, down the right side and out to the right tip. The closing segment
    // is the bottom edge itself, spanning tip to tip.
    PathMove {
        x: root.leftEdge - root.flare
        y: root.bottom
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
        relativeX: root.wrapper.width - root.rounding * 2
        relativeY: 0
    }

    PathArc {
        relativeX: root.rounding
        relativeY: root.roundingY
        radiusX: root.rounding
        radiusY: root.roundingY
        direction: PathArc.Clockwise
    }

    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }

    // Concave cove at the bottom-right shoulder.
    PathArc {
        relativeX: root.flare
        relativeY: root.roundingY
        radiusX: root.flare
        radiusY: root.roundingY
        direction: PathArc.Counterclockwise
    }

    Behavior on fillColor {
        CAnim {}
    }
}