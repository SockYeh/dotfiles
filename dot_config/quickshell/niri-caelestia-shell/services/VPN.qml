pragma Singleton

import Quickshell
import Quickshell.Io
import Caelestia
import QtQuick
import qs.config
import qs.services

Singleton {
    id: root

    property bool connected: false

    readonly property bool connecting: connectProc.running || disconnectProc.running
    readonly property bool enabled: Config.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false)
    readonly property var providerInput: {
        const enabledProvider = Config.utilities.vpn.provider.find(p => typeof p === "object" ? (p.enabled === true) : false);
        return enabledProvider || "wireguard";
    }
    readonly property bool isCustomProvider: typeof providerInput === "object"
    readonly property string providerName: isCustomProvider ? (providerInput.name || "custom") : String(providerInput)
    readonly property string interfaceName: isCustomProvider ? (providerInput.interface || "") : ""
    readonly property var currentConfig: {
        const name = providerName;
        const iface = interfaceName;
        const defaults = getBuiltinDefaults(name, iface);

        if (isCustomProvider) {
            const custom = providerInput;
            return {
                connectCmd: custom.connectCmd || defaults.connectCmd,
                disconnectCmd: custom.disconnectCmd || defaults.disconnectCmd,
                interface: custom.interface || defaults.interface,
                displayName: custom.displayName || defaults.displayName,
                // Optional status probe. Without one the interface is checked
                // for existence, which lies for tailscale: tailscale0 stays
                // around (and stays UP) after `tailscale down`.
                statusCmd: custom.statusCmd || defaults.statusCmd || null,
                statusJsonPath: custom.statusJsonPath || defaults.statusJsonPath || null,
                statusRunningValue: custom.statusRunningValue || defaults.statusRunningValue || null,
                statusMatch: custom.statusMatch || defaults.statusMatch || null
            };
        }

        return defaults;
    }

    // Exit nodes are a tailscale-only feature; other providers have none.
    readonly property bool supportsExitNodes: providerName === "tailscale"
    property var exitNodes: []
    property string currentExitNode: ""
    property bool exitNodeOnline: false

    function loadExitNodes(): void {
        if (!root.supportsExitNodes)
            return;

        exitNodeListProc.exec(["tailscale", "exit-node", "list"]);
    }

    function setExitNode(ip: string): void {
        if (!root.supportsExitNodes)
            return;

        if (!ip) {
            clearExitNode();
            return;
        }

        exitNodeSetProc.exec(["tailscale", "set", `--exit-node=${ip}`]);
    }

    function clearExitNode(): void {
        exitNodeSetProc.exec(["tailscale", "set", "--exit-node="]);
    }

    function getBuiltinDefaults(name, iface) {
        const builtins = {
            "wireguard": {
                connectCmd: ["pkexec", "wg-quick", "up", iface],
                disconnectCmd: ["pkexec", "wg-quick", "down", iface],
                interface: iface,
                displayName: iface
            },
            "warp": {
                connectCmd: ["warp-cli", "connect"],
                disconnectCmd: ["warp-cli", "disconnect"],
                interface: "CloudflareWARP",
                displayName: "Warp",
                statusCmd: ["warp-cli", "--accept-tos", "status"],
                statusMatch: "Status update: Connected"
            },
            "netbird": {
                connectCmd: ["netbird", "up"],
                disconnectCmd: ["netbird", "down"],
                interface: "wt0",
                displayName: "NetBird",
                statusCmd: ["netbird", "status", "--json"],
                statusJsonPath: ["connected"]
            },
            "tailscale": {
                connectCmd: ["tailscale", "up"],
                disconnectCmd: ["tailscale", "down"],
                interface: "tailscale0",
                displayName: "Tailscale",
                statusCmd: ["tailscale", "status", "--json"],
                statusJsonPath: ["BackendState"],
                statusRunningValue: "Running"
            }
        };

        return builtins[name] || {
            connectCmd: [name, "up"],
            disconnectCmd: [name, "down"],
            interface: iface || name,
            displayName: name
        };
    }

    function connect(): void {
        if (!connected && !connecting && root.currentConfig && root.currentConfig.connectCmd) {
            connectProc.exec(root.currentConfig.connectCmd);
        }
    }

    function disconnect(): void {
        if (connected && !connecting && root.currentConfig && root.currentConfig.disconnectCmd) {
            disconnectProc.exec(root.currentConfig.disconnectCmd);
        }
    }

    function toggle(): void {
        if (connected) {
            disconnect();
        } else {
            connect();
        }
    }

    function checkStatus(): void {
        if (root.enabled) {
            statusProc.running = true;
        }
    }

    onConnectedChanged: {
        if (!Config.utilities.toasts.vpnChanged)
            return;

        const displayName = root.currentConfig ? (root.currentConfig.displayName || "VPN") : "VPN";
        if (connected) {
            Toaster.toast(qsTr("VPN connected"), qsTr("Connected to %1").arg(displayName), "vpn_key");
        } else {
            Toaster.toast(qsTr("VPN disconnected"), qsTr("Disconnected from %1").arg(displayName), "vpn_key_off");
        }
    }

    Component.onCompleted: root.enabled && statusCheckTimer.start()

    Process {
        id: nmMonitor

        running: root.enabled
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: statusCheckTimer.restart()
        }
    }

    Process {
        id: statusProc

        // Prefer the provider's own status command; fall back to looking for
        // the interface, which is all wireguard has to offer.
        command: {
            const cfg = root.currentConfig;
            if (!cfg || !cfg.statusCmd)
                return ["ip", "link", "show"];
            return cfg.statusCmd;
        }

        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const cfg = root.currentConfig;
                if (!cfg) {
                    root.connected = false;
                    return;
                }

                if (cfg.statusJsonPath) {
                    try {
                        const data = JSON.parse(text);
                        let value = data;
                        for (const key of cfg.statusJsonPath)
                            value = value?.[key];
                        root.connected = cfg.statusRunningValue ? value === cfg.statusRunningValue : value === true;

                        // tailscale reports the active exit node in the same
                        // document, so no extra probe is needed for it.
                        const status = data.ExitNodeStatus;
                        if (status) {
                            const address = (status.TailscaleIPs ?? []).find(a => !a.includes(":")) ?? "";
                            root.currentExitNode = address.split("/")[0];
                            root.exitNodeOnline = status.Online === true;
                        } else {
                            root.currentExitNode = "";
                            root.exitNodeOnline = false;
                        }
                    } catch (error) {
                        console.warn("VPN status parse error:", error, text.slice(0, 200));
                        root.connected = false;
                    }
                } else if (cfg.statusMatch) {
                    root.connected = text.includes(cfg.statusMatch);
                } else {
                    root.connected = Boolean(cfg.interface) && text.includes(cfg.interface + ":");
                }
            }
        }
    }

    Process {
        id: connectProc

        onExited: statusCheckTimer.start()
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && !error.includes("[#]") && !error.includes("already exists")) {
                    console.warn("VPN connection error:", error);
                } else if (error.includes("already exists")) {
                    root.connected = true;
                }
            }
        }
    }

    Process {
        id: disconnectProc

        onExited: statusCheckTimer.start()
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && !error.includes("[#]")) {
                    console.warn("VPN disconnection error:", error);
                }
            }
        }
    }

    Timer {
        id: statusCheckTimer

        interval: 500
        onTriggered: root.checkStatus()
    }

    Process {
        id: exitNodeListProc

        stdout: StdioCollector {
            onStreamFinished: {
                const nodes = [];
                for (const line of text.split("\n")) {
                    const trimmed = line.trim();
                    // Skip the header and the trailing comments.
                    if (!trimmed || !/\d/.test(trimmed[0]))
                        continue;

                    const parts = trimmed.split(/\s+/);
                    if (parts.length < 2)
                        continue;

                    nodes.push({ ip: parts[0], name: parts[1] });
                }
                root.exitNodes = nodes;
            }
        }
    }

    Process {
        id: exitNodeSetProc

        onExited: {
            statusCheckTimer.start();
            root.loadExitNodes();
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const error = text.trim();
                if (error && !error.includes("[#]")) {
                    console.warn("VPN exit node error:", error);
                }
            }
        }
    }
}
