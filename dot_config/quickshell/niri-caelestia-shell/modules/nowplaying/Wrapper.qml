pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick

// Middle-top "now playing" popup. Shown briefly whenever the active player
// switches track; hovering keeps it up, clicking dismisses it.
Item {
    id: root

    required property PersistentProperties visibilities

    /** Whether the popup is allowed to show at all (shell.json toggle). */
    readonly property bool popupEnabled: Config.utilities.toasts.nowPlaying
    readonly property bool shown: root.visibilities.nowPlaying && root.popupEnabled
    readonly property int hideDelay: 3000

    // The drawers window punches an input hole everywhere except panel
    // rectangles, so collapse to zero width while hidden to avoid leaving an
    // unclickable strip over the desktop.
    implicitWidth: opacity > 0.01 ? content.implicitWidth : 0
    implicitHeight: content.implicitHeight

    visible: opacity > 0
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9

    Behavior on opacity {
        Anim {
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Behavior on scale {
        Anim {
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Content {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    MouseArea {
        id: hoverArea

        anchors.fill: content
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onEntered: timer.stop()
        onExited: {
            if (root.shown)
                timer.restart();
        }
        onClicked: root.visibilities.nowPlaying = false
    }

    Timer {
        id: timer

        interval: root.hideDelay
        onTriggered: {
            if (hoverArea.containsMouse)
                return;
            root.visibilities.nowPlaying = false;
        }
    }

    Connections {
        target: Players

        function onNowPlayingTokenChanged(): void {
            if (!root.popupEnabled)
                return;
            root.visibilities.nowPlaying = true;
            timer.restart();
        }
    }
}
