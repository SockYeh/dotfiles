pragma ComponentBehavior: Bound

import qs.components
import qs.components.misc
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Three separate pills:
//   system  — volume, brightness, battery (+ percentage), lock/mic/keyboard
//   network — wifi (+ SSID) and bluetooth
//   speed   — live upload/download throughput
Item {
    id: root

    required property ShellScreen screen

    readonly property var monitor: Brightness.getMonitorForScreen(screen)
    property color colour: Colours.palette.m3secondary
    readonly property alias items: pillRow
    readonly property var pills: [systemPill, networkPill]

    implicitWidth: pillRow.implicitWidth
    implicitHeight: Config.bar.sizes.innerWidth

    // Name of the entry under the given window x, used by Bar.handleWheel to
    // decide whether a scroll means volume or brightness.
    function itemNameAt(x: real): string {
        for (let i = 0; i < root.pills.length; i++) {
            const pill = root.pills[i];
            if (!pill.visible || !pill.contentRow)
                continue;

            const left = pill.mapToItem(null, 0, 0).x;
            if (x < left || x > left + pill.width)
                continue;

            const row = pill.contentRow;
            for (let j = 0; j < row.children.length; j++) {
                const child = row.children[j];
                if (!child.visible || !child.width)
                    continue;
                const cx = child.mapToItem(null, 0, 0).x;
                if (x >= cx && x <= cx + child.width)
                    return child.name ?? "";
            }
            return "";
        }
        return "";
    }

    RowLayout {
        id: pillRow

        anchors.fill: parent
        spacing: Appearance.spacing.md

        // ------------------------------------------------------------------
        // System: volume / brightness / battery / lock state
        // ------------------------------------------------------------------
        StyledRect {
            id: systemPill

            readonly property alias contentRow: systemRow

            color: Qt.alpha(Colours.palette.m3surface, 0.4)
            radius: Appearance.rounding.full
            clip: true

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: systemRow.implicitWidth + Appearance.padding.md * 2
            implicitHeight: Config.bar.sizes.innerWidth
            visible: systemRow.implicitWidth > 0

            RowLayout {
                id: systemRow

                anchors.centerIn: parent
                spacing: Appearance.spacing.md

                // Lock keys status
                WrappedLoader {
                    name: "lockstatus"
                    active: Config.bar.status.showLockStatus

                    sourceComponent: RowLayout {
                        spacing: 0

                        Item {
                            implicitHeight: capslockIcon.implicitHeight
                            implicitWidth: Niri.capsLock ? capslockIcon.implicitWidth : 0

                            MaterialIcon {
                                id: capslockIcon

                                anchors.centerIn: parent

                                scale: Niri.capsLock ? 1 : 0.5
                                opacity: Niri.capsLock ? 1 : 0

                                text: "keyboard_capslock_badge"
                                color: root.colour

                                Behavior on opacity {
                                    Anim {}
                                }

                                Behavior on scale {
                                    Anim {}
                                }
                            }

                            Behavior on implicitWidth {
                                Anim {}
                            }
                        }

                        Item {
                            Layout.leftMargin: Niri.capsLock && Niri.numLock ? systemRow.spacing : 0

                            implicitHeight: numlockIcon.implicitHeight
                            implicitWidth: Niri.numLock ? numlockIcon.implicitWidth : 0

                            MaterialIcon {
                                id: numlockIcon

                                anchors.centerIn: parent

                                scale: Niri.numLock ? 1 : 0.5
                                opacity: Niri.numLock ? 1 : 0

                                text: "looks_one"
                                color: root.colour

                                Behavior on opacity {
                                    Anim {}
                                }

                                Behavior on scale {
                                    Anim {}
                                }
                            }

                            Behavior on implicitWidth {
                                Anim {}
                            }
                        }
                    }
                }

                // Volume icon + level
                WrappedLoader {
                    name: "audio"
                    active: Config.bar.status.showAudio

                    sourceComponent: RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            animate: false
                            text: "volume_up"
                            color: root.colour
                        }

                        StyledText {
                            animate: false
                            text: `${Math.round(Audio.volume * 100)}%`
                            color: root.colour
                            font.family: Appearance.font.family.mono
                        }
                    }
                }

                // Microphone icon
                WrappedLoader {
                    name: "microphone"
                    active: Config.bar.status.showMicrophone

                    sourceComponent: MaterialIcon {
                        animate: true
                        text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                        color: root.colour
                    }
                }

                // Keyboard layout
                WrappedLoader {
                    name: "kblayout"
                    active: Config.bar.status.showKbLayout

                    sourceComponent: StyledText {
                        animate: true
                        text: Niri.kbLayout
                        color: root.colour
                        font.family: Appearance.font.family.mono
                    }
                }

                // Brightness icon + level
                WrappedLoader {
                    name: "brightness"
                    active: Config.bar.status.showBrightness

                    sourceComponent: RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            animate: false
                            text: "brightness_high"
                            color: root.colour
                        }

                        StyledText {
                            animate: false
                            text: `${Math.round((root.monitor?.brightness ?? 0.5) * 100)}%`
                            color: root.colour
                            font.family: Appearance.font.family.mono
                        }
                    }
                }

                // Battery icon + percentage
                WrappedLoader {
                    name: "battery"
                    active: Config.bar.status.showBattery

                    sourceComponent: RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            animate: true
                            text: {
                                if (!UPower.displayDevice.isLaptopBattery) {
                                    if (PowerProfiles.profile === PowerProfile.PowerSaver)
                                        return "energy_savings_leaf";
                                    if (PowerProfiles.profile === PowerProfile.Performance)
                                        return "rocket_launch";
                                    return "balance";
                                }

                                const perc = UPower.displayDevice.percentage;
                                const charging = !UPower.onBattery;
                                if (perc === 1)
                                    return charging ? "battery_charging_full" : "battery_full";
                                let level = Math.floor(perc * 7);
                                if (charging && (level === 4 || level === 1))
                                    level--;
                                return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                            }
                            color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error
                            fill: 1
                        }

                        StyledText {
                            animate: false
                            visible: UPower.displayDevice.isLaptopBattery
                            text: `${Math.round((UPower.displayDevice.percentage ?? 0) * 100)}%`
                            color: root.colour
                            font.family: Appearance.font.family.mono
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------------
        // Network: wifi + SSID and bluetooth
        // ------------------------------------------------------------------
        StyledRect {
            id: networkPill

            readonly property alias contentRow: networkRow

            color: Qt.alpha(Colours.palette.m3surface, 0.4)
            radius: Appearance.rounding.full
            clip: true

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: networkRow.implicitWidth + Appearance.padding.md * 2
            implicitHeight: Config.bar.sizes.innerWidth
            visible: networkRow.implicitWidth > 0

            RowLayout {
                id: networkRow

                anchors.centerIn: parent
                spacing: Appearance.spacing.md

                WrappedLoader {
                    name: "network"
                    active: Config.bar.status.showNetwork

                    sourceComponent: RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            animate: true
                            text: Network.active ? Icons.getNetworkIcon(Network.active.strength ?? 0) : "wifi_off"
                            color: root.colour
                        }

                        StyledText {
                            animate: false
                            visible: (Network.active?.ssid ?? "") !== ""
                            text: Network.active?.ssid ?? ""
                            color: root.colour
                            font.family: Appearance.font.family.mono
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, Appearance.font.size.smaller * 10)
                        }
                    }
                }

                WrappedLoader {
                    Layout.preferredWidth: implicitWidth

                    name: "bluetooth"
                    active: Config.bar.status.showBluetooth

                    sourceComponent: RowLayout {
                        id: bluetoothRow

                        spacing: Appearance.spacing.md / 2

                        readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)

                        MaterialIcon {
                            animate: true
                            text: {
                                if (!Bluetooth.defaultAdapter?.enabled)
                                    return "bluetooth_disabled";
                                if (bluetoothRow.connectedDevices.length > 0)
                                    return "bluetooth_connected";
                                return "bluetooth";
                            }
                            color: root.colour
                        }

                        StyledText {
                            animate: false
                            text: {
                                if (!Bluetooth.defaultAdapter?.enabled)
                                    return qsTr("Not Connected");
                                const count = bluetoothRow.connectedDevices.length;
                                if (count === 0)
                                    return qsTr("Not Connected");
                                return qsTr("Connected (%1)").arg(count);
                            }
                            color: root.colour
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {}
                    }
                }
            }
        }

    }

    component WrappedLoader: Loader {
        required property string name

        Layout.alignment: Qt.AlignVCenter
        asynchronous: true
        visible: active
    }
}
