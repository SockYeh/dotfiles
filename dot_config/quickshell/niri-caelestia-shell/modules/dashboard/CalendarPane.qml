pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import "dash"
import Quickshell
import QtQuick

// Calendar tab: the month grid that used to sit in the overview, now on its
// own page so the overview can stay short.
Item {
    id: root

    required property PersistentProperties state

    implicitWidth: 520
    implicitHeight: calendar.implicitHeight + Appearance.padding.xl * 2

    StyledRect {
        anchors.fill: parent

        radius: Appearance.rounding.small
        // Opaque box, like the overview's cards: the calendar's text has to
        // stay readable over the frosted panel base.
        color: Colours.tPalette.m3surfaceContainer
    }

    Calendar {
        id: calendar

        // Anchored to the edges, not centred: Calendar already anchors its own
        // left and right, and adding horizontalCenter makes it fall back to
        // implicitWidth (0), which collapses every row inside it.
        anchors.top: parent.top
        anchors.topMargin: Appearance.padding.xl

        state: root.state
    }
}