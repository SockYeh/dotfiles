import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Shapes

// OSD panel, centred vertically and flush with the right screen edge. The fill
// is a rounded rectangle with a flare on each of the two corners that touch the
// screen edge: the top-right tip runs *up* that edge and the bottom-right tip
// runs *down* it, the same motif the quick toggles use where their panel meets
// the right and bottom edges. The two corners on the open side stay plain
// fillets.
//
// Every coordinate is absolute and derived from the wrapper's own geometry, so
// nothing here depends on the parent passing in a start point. The earlier
// version read startX, which the parent computed from wrapper.width — the path
// and the value it was given were both derived from the same animated width, so
// the origin could land anywhere while the panel was opening.
ShapePath {
    id: root

    required property Wrapper wrapper
    readonly property real rounding: Config.border.rounding
    readonly property real flare: rounding
    readonly property bool flatten: wrapper.width < rounding * 2
    readonly property real roundingX: flatten ? wrapper.width / 2 : rounding

    // The panel's left edge and its top, in the Shape's own coordinates.
    readonly property real left: wrapper.x
    readonly property real top: wrapper.y - root.flare
    readonly property real right: wrapper.x + wrapper.width
    readonly property real bottom: wrapper.y + wrapper.height + root.flare

    // Where the top and bottom edges stop so the flare tips fit.
    readonly property real edgeBreak: root.right - root.flare - root.roundingX

    strokeWidth: -1
    // Same frost as the launcher, notifications and quick toggles. The opaque
    // m3surface this used to be would have hidden the blur entirely.
    fillColor: Colours.frost

    // Top flare tip: a quarter circle from the top edge out onto the screen
    // edge, mirroring the quick toggles' top-right. Clockwise sweeps it up.
    // 
}