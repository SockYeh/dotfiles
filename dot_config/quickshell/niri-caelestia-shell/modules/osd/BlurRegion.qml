import qs.config
import QtQuick
import Quickshell
import Quickshell.Wayland

// Blur region for the OSD. The fill (Background.qml) is a plain rounded
// rectangle with no flares, so a simple radius is all it takes — the same
// shape the launcher, notifications and quick toggles use.
Region {
    id: root

    required property Item osd
    required property Item bar

    readonly property int rounding: Config.border.rounding
    readonly property bool open: root.osd.width > 0

    // The OSD wrapper hugs the right edge below the bar, and only its width
    // animates, so the region follows it exactly and collapses with it.
    x: Math.round(root.osd.x + Config.border.thickness)
    y: Math.round(root.osd.y + root.bar.implicitHeight)
    width: Math.max(0, Math.round(root.osd.width))
    height: root.open ? Math.max(0, Math.round(root.osd.height)) : 0

    radius: root.rounding
}