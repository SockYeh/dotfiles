pragma ComponentBehavior: Bound

import qs.components
import qs.components.misc
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

// Live network throughput: download first, then upload.
StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary

    color: Colours.frost
    radius: Appearance.rounding.full
    clip: true

    implicitWidth: row.implicitWidth + Appearance.padding.md * 2
    implicitHeight: Config.bar.sizes.innerWidth

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacing.md

        // Keeps the NetworkUsage poller running while the pill exists
        Ref {
            service: NetworkUsage
        }

        WrappedLoader {
            name: "download"
            active: true

            sourceComponent: RowLayout {
                spacing: Appearance.spacing.small

                MaterialIcon {
                    animate: false
                    text: "download"
                    color: root.colour
                }

                StyledText {
                    animate: false
                    text: {
                        const fmt = NetworkUsage.formatBytes(NetworkUsage.downloadSpeed ?? 0);
                        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                    }
                    color: root.colour
                    font.family: Appearance.font.family.mono
                }
            }
        }

        WrappedLoader {
            name: "upload"
            active: true

            sourceComponent: RowLayout {
                spacing: Appearance.spacing.small

                MaterialIcon {
                    animate: false
                    text: "upload"
                    color: root.colour
                }

                StyledText {
                    animate: false
                    text: {
                        const fmt = NetworkUsage.formatBytes(NetworkUsage.uploadSpeed ?? 0);
                        return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                    }
                    color: root.colour
                    font.family: Appearance.font.family.mono
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
