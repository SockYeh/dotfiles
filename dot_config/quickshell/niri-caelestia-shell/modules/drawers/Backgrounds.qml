import qs.services
import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.session as Session
import qs.modules.launcher as Launcher
import qs.modules.dashboard as Dashboard
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import qs.modules.quicktoggles as QuickToggles
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.topMargin: bar.implicitHeight
    preferredRendererType: Shape.CurveRenderer

    Osd.Background {
        wrapper: root.panels.osd

        // The path starts at the panel's top-left corner, so startX is its left
        // edge. startY leaves one flare of headroom above the body for the tip.
        startX: root.width - root.panels.session.width - wrapper.width
        startY: (root.height - wrapper.height) / 2 - rounding - wrapper.flare
    }

    Notifications.Background {
        wrapper: root.panels.notifications

        startX: root.width
        startY: 0
    }

    Session.Background {
        wrapper: root.panels.session

        startX: root.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Launcher.Background {
        wrapper: root.panels.launcher

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height
    }

    Dashboard.Background {
        wrapper: root.panels.dashboard

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: 0
    }

    BarPopouts.Background {
        wrapper: root.panels.popouts
        invertBottomRounding: wrapper.animY + wrapper.height + 1 >= root.height

        // animX/animY, not x/y: the wrapper slides by translating itself with
        // the difference between the two, so its content sits at animX while
        // the raw x jumps to the final spot immediately. The fill has to track
        // where the content actually is.
        startX: wrapper.animX
        startY: wrapper.animY
    }

    Utilities.Background {
        wrapper: root.panels.utilities

        startX: root.width
        startY: root.height
    }


    QuickToggles.QuickTogglesBackground {
        wrapper: root.panels.quicktoggles

        startX: root.width
        startY: root.height
    }
}
