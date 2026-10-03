pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.components.controls
import qs.components.images
import qs.services
import qs.utils
import qs.config
import Caelestia.Services
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Overview media card. Landscape: the cover and its progress ring sit on the
// left, the track text fills the middle, and the controls sit on the right.
Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    // The cover keeps the card's height; the card stretches to whatever width
    // the overview's bottom row gives it.
    readonly property int coverSize: Math.max(80, Math.min(Config.dashboard.sizes.mediaCoverArtSize, height - Appearance.padding.xl))

    implicitWidth: Config.dashboard.sizes.mediaWidth
    implicitHeight: Config.dashboard.sizes.mediaCoverArtSize + Appearance.padding.xl

    Behavior on playerProgress {
        Anim {
            duration: Appearance.anim.durations.large
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 2)
            strokeWidth: Config.dashboard.sizes.mediaProgressThickness
            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                radiusY: (cover.height + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                startAngle: -90 - Config.dashboard.sizes.mediaProgressSweep / 2
                sweepAngle: Config.dashboard.sizes.mediaProgressSweep
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3primary
            strokeWidth: Config.dashboard.sizes.mediaProgressThickness
            capStyle: Appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                radiusY: (cover.height + Config.dashboard.sizes.mediaProgressThickness) / 2 + Appearance.spacing.sm
                startAngle: -90 - Config.dashboard.sizes.mediaProgressSweep / 2
                sweepAngle: Config.dashboard.sizes.mediaProgressSweep * root.playerProgress
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        implicitWidth: root.coverSize
        implicitHeight: width
        color: Colours.tPalette.m3surfaceContainerHigh
        radius: Infinity

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: "art_track"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: (parent.width * 0.4) || 1
        }

        RemoteImage {
            id: image

            anchors.fill: parent

            remoteSource: Players.active?.trackArtUrl ?? ""
        }
    }

    ColumnLayout {
        id: textColumn

        anchors.left: cover.right
        anchors.leftMargin: Appearance.spacing.lg
        anchors.right: controls.left
        anchors.rightMargin: Appearance.spacing.lg
        anchors.verticalCenter: cover.verticalCenter

        spacing: Appearance.spacing.xs

        StyledText {
            id: title

            Layout.fillWidth: true

            animate: true
            horizontalAlignment: Text.AlignLeft
            text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.bodyMedium
            elide: Text.ElideRight
        }

        StyledText {
            id: album

            Layout.fillWidth: true

            animate: true
            horizontalAlignment: Text.AlignLeft
            text: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.labelLarge
            elide: Text.ElideRight
        }

        StyledText {
            id: artist

            Layout.fillWidth: true

            animate: true
            horizontalAlignment: Text.AlignLeft
            text: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
            color: Colours.palette.m3secondary
            elide: Text.ElideRight
        }
    }

    Row {
        id: controls

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        spacing: Appearance.spacing.sm

        Control {
            icon: "skip_previous"
            canUse: Players.active?.canGoPrevious ?? false

            function onClicked(): void {
                Players.active?.previous();
            }
        }

        Control {
            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            canUse: Players.active?.canTogglePlaying ?? false

            function onClicked(): void {
                Players.active?.togglePlaying();
            }
        }

        Control {
            icon: "skip_next"
            canUse: Players.active?.canGoNext ?? false

            function onClicked(): void {
                Players.active?.next();
            }
        }
    }

    component Control: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        function onClicked(): void {
        }

        implicitWidth: Math.max(icon.implicitHeight, icon.implicitHeight) + Appearance.padding.xs
        implicitHeight: implicitWidth

        StateLayer {
            disabled: !control.canUse
            radius: Appearance.rounding.full

            function onClicked(): void {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: font.pointSize * 0.05

            animate: true
            text: control.icon
            color: control.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font.pointSize: Appearance.font.size.titleMedium
        }
    }
}