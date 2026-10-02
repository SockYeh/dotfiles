pragma Singleton
pragma ComponentBehavior: Bound

import qs.config
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick

// Blanks the display after a period without input, and restores the previous
// brightness the moment input comes back. Uses the compositor's idle protocol
// (ext-idle-notify), so no external idle daemon is needed.
Singleton {
    id: root

    // Idle seconds before the display is blanked; 0 turns the timeout off
    readonly property int timeoutSeconds: Math.max(0, Config.services.screenTimeoutSeconds)
    readonly property bool active: props.enabled && timeoutSeconds > 0

    // Set only when *we* blanked the display, so a manual "Display off"
    // from the brightness popout is never overridden on wake.
    property bool _blanked: false
    property real _previousBrightness: -1

    readonly property alias enabled: props.enabled

    function toggle(): void {
        props.enabled = !props.enabled;
    }

    function blankNow(): void {
        const monitor = Brightness.getMonitor("active");
        if (!monitor || monitor.brightness <= 0)
            return;
        _previousBrightness = monitor.brightness;
        _blanked = true;
        monitor.setBrightness(0);
    }

    function wake(): void {
        if (!_blanked)
            return;
        const monitor = Brightness.getMonitor("active");
        if (monitor && _previousBrightness > 0)
            monitor.setBrightness(_previousBrightness);
        _blanked = false;
        _previousBrightness = -1;
    }

    PersistentProperties {
        id: props

        property bool enabled: true

        reloadableId: "screenTimeout"
    }

    IdleMonitor {
        id: idle

        enabled: root.active
        timeout: Math.max(1, root.timeoutSeconds)
        respectInhibitors: true

        onIsIdleChanged: {
            if (idle.isIdle) {
                console.log("ScreenTimeout: idle for", root.timeoutSeconds + "s, blanking display");
                root.blankNow();
            } else {
                root.wake();
            }
        }
    }
}
