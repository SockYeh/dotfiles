import qs.components
import qs.services
import qs.config
import "dash"
import Quickshell
import QtQuick.Layouts

GridLayout {
    id: root

    required property PersistentProperties visibilities
    required property PersistentProperties state

    rowSpacing: Appearance.spacing.lg
    columnSpacing: Appearance.spacing.lg

    // Declared before first use: inline components resolve in document order,
    // so a Rect used above this point fails with "Rect is not a type".
    component Rect: StyledRect {
        radius: Appearance.rounding.small
        // Opaque box: everything that holds text sits on a solid plate so it
        // stays readable over the frosted panel base.
        color: Colours.tPalette.m3surfaceContainer
    }

    Rect {
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.preferredWidth: user.implicitWidth
        Layout.preferredHeight: user.implicitHeight

        User {
            id: user

            visibilities: root.visibilities
            state: root.state
        }
    }

    Rect {
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Config.dashboard.sizes.weatherWidth
        Layout.fillHeight: true

        Weather {}
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: date.implicitWidth
        Layout.fillHeight: true

        Date {
            id: date
        }
    }

    // Music player spans the rest of the bottom row, which is what makes it
    // landscape rather than a tall column on the right.
    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 4
        Layout.fillWidth: true
        // The row takes its height from the card: a fillHeight cell with no
        // preferred size collapses to nothing.
        Layout.preferredHeight: media.implicitHeight

        Media {
            id: media
            anchors.fill: parent
            anchors.margins: Appearance.padding.md
        }
    }
}
