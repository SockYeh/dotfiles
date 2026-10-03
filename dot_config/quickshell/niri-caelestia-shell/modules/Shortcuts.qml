import qs.components.misc
import qs.modules.controlcenter
import qs.services
import qs.config
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property bool launcherInterrupted

    Connections {
        target: Config

        function onConfigSaved(): void {
            if (Config.utilities.toasts.configLoaded)
                Toaster.toast(qsTr("Config saved"), qsTr("Configuration saved successfully"), "rule_settings");
        }

        function onConfigLoaded(elapsed: int): void {
            if (Config.utilities.toasts.configLoaded)
                Toaster.toast(qsTr("Config loaded"), qsTr("Config loaded in %1ms").arg(elapsed), "rule_settings");
        }

        function onConfigError(message: string): void {
            Toaster.toast(qsTr("Config error"), message, "settings_alert", Toast.Error);
        }
    }

    IpcHandler {
        target: "drawers"

        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
                const visibilities = Visibilities.getForActive();
                visibilities[drawer] = !visibilities[drawer];
            } else {
                console.warn(`[IPC] Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const visibilities = Visibilities.getForActive();
            return Object.keys(visibilities).filter(k => typeof visibilities[k] === "boolean").join("\n");
        }
    }

    IpcHandler {
        target: "controlCenter"

        function open(): void {
            WindowFactory.create();
        }
    }

    IpcHandler {
        target: "vpn"

        function toggle(): void {
            VPN.toggle();
        }

        function connect(): void {
            VPN.connect();
        }

        function disconnect(): void {
            VPN.disconnect();
        }

        function status(): string {
            return `connected=${VPN.connected} connecting=${VPN.connecting} enabled=${VPN.enabled} provider=${VPN.providerName} exitNodes=${VPN.supportsExitNodes} nodes=${VPN.exitNodes.length} current=${VPN.currentExitNode}`;
        }
    }

    IpcHandler {
        target: "toaster"

        function info(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Info);
        }

        function success(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Success);
        }

        function warn(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Warning);
        }

        function error(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Error);
        }
    }

    IpcHandler {
        target: "clipboard"

        function open(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.clipboardRequested = true
            visibilities.launcher = true
        }

        function close(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.launcher = false
        }

        function toggle(): void {
            const visibilities = Visibilities.getForActive()
            if (visibilities.launcher) {
                visibilities.launcher = false
            } else {
                visibilities.clipboardRequested = true
                visibilities.launcher = true
            }
        }

        function clear(): void {
            Quickshell.execDetached(["cliphist", "wipe"]);
            Quickshell.execDetached(["wl-copy", "--clear"]);
            Toaster.toast(qsTr("Clipboard cleared"), qsTr("The clipboard history has been wiped."), "content_paste_off");
        }
    }

    }

// keybind-ipc-wallpaper 1790887284
