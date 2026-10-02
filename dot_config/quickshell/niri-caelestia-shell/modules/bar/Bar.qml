pragma ComponentBehavior: Bound

import qs.services
import qs.config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
    readonly property int hPadding: Appearance.padding.xl

    // The clock is rendered outside the row flow, pinned to the exact centre of the bar
    readonly property bool showClock: {
        const entries = Config.bar.entries;
        for (let i = 0; i < entries.length; i++) {
            if (entries[i].id === "clock" && entries[i].enabled)
                return true;
        }
        return false;
    }

    // Handle Workspace Popouts for Niri

    Connections {
        target: root.popouts
        function onHasCurrentChanged() {
            if (!root.popouts.hasCurrent && root.popouts.currentName === "wsWindow") {
                Niri.wsContextAnchor = null;
            }
        }
    }

    // Handle Popouts Hover

    function checkPopout(x: real): void {
        if (Niri.wsContextType === "workspaces") {
            // Workspace context menu
            const anchor = Niri.wsContextAnchor;
            if (!anchor) {
                popouts.hasCurrent = false;
                return;
            }
            popouts.currentCenter = Qt.binding(() => Math.round(anchor.mapToItem(root, anchor.width / 2, anchor.height).x));
            return;
        }

        const ch = row.childAt(x, height / 2) as WrappedLoader;
        if (!ch?.item) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.id;
        const left = ch.x;
        const item = ch.item;
        const itemWidth = item.implicitWidth;
        const sticky = popouts.currentName.startsWith("traymenu") || popouts.currentName === "wirelesspassword";

        if (id === "statusIcons") {
            const items = item.items;
            const icon = items.childAt(mapToItem(items, x, 0).x, items.height / 2);
            if (icon) {
                // The mic icon shares the audio popout; brightness has its own
                popouts.currentName = icon.name === "microphone" ? "audio" : icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, icon.implicitWidth / 2, 0).x);
                popouts.hasCurrent = true;
            } else if (!sticky) {
                popouts.hasCurrent = false;
            }
        } else if (id === "tray") {
            // The tray is a single button that opens the dropdown popout
            if (Config.bar.popouts.tray) {
                popouts.currentName = "trayDropdown";
                popouts.currentCenter = Qt.binding(() => item.mapToItem(root, item.implicitWidth / 2, 0).x);
                popouts.hasCurrent = true;
            } else if (!sticky) {
                popouts.hasCurrent = false;
            }
        } else if (!sticky) {
            popouts.hasCurrent = false;
        }
    }

    function handleWheel(x: real, angleDelta: point): void {
        const ch = row.childAt(x, height / 2) as WrappedLoader;
        if (!ch?.item)
            return;

        if (ch.id === "workspaces" && Config.bar.scrollActions.workspaces) {
            Niri.switchToWorkspaceUpDown(angleDelta.y > 0 ? "up" : "down");
        } else if (ch.id === "statusIcons") {
            // Scrolling only adjusts volume/brightness when over their icons
            const items = ch.item.items;
            const icon = items.childAt(mapToItem(items, x, 0).x, items.height / 2);
            if (icon?.name === "audio" && Config.bar.scrollActions.volume) {
                if (angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (angleDelta.y < 0)
                    Audio.decrementVolume();
            } else if (icon?.name === "brightness" && Config.bar.scrollActions.brightness) {
                const monitor = ch.item.monitor;
                if (monitor) {
                    if (angleDelta.y > 0)
                        monitor.setBrightness(monitor.brightness + Config.services.brightnessIncrement);
                    else if (angleDelta.y < 0)
                        monitor.setBrightness(monitor.brightness - Config.services.brightnessIncrement);
                }
            }
        }
    }

    // True when the pointer is over the centred cluster (clock + now-playing)
    // — hovering anywhere in that group opens the dashboard
    function clockHovered(mx: real, my: real): bool {
        if (clockCluster.width <= 0 || clockCluster.height <= 0)
            return false;
        const p = clockCluster.mapToItem(null, 0, 0);
        return mx >= p.x && mx <= p.x + clockCluster.width && my >= p.y && my <= p.y + clockCluster.height;
    }

    RowLayout {
        id: row

        anchors.fill: parent
        spacing: Appearance.spacing.lg

        Repeater {
            id: repeater

            model: {
                // The clock is rendered separately, pinned to the bar's centre
                const out = [];
                const entries = Config.bar.entries;
                for (let i = 0; i < entries.length; i++) {
                    if (entries[i].id !== "clock")
                        out.push(entries[i]);
                }
                return out;
            }

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "spacer"
                    delegate: WrappedLoader {
                        Layout.fillWidth: enabled
                    }
                }
                DelegateChoice {
                    roleValue: "divider"
                    delegate: WrappedLoader {
                        sourceComponent: Rectangle {
                            implicitWidth: 1
                            implicitHeight: Appearance.padding.md
                            color: Colours.palette.m3outlineVariant
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "logo"
                    delegate: WrappedLoader {
                        sourceComponent: OsIcon {
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        Niri.wsContextType = "workspaces";
                                        root.popouts.currentName = "wsWindow";
                                        root.popouts.hasCurrent = true;
                                    }
                                }
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "workspaces"
                    delegate: WrappedLoader {
                        sourceComponent: Workspaces {

                            property var anchorItem: Niri.wsContextAnchor && Niri.wsContextType !== "none" ? Niri.wsContextAnchor : null

                            onRequestWindowPopout: {
                                if (anchorItem && Config.bar.workspaces.windowRighClickContext) {
                                    root.popouts.currentName = "wsWindow";
                                    root.popouts.currentCenter = Qt.binding(() => Math.round(anchorItem.mapToItem(null, anchorItem.width / 2, anchorItem.height).x));
                                    root.popouts.hasCurrent = true;
                                }
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "activeWindow"
                    delegate: WrappedLoader {
                        sourceComponent: ActiveWindow {
                            bar: root
                            monitor: Brightness.getMonitorForScreen(root.screen)
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "tray"
                    delegate: WrappedLoader {
                        sourceComponent: Tray {}
                    }
                }
                DelegateChoice {
                    roleValue: "statusIcons"
                    delegate: WrappedLoader {
                        sourceComponent: StatusIcons {
                            screen: root.screen
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "power"
                    delegate: WrappedLoader {
                        sourceComponent: Power {
                            visibilities: root.visibilities
                        }
                    }
                }
                // DelegateChoice {
                //     roleValue: "idleInhibitor"
                //     delegate: WrappedLoader {
                //         sourceComponent: IdleInhibitor {}
                //     }
                // }
            }
        }
    }

    // Centred clock cluster: time + now-playing as one centred group
    Item {
        id: clockCluster

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: clockLoader.width + (nowPlayingLoader.width > 0 ? Appearance.spacing.lg : 0) + nowPlayingLoader.width
        height: Math.max(nowPlayingLoader.height, clockLoader.height)

        Loader {
            id: clockLoader

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            active: root.showClock
            visible: active
            asynchronous: true

            sourceComponent: Clock {}
        }

        Loader {
            id: nowPlayingLoader

            anchors.left: clockLoader.right
            anchors.leftMargin: nowPlayingLoader.width > 0 ? Appearance.spacing.lg : 0
            anchors.verticalCenter: parent.verticalCenter

            active: root.showClock && Config.bar.clock.showNowPlaying
            visible: active
            asynchronous: true

            sourceComponent: NowPlayingStatus {
                visibilities: root.visibilities
            }
        }
    }

    // Cached first/last enabled items — recomputed once when repeater changes
    property Item firstEnabled: null
    property Item lastEnabled: null

    function updateEnabledCache(): void {
        let first = null;
        let last = null;
        const count = repeater.count;
        for (let i = 0; i < count; i++) {
            const item = repeater.itemAt(i);
            if (item?.enabled) {
                if (!first) first = item;
                last = item;
            }
        }
        firstEnabled = first;
        lastEnabled = last;
    }

    Connections {
        target: repeater
        function onCountChanged() { root.updateEnabledCache(); }
    }

    Component.onCompleted: updateEnabledCache()

    component WrappedLoader: Loader {
        required property string id
        required property int index

        onEnabledChanged: root.updateEnabledCache()

        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        Layout.leftMargin: root.firstEnabled === this ? root.hPadding : 0
        Layout.rightMargin: root.lastEnabled === this ? root.hPadding : 0

        asynchronous: true
        visible: enabled
        active: enabled
    }
}
