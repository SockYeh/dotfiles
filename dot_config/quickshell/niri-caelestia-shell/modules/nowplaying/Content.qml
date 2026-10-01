pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property int artSize: Config.notifs.sizes.image
    readonly property int textWidth: 220

    implicitWidth: layout.implicitWidth + Appearance.padding.lg * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.md * 2

    StyledRect {
        id: card

        anchors.fill: parent

        radius: Appearance.rounding.normal
        color: Colours.palette.m3surface
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.3)

        Elevation {
            anchors.fill: card

            radius: card.radius
            opacity: card.opacity
            level: 3
        }

        RowLayout {
            id: layout

            anchors.centerIn: parent
            spacing: Appearance.spacing.lg

            StyledClippingRect {
                implicitWidth: root.artSize
                implicitHeight: root.artSize
                radius: Infinity
                color: Colours.tPalette.m3surfaceContainerHigh

                MaterialIcon {
                    anchors.centerIn: parent

                    grade: 200
                    text: "music_note"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: parent.width * 0.4 || 1
                }

                RemoteImage {
                    anchors.fill: parent

                    remoteSource: Players.active?.trackArtUrl ?? ""
                }
            }

            ColumnLayout {
                spacing: 0

                Layout.preferredWidth: root.textWidth

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    text: (Players.active?.trackTitle ?? "") || qsTr("Unknown title")
                    color: Colours.palette.m3onSurface
                    font.pointSize: Appearance.font.size.bodyMedium
                }

                StyledText {
                    Layout.fillWidth: true

                    animate: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    text: (Players.active?.trackArtist ?? "") || qsTr("Unknown artist")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.labelLarge
                }
            }
        }
    }
}
