pragma ComponentBehavior: Bound

import qs.components
import qs.components.misc
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

// Live resource usage: memory, then CPU, then power — the last only when the
// supplies report a draw.
//
// Icons are the Material Symbols stand-ins for the Noctalia set: its CPU glyph
// is a chip with pins, which `memory` is here (there is no plain chip name in
// this font — `cpu` and `settings_cpu` have no ligature and render as their own
// text), and its RAM glyph is a stick, which `storage` is closest to.
StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary

    color: Colours.frost
    radius: Appearance.rounding.full
    clip: true

    implicitWidth: row.implicitWidth + Appearance.padding.md * 2
    implicitHeight: Config.bar.sizes.innerWidth

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.md

        // Keeps the pollers running while the pill exists
        Ref {
            service: SystemUsage
        }

        RowLayout {
            spacing: Appearance.spacing.small

            MaterialIcon {
                animate: false
                text: "storage"
                color: root.colour
            }

            StyledText {
                animate: false
                text: `${Math.round(SystemUsage.memPerc * 100)}%`
                color: root.colour
                font.family: Appearance.font.family.mono
            }
        }

        RowLayout {
            spacing: Appearance.spacing.small

            MaterialIcon {
                animate: false
                text: "memory"
                color: root.colour
            }

            StyledText {
                animate: false
                text: `${Math.round(SystemUsage.cpuPerc * 100)}%`
                color: root.colour
                font.family: Appearance.font.family.mono
            }
        }

        RowLayout {
            spacing: Appearance.spacing.small
            visible: SystemUsage.watts > 0

            MaterialIcon {
                animate: false
                text: "bolt"
                color: root.colour
            }

            StyledText {
                animate: false
                text: `${SystemUsage.watts.toFixed(1)} W`
                color: root.colour
                font.family: Appearance.font.family.mono
            }
        }
    }
}