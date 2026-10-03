pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: root

    required property Item wrapper

    anchors.centerIn: parent

    // The fill's body sits one flare inside the wrapper (the flare overhangs
    // it), so the content has to start where the body does — otherwise text
    // spills sideways over the cove that's cut out of the corner. The usual
    // padding still applies inside that, so the panel keeps its slack around
    // content that draws wider than its implicit width.
    readonly property int inset: (wrapper.isDetached ? Appearance.rounding.normal : Config.border.rounding) + Appearance.padding.xl

    implicitWidth: (content.children.find(c => c.shouldBeActive)?.implicitWidth ?? 0) + root.inset * 2
    implicitHeight: (content.children.find(c => c.shouldBeActive)?.implicitHeight ?? 0) + Appearance.padding.xl * 2

    // Persistent storage for the password network - survives network popout deactivation
    property var pendingPasswordNetwork: null

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Appearance.padding.xl
        anchors.leftMargin: root.inset
        anchors.rightMargin: root.inset

        Popout {
            name: "wsWindow"
            sourceComponent:
            // Bind y to currentCenter for dynamic following
            WsContextPopout {}
        }

        Popout {
            id: networkPopout

            name: "network"
            sourceComponent: Network {
                wrapper: root.wrapper
                onPasswordNetworkChanged: {
                    // Capture network to persistent storage whenever it changes
                    if (passwordNetwork) {
                        root.pendingPasswordNetwork = passwordNetwork;
                    }
                }
            }
        }

        Popout {
            id: passwordPopout

            name: "wirelesspassword"
            sourceComponent: WirelessPassword {
                wrapper: root.wrapper
                // Use the persistent copy, not a binding to the network popout's item
                network: root.pendingPasswordNetwork
            }
        }

        Popout {
            name: "bluetooth"
            sourceComponent: Bluetooth {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "battery"
            source: "Battery.qml"
        }

        Popout {
            name: "audio"
            sourceComponent: Audio {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "brightness"
            sourceComponent: BrightnessPopout {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "kblayout"
            source: "KbLayout.qml"
        }

        Popout {
            name: "lockstatus"
            source: "LockStatus.qml"
        }

        Popout {
            name: "trayDropdown"
            sourceComponent: TrayDropdown {
                popouts: root.wrapper
            }
        }

        Repeater {
            model: ScriptModel {
                values: [...SystemTray.items.values]
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData
                required property int index

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    target: root.wrapper

                    function onHasCurrentChanged(): void {
                        if (root.wrapper.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.wrapper
                        trayItem: trayMenu.modelData.menu
                    }
                }
            }
        }
    }

    // Every popout is wrapped in a card, the same translucent rounded panel the
    // dashboard draws behind its own content: the popout itself carries no
    // tint, so without this the rows are read straight off the blurred
    // backdrop.
    component Popout: Item {
        id: popout

        required property string name
        property bool shouldBeActive: root.wrapper.currentName === name

        property url source
        property Component sourceComponent

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        // No fade or scale, matching the dashboard: only the wrapper animates,
        // so the content is always the same size as the panel around it.
        visible: popout.shouldBeActive

        implicitWidth: loader.implicitWidth + Appearance.padding.md * 2
        implicitHeight: loader.implicitHeight + Appearance.padding.md * 2

        StyledRect {
            anchors.fill: parent

            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
        }

        Loader {
            id: loader

            anchors.fill: parent
            anchors.margins: Appearance.padding.md

            asynchronous: true
            active: popout.shouldBeActive

            source: popout.source
            sourceComponent: popout.sourceComponent
        }
    }
}
