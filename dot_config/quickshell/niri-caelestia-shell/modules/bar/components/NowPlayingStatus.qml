pragma ComponentBehavior: Bound

import qs.components
import qs.components.images
import qs.services
import qs.config
import QtQuick

Item {
    id: root

    required property var visibilities

    readonly property string title: (Players.active?.trackTitle ?? "").trim()
    readonly property bool available: Config.bar.clock.showNowPlaying && root.title !== ""
    // playbackState enum: Stopped=0, Playing=1, Paused=2 (string fallback in
    // case the enum value stringifies to its name).
    readonly property bool playing: {
        const st = Players.active?.playbackState;
        if (st === undefined || st === null)
            return false;
        return st === 1 || String(st) === "1" || String(st) === "Playing";
    }
    readonly property int artSize: 18

    visible: available
    opacity: playing ? 1 : 0.4
    // Explicit sizing (no Row: its implicitWidth collapsed to 0 via the
    // MouseArea fill cycle, and it never positioned its children reliably).
    implicitWidth: textLabel.x + textLabel.width
    implicitHeight: art.height

    StyledClippingRect {
        id: art

        x: 0
        anchors.verticalCenter: parent.verticalCenter

        implicitWidth: root.artSize
        implicitHeight: root.artSize
        radius: Infinity
        color: Colours.tPalette.m3surfaceContainerHigh

        // Shown until the track art loads over it
        MaterialIcon {
            anchors.centerIn: parent

            text: "music_note"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: parent.width * 0.5 || 1
        }

        RemoteImage {
            anchors.fill: parent

            remoteSource: Players.active?.trackArtUrl ?? ""
        }
    }

    StyledText {
        id: textLabel

        x: art.width + Appearance.spacing.small
        anchors.verticalCenter: parent.verticalCenter

        animate: false
        text: {
            const artist = (Players.active?.trackArtist ?? "").trim();
            return artist ? `${root.title} — ${artist}` : root.title;
        }
        color: Colours.palette.m3primary
        font.family: Appearance.font.family.sans
        font.pointSize: Appearance.font.size.smaller
        elide: Text.ElideRight
        width: Math.min(implicitWidth, Appearance.font.size.smaller * 28)
    }

    MouseArea {
        id: input

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: mouse => {
            // Middle click toggles playback, left click opens the dashboard.
            if (mouse.button === Qt.MiddleButton) {
                const player = Players.active;
                if (player?.canTogglePlaying)
                    player.togglePlaying();
            } else {
                root.visibilities.dashboard = true;
            }
        }

    }
}
