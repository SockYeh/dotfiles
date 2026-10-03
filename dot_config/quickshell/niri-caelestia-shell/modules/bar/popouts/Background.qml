import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

// Same silhouette as the dashboard (modules/dashboard/Background.qml): a flat
// top edge that flares out toward the bar with concave coves at the
// shoulders, straight sides, and concave fillets along the bottom. The body
// sits one flare inside the wrapper so the tips stay within the popout's own
// footprint instead of hanging off the screen edge the way a centred panel
// can afford to.
ShapePath {
    id: root

    required property Wrapper wrapper
    required property bool invertBottomRounding

    readonly property real rounding: wrapper.isDetached ? Appearance.rounding.normal : Config.border.rounding
    readonly property real flare: rounding
    readonly property bool flatten: wrapper.height < rounding * 2
    readonly property real roundingY: flatten ? wrapper.height / 2 : rounding

    // Body edges, relative to the startX the parent sets. startX is the
    // wrapper's left edge, so the body is inset by one flare on each side and
    // the flares run out to the wrapper's own margins.
    readonly property real leftEdge: startX + flare
    readonly property real bodyWidth: Math.max(0, wrapper.width - flare * 2)
    // Narrow popouts can't fit two full fillets across the body.
    readonly property real fillet: Math.min(rounding, bodyWidth / 2)

    property real ibr: invertBottomRounding ? -1 : 1

    strokeWidth: -1
    // Translucent frosted fill so the popout matches the bar pills instead of
    // reading as an opaque black box.
    fillColor: Colours.frost

    PathMove {
        x: root.leftEdge - root.flare
        y: 0
    }

    // Left shoulder: a concave cove, same sweep as the dashboard's.
    PathArc {
        relativeX: root.flare
        relativeY: root.roundingY
        radiusX: root.flare
        radiusY: root.roundingY
        direction: PathArc.Clockwise
    }

    PathLine {
        relativeX: 0
        relativeY: root.wrapper.height - root.roundingY * 2
    }

    // Bottom-right fillet. Concave normally; when the popout reaches the
    // bottom of the screen it bulges out instead, so the two meet flush.
    PathArc {
        relativeX: -root.fillet * root.ibr
        relativeY: root.roundingY
        radiusX: root.fillet
        radiusY: root.roundingY
        direction: PathArc.Clockwise
    }

    PathLine {
        relativeX: -(root.bodyWidth - root.fillet * 2 * root.ibr)
        relativeY: 0
    }

    PathArc {
        relativeX: -root.fillet * root.ibr
        relativeY: -root.roundingY
        radiusX: root.fillet
        radiusY: root.roundingY
        direction: root.ibr < 0 ? PathArc.Counterclockwise : PathArc.Clockwise
    }

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

    Behavior on fillColor {
        CAnim {}
    }

    Behavior on ibr {
        Anim {}
    }
}