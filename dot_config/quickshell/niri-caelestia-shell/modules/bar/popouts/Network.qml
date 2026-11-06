pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Item wrapper

    property string connectingToSsid: ""
    property var passwordNetwork: null
    property bool showPasswordDialog: false

    readonly property var activeNetwork: Nmcli.active ?? null
    readonly property var sortedNetworks: [...Nmcli.networks].sort((a, b) => b.strength - a.strength)
    readonly property var savedNetworks: root.sortedNetworks.filter(n => !n.active && Nmcli.hasSavedProfile(n.ssid))
    readonly property var availableNetworks: root.sortedNetworks.filter(n => !n.active && !Nmcli.hasSavedProfile(n.ssid)).slice(0, 8)

    function bandFor(frequency: int): string {
        if (!frequency)
            return "";
        if (frequency < 2500)
            return qsTr("2.4 GHz");
        if (frequency < 5925)
            return qsTr("5 GHz");
        return qsTr("6 GHz");
    }

    spacing: Appearance.spacing.sm
    width: Config.bar.sizes.networkWidth

    StyledText {
        Layout.topMargin: Appearance.padding.md
        Layout.rightMargin: Appearance.padding.xs
        text: qsTr("Wifi %1").arg(Nmcli.wifiEnabled ? "enabled" : "disabled")
        font.weight: 500
    }

    Toggle {
        label: qsTr("Enabled")
        checked: Nmcli.wifiEnabled
        toggle.onToggled: Nmcli.enableWifi(checked)
    }

    // The active connection's address belongs here rather than in one of the
    // lists: it is the one row that stays meaningful when the popout reopens
    // and it carries information the lists do not (IP, band, live signal).
    StyledRect {
        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.xs
        visible: root.activeNetwork !== null
        implicitHeight: currentRow.implicitHeight + Appearance.padding.md * 2

        radius: Appearance.rounding.normal
        color: Colours.tPalette.m3surfaceContainerHigh

        RowLayout {
            id: currentRow

            anchors.fill: parent
            anchors.margins: Appearance.padding.md
            spacing: Appearance.spacing.md

            MaterialIcon {
                text: Icons.getNetworkIcon(root.activeNetwork?.strength ?? 0)
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.titleMedium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.activeNetwork?.ssid ?? ""
                    elide: Text.ElideRight
                    font.weight: 500
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("%1 · %2% · %3").arg(Nmcli.wirelessDeviceDetails?.ipAddress || qsTr("No IP")).arg(root.activeNetwork?.strength ?? 0).arg(root.bandFor(root.activeNetwork?.frequency ?? 0))
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.labelLarge
                    elide: Text.ElideRight
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: currentDisconnectIcon.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, 0.16)

                StateLayer {
                    color: Colours.palette.m3onSurface

                    function onClicked(): void {
                        Nmcli.disconnectFromNetwork();
                    }
                }

                MaterialIcon {
                    id: currentDisconnectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: "link_off"
                    color: Colours.palette.m3primary
                }
            }
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.sm
        Layout.rightMargin: Appearance.padding.xs
        visible: Nmcli.wifiEnabled && root.savedNetworks.length > 0
        text: qsTr("Saved")
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.labelLarge
    }

    Repeater {
        model: root.savedNetworks

        delegate: networkRowComponent
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.sm
        Layout.rightMargin: Appearance.padding.xs
        visible: Nmcli.wifiEnabled && root.availableNetworks.length > 0
        text: qsTr("Available")
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.labelLarge
    }

    Repeater {
        model: root.availableNetworks

        delegate: networkRowComponent
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.sm
        Layout.rightMargin: Appearance.padding.xs
        visible: Nmcli.wifiEnabled && root.activeNetwork === null && Nmcli.networks.length === 0
        text: Nmcli.scanning ? qsTr("Scanning…") : qsTr("No networks found")
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Appearance.font.size.labelLarge
    }

    // Ethernet uses the same row shape as a wireless network so a wired
    // connection is not a second UI to learn. The section is hidden entirely
    // on machines with no wired interface.
    StyledText {
        Layout.topMargin: Appearance.spacing.md
        Layout.rightMargin: Appearance.padding.xs
        visible: Nmcli.ethernetDevices.length > 0
        text: qsTr("Ethernet")
        font.weight: 500
    }

    Repeater {
        model: Nmcli.ethernetDevices

        RowLayout {
            id: ethernetItem

            required property var modelData
            readonly property bool connected: modelData.connected
            readonly property var details: Nmcli.ethernetDeviceDetails

            Layout.fillWidth: true
            Layout.rightMargin: Appearance.padding.xs
            spacing: Appearance.spacing.sm

            MaterialIcon {
                text: "cable"
                color: ethernetItem.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: ethernetItem.modelData.connection || ethernetItem.modelData.interface
                    elide: Text.ElideRight
                    font.weight: ethernetItem.connected ? 500 : 400
                    color: ethernetItem.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const ip = ethernetItem.connected && ethernetItem.details && Nmcli.activeEthernet?.interface === ethernetItem.modelData.interface ? ethernetItem.details.ipAddress : "";
                        const state = ethernetItem.connected ? qsTr("Connected") : qsTr("Disconnected");
                        return ip.length > 0 ? `${ethernetItem.modelData.interface} · ${ip}` : `${ethernetItem.modelData.interface} · ${state}`;
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.labelLarge
                    elide: Text.ElideRight
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: ethernetIcon.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, ethernetItem.connected ? 1 : 0)

                StateLayer {
                    color: ethernetItem.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    function onClicked(): void {
                        if (ethernetItem.connected) {
                            Nmcli.disconnectEthernet(ethernetItem.modelData.connection, () => {});
                        } else {
                            Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.interface || "", () => {});
                        }
                    }
                }

                MaterialIcon {
                    id: ethernetIcon

                    anchors.centerIn: parent
                    animate: true
                    text: ethernetItem.connected ? "link_off" : "link"
                    color: ethernetItem.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                }
            }
        }
    }

    StyledRect {
        Layout.topMargin: Appearance.spacing.sm
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + Appearance.padding.xs * 2

        radius: Appearance.rounding.full
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer
            disabled: Nmcli.scanning || !Nmcli.wifiEnabled

            function onClicked(): void {
                Nmcli.rescanWifi();
            }
        }

        RowLayout {
            id: rescanBtn

            anchors.centerIn: parent
            spacing: Appearance.spacing.sm
            opacity: Nmcli.scanning ? 0 : 1

            MaterialIcon {
                id: scanIcon

                animate: true
                text: "wifi_find"
                color: Colours.palette.m3onPrimaryContainer
            }

            StyledText {
                text: qsTr("Rescan networks")
                color: Colours.palette.m3onPrimaryContainer
            }

            Behavior on opacity {
                Anim {}
            }
        }

        StyledBusyIndicator {
            anchors.centerIn: parent
            strokeWidth: Appearance.padding.xs / 2
            bgColour: "transparent"
            implicitHeight: parent.implicitHeight - Appearance.padding.sm * 2
            running: Nmcli.scanning
        }
    }

    Component {
        id: networkRowComponent

        RowLayout {
            id: networkItem

            required property var modelData
            readonly property bool isConnecting: root.connectingToSsid === networkItem.modelData.ssid
            readonly property bool isSaved: Nmcli.hasSavedProfile(networkItem.modelData.ssid)

            Layout.fillWidth: true
            Layout.rightMargin: Appearance.padding.xs
            spacing: Appearance.spacing.sm

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                visible: networkItem.modelData.isSecure
                text: "lock"
                font.pointSize: Appearance.font.size.labelLarge
            }

            StyledText {
                Layout.leftMargin: Appearance.spacing.sm / 2
                Layout.rightMargin: Appearance.spacing.sm / 2
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font.weight: networkItem.modelData.active ? 500 : 400
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledText {
                text: `${networkItem.modelData.strength}%`
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.labelLarge
            }

            // Saved profiles get a forget action, matching what the control
            // centre can already do; available networks have nothing to forget.
            StyledRect {
                visible: networkItem.isSaved && !networkItem.isConnecting

                implicitWidth: implicitHeight
                implicitHeight: forgetIcon.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.full
                color: "transparent"

                StateLayer {
                    color: Colours.palette.m3error

                    function onClicked(): void {
                        Network.forgetNetwork(networkItem.modelData.ssid);
                    }
                }

                MaterialIcon {
                    id: forgetIcon

                    anchors.centerIn: parent
                    text: "delete"
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: wirelessConnectIcon.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                StyledBusyIndicator {
                    anchors.fill: parent
                    running: networkItem.isConnecting
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: networkItem.isConnecting || !Nmcli.wifiEnabled

                    function onClicked(): void {
                        if (networkItem.modelData.active) {
                            Nmcli.disconnectFromNetwork();
                        } else {
                            root.connectingToSsid = networkItem.modelData.ssid;
                            NetworkConnection.handleConnect(networkItem.modelData, null, network => {
                                // Password is required - show password popout
                                root.passwordNetwork = network;
                                root.showPasswordDialog = true;
                                root.wrapper.currentName = "wirelesspassword";
                            });
                        }
                    }
                }

                MaterialIcon {
                    id: wirelessConnectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: networkItem.isConnecting ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    // The lists only know about access points; the address has to be asked for
    // separately, and the answer changes whenever the active connection does.
    Component.onCompleted: {
        if (Nmcli.wifiEnabled)
            Nmcli.getWirelessDeviceDetails("", () => {});
        if (Nmcli.activeEthernet)
            Nmcli.getEthernetDeviceDetails(Nmcli.activeEthernet.interface, () => {});
    }

    // Reset connecting state when network changes, and keep the address in the
    // current-connection card in step with whatever just became active.
    Connections {
        target: Nmcli

        function onActiveChanged(): void {
            if (Nmcli.active) {
                Nmcli.getWirelessDeviceDetails("", () => {});

                if (root.connectingToSsid === Nmcli.active.ssid) {
                    root.connectingToSsid = "";
                    // Close password dialog if we successfully connected
                    if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                        root.showPasswordDialog = false;
                        root.passwordNetwork = null;
                        if (root.wrapper.currentName === "wirelesspassword") {
                            root.wrapper.currentName = "network";
                        }
                    }
                }
            }
        }

        function onActiveEthernetChanged(): void {
            if (Nmcli.activeEthernet)
                Nmcli.getEthernetDeviceDetails(Nmcli.activeEthernet.interface, () => {});
        }

        function onConnectionFailed(ssid): void {
            if (root.connectingToSsid === ssid) {
                root.connectingToSsid = "";
            }
        }

        function onScanningChanged(): void {
            if (!Nmcli.scanning)
                scanIcon.rotation = 0;
        }
    }

    Connections {
        function onCurrentNameChanged(): void {
            // Clear password network when leaving password dialog
            if (root.wrapper.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }

        target: root.wrapper
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Appearance.padding.xs
        spacing: Appearance.spacing.lg

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
