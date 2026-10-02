pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var wrapper

    // Fall back to the focused monitor if this screen has no entry yet
    readonly property var monitor: Brightness.getMonitorForScreen(wrapper.screen) ?? Brightness.getMonitor("active")
    readonly property real level: monitor?.brightness ?? 0.5

    implicitWidth: layout.implicitWidth + Appearance.padding.md * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.md * 2

    function apply(value: real): void {
        monitor?.setBrightness(value);
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        StyledText {
            Layout.bottomMargin: Appearance.spacing.sm / 2
            text: qsTr("Brightness (%1)").arg(`${Math.round(root.level * 100)}%`)
            font.weight: 500
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Appearance.padding.md * 3

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    root.apply(root.level + Config.services.brightnessIncrement);
                else if (event.angleDelta.y < 0)
                    root.apply(root.level - Config.services.brightnessIncrement);
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight

                from: 0
                to: 1
                value: root.level
                onMoved: root.apply(value)

                Behavior on value {
                    Anim {}
                }
            }
        }

        RowLayout {
            Layout.topMargin: Appearance.spacing.lg
            spacing: Appearance.spacing.sm

            // Display off — drops the backlight to 0
            StyledRect {
                implicitWidth: displayOffBtn.implicitWidth + Appearance.padding.md * 2
                implicitHeight: displayOffBtn.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.normal
                color: Colours.palette.m3primaryContainer

                StateLayer {
                    color: Colours.palette.m3onPrimaryContainer

                    function onClicked(): void {
                        root.apply(0);
                    }
                }

                RowLayout {
                    id: displayOffBtn

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.sm

                    StyledText {
                        Layout.leftMargin: Appearance.padding.sm
                        text: qsTr("Display off")
                        color: Colours.palette.m3onPrimaryContainer
                    }

                    MaterialIcon {
                        Layout.rightMargin: Appearance.padding.sm
                        text: "display_off"
                        color: Colours.palette.m3onPrimaryContainer
                    }
                }
            }

            // Only offered once the backlight is actually down
            StyledRect {
                visible: root.level <= 0.001

                implicitWidth: displayOnBtn.implicitWidth + Appearance.padding.md * 2
                implicitHeight: displayOnBtn.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.normal
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    color: Colours.palette.m3onSurface

                    function onClicked(): void {
                        root.apply(0.5);
                    }
                }

                RowLayout {
                    id: displayOnBtn

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.sm

                    StyledText {
                        Layout.leftMargin: Appearance.padding.sm
                        text: qsTr("Display on")
                        color: Colours.palette.m3onSurface
                    }

                    MaterialIcon {
                        Layout.rightMargin: Appearance.padding.sm
                        text: "display"
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }

        // Screen timeout on/off — 3 min blanking by default
        StyledRect {
            Layout.topMargin: Appearance.spacing.sm

            implicitWidth: timeoutBtn.implicitWidth + Appearance.padding.md * 2
            implicitHeight: timeoutBtn.implicitHeight + Appearance.padding.xs

            radius: Appearance.rounding.normal
            color: ScreenTimeout.enabled ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

            StateLayer {
                color: ScreenTimeout.enabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                function onClicked(): void {
                    ScreenTimeout.toggle();
                }
            }

            RowLayout {
                id: timeoutBtn

                anchors.centerIn: parent
                spacing: Appearance.spacing.sm

                StyledText {
                    Layout.leftMargin: Appearance.padding.sm
                    text: qsTr("Screen timeout")
                    color: ScreenTimeout.enabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }

                StyledText {
                    text: ScreenTimeout.enabled ? `${Math.round(ScreenTimeout.timeoutSeconds / 60)} min` : qsTr("Off")
                    color: ScreenTimeout.enabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                    font.family: Appearance.font.family.mono
                }

                MaterialIcon {
                    Layout.rightMargin: Appearance.padding.sm
                    text: ScreenTimeout.enabled ? "timer" : "timer_off"
                    color: ScreenTimeout.enabled ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
            }
        }
    }
}
