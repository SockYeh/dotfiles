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

    readonly property int flare: Config.border.rounding
    readonly property int bodyX: Math.round(root.osd.x + Config.border.thickness)
    readonly property int bodyY: Math.round(root.osd.y + root.bar.implicitHeight)
    readonly property int bodyW: Math.max(0, Math.round(root.osd.width))
    readonly property int bodyH: Math.max(0, Math.round(root.osd.height))


    // The OSD wrapper hugs the right edge below the bar, and only its width
    // animates, so the region follows it exactly and collapses with it.
    x: Math.round(root.osd.x + Config.border.thickness)
    y: Math.round(root.osd.y + root.bar.implicitHeight)
    width: Math.max(0, Math.round(root.osd.width))
    height: root.open ? Math.max(0, Math.round(root.osd.height)) : 0
    topLeftRadius: root.rounding
    bottomLeftRadius: root.rounding
    
    // top flare
    Region {
        x: root.bodyX + root.bodyW - root.flare
        y: root.bodyY - root.flare
        width: root.flare
        height: root.open ? root.bodyH + root.flare : 0
    }

    Region {
        intersection: Intersection.Subtract
        x: root.bodyX + root.bodyW - root.flare
        y: root.bodyY - root.flare * 2
        width: root.flare
        height: root.open ? root.flare * 3 : 0

        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Intersect
            x: root.bodyX + root.bodyW - root.flare * 2
            y: root.bodyY - root.flare * 2
            width: root.flare * 2
            height: root.open ? root.flare * 2 : 0
        }
    }

    // bottom flare
    Region {
        x: root.bodyX + root.bodyW - root.flare
        y: root.bodyY + root.bodyH
        width: root.flare
        height: root.open ? root.flare : 0
    }

   
    Region {
        intersection: Intersection.Subtract
        x: root.bodyX + root.bodyW - root.flare
        y: root.bodyY + root.bodyH
        width: root.flare
        height: root.open ? root.flare * 3 : 0

        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Intersect
            x: root.bodyX + root.bodyW - root.flare * 2
            y: root.bodyY + root.bodyH
            width: root.flare * 2
            height: root.open ? root.flare * 2 : 0
        }
    }


}