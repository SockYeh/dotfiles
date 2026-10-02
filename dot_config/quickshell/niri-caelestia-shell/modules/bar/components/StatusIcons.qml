pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property ShellScreen screen

    readonly property var monitor: Brightness.getMonitorForScreen(screen)
    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconRow

    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    clip: true
    implicitWidth: iconRow.implicitWidth + Appearance.padding.md * 2
    implicitHeight: Config.bar.sizes.innerWidth

    RowLayout {
        id: iconRow

        anchors.centerIn: parent

        spacing: Appearance.spacing.md / 2

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
                    Layout.leftMargin: Niri.capsLock && Niri.numLock ? iconRow.spacing : 0

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

        // Audio icon + current volume
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
                    animate: true
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

        // Keyboard layout icon
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

        // Network icon
        WrappedLoader {
            name: "network"
            active: Config.bar.status.showNetwork

            sourceComponent: MaterialIcon {
                animate: true
                text: Network.active ? Icons.getNetworkIcon(Network.active.strength ?? 0) : "wifi_off"
                color: root.colour
            }
        }

        // Bluetooth section
        WrappedLoader {
            Layout.preferredWidth: implicitWidth

            name: "bluetooth"
            active: Config.bar.status.showBluetooth

            sourceComponent: RowLayout {
                spacing: Appearance.spacing.md / 2

                // Bluetooth icon (devices are in the popout dropdown)
                MaterialIcon {
                    animate: true
                    text: {
                        if (!Bluetooth.defaultAdapter?.enabled)
                            return "bluetooth_disabled";
                        if (Bluetooth.devices.values.some(d => d.connected))
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.colour
                }
            }

            Behavior on Layout.preferredWidth {
                Anim {}
            }
        }

        // Brightness icon + current level
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
                    animate: true
                    text: `${Math.round((root.monitor?.brightness ?? 0.5) * 100)}%`
                    color: root.colour
                    font.family: Appearance.font.family.mono
                }
            }
        }

        // Battery icon
        WrappedLoader {
            name: "battery"
            active: Config.bar.status.showBattery

            sourceComponent: MaterialIcon {
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
        }
    }

    component WrappedLoader: Loader {
        required property string name

        Layout.alignment: Qt.AlignVCenter
        asynchronous: true
        visible: active
    }
}
