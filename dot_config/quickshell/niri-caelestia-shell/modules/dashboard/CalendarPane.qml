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

        anchors.centerIn: parent
        state: root.state
    }
}