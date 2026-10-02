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
        spacing: Appearance.spacing.md

        // Readout — scrolling over it nudges the brightness (replaces the slider)
        CustomMouseArea {
            Layout.fillWidth: true
            implicitWidth: header.implicitWidth
            implicitHeight: header.implicitHeight

            onWheel: event => {
                root.apply(root.level + (event.angleDelta.y > 0 ? Config.services.brightnessIncrement : -Config.services.brightnessIncrement));
            }

            RowLayout {
                id: header

                spacing: Appearance.spacing.sm

                StyledText {
                    text: qsTr("Brightness")
                    font.weight: 500
                }

                StyledText {
                    text: `${Math.round(root.level * 100)}%`
                    color: Colours.palette.m3primary
                    font.family: Appearance.font.family.mono
                }
            }
        }

        RowLayout {
            spacing: Appearance.spacing.sm

            // Display on/off — coloured while the display is lit, muted once it
            // has been turned off (matches the Screen timeout toggle's pattern)
            StyledRect {
                readonly property bool active: root.level > 0.001

                implicitWidth: displayBtn.implicitWidth + Appearance.padding.sm * 2
                implicitHeight: displayBtn.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.small
                color: active ? Colours.palette.m3primaryContainer : displayLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

                StateLayer {
                    id: displayLayer
                    color: parent.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    radius: parent.radius

                    function onClicked(): void {
                        if (root.level > 0.001)
                            root.apply(0);
                        else
                            root.apply(root.monitor?.restoreBrightness ?? 0.5);
                    }
                }

                RowLayout {
                    id: displayBtn

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.xs

                    MaterialIcon {
                        Layout.leftMargin: Appearance.padding.xs
                        text: displayLayer.parent.active ? "visibility" : "visibility_off"
                        color: displayLayer.color
                        font.pointSize: Appearance.font.size.bodySmall
                    }

                    StyledText {
                        Layout.rightMargin: Appearance.padding.xs
                        text: displayLayer.parent.active ? qsTr("Display on") : qsTr("Display off")
                        color: displayLayer.color
                        font.pointSize: Appearance.font.size.bodySmall
                    }
                }
            }

            // Screen timeout on/off
            StyledRect {
                readonly property bool active: ScreenTimeout.enabled

                implicitWidth: timeoutBtn.implicitWidth + Appearance.padding.sm * 2
                implicitHeight: timeoutBtn.implicitHeight + Appearance.padding.xs

                radius: Appearance.rounding.small
                color: active ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

                StateLayer {
                    id: timeoutLayer
                    color: parent.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    radius: parent.radius

                    function onClicked(): void {
                        ScreenTimeout.toggle();
                    }
                }

                RowLayout {
                    id: timeoutBtn

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.xs

                    MaterialIcon {
                        Layout.leftMargin: Appearance.padding.xs
                        text: timeoutLayer.color === Colours.palette.m3onPrimaryContainer ? "timer" : "hourglass_bottom"
                        color: timeoutLayer.color
                        font.pointSize: Appearance.font.size.bodySmall
                    }

                    StyledText {
                        Layout.rightMargin: Appearance.padding.xs
                        text: qsTr("Screen timeout")
                        color: timeoutLayer.color
                        font.pointSize: Appearance.font.size.bodySmall
                    }
                }
            }

            // Timeout length, in seconds
            StyledInputField {
                Layout.preferredWidth: 58

                text: `${ScreenTimeout.timeoutSeconds}`
                placeholderText: qsTr("sec")
                horizontalAlignment: TextInput.AlignHCenter
                validator: IntValidator {
                    bottom: 0
                    top: 7200
                }

                function commit(val: real): void {
                    if (isNaN(val))
                        return;
                    Config.services.screenTimeoutSeconds = Math.max(0, Math.round(val));
                    Config.markDirty("services");
                }

                onEditingFinished: commit(parseInt(text))
            }

            StyledText {
                text: qsTr("sec")
                color: Colours.palette.m3outline
                font.pointSize: Appearance.font.size.bodySmall
            }
        }
    }
}
