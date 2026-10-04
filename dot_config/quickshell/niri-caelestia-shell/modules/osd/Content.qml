pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Brightness.Monitor monitor
    required property var visibilities

    // "all" is the hover case: every enabled slider at once. A key press
    // narrows it to just the one that changed (see osd/Interactions).
    readonly property bool allSliders: visibilities.osdMode === "all"

    function sliderFor(mode: string): bool {
        return root.allSliders || visibilities.osdMode === mode;
    }

    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left

    implicitWidth: layout.implicitWidth + Appearance.padding.xl * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.xl * 2

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Appearance.spacing.lg

        // Speaker volume
        WrappedLoader {
            shouldBeActive: root.sliderFor("volume")

            sourceComponent: CustomMouseArea {
                implicitWidth: Config.osd.sizes.sliderWidth
                implicitHeight: Config.osd.sizes.sliderHeight

                function onWheel(event: WheelEvent) {
                    if (event.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementVolume();
                }

                FilledSlider {
                    anchors.fill: parent

                    icon: Icons.getVolumeIcon(value, Audio.muted)
                    value: Audio.volume
                    onMoved: Audio.setVolume(value)
                }
            }
        }

        // Microphone volume
        WrappedLoader {
            shouldBeActive: Config.osd.enableMicrophone && root.sliderFor("mic")

            sourceComponent: CustomMouseArea {
                implicitWidth: Config.osd.sizes.sliderWidth
                implicitHeight: Config.osd.sizes.sliderHeight

                function onWheel(event: WheelEvent) {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume();
                }

                FilledSlider {
                    anchors.fill: parent

                    icon: Icons.getMicVolumeIcon(value, Audio.sourceMuted)
                    value: Audio.sourceVolume
                    onMoved: Audio.setSourceVolume(value)
                }
            }
        }

        // Brightness
        WrappedLoader {
            shouldBeActive: Config.osd.enableBrightness && root.sliderFor("brightness")

            sourceComponent: CustomMouseArea {
                implicitWidth: Config.osd.sizes.sliderWidth
                implicitHeight: Config.osd.sizes.sliderHeight

                function onWheel(event: WheelEvent) {
                    const monitor = root.monitor;
                    if (!monitor)
                        return;
                    if (event.angleDelta.y > 0)
                        monitor.setBrightness(monitor.brightness + Config.services.brightnessIncrement);
                    else if (event.angleDelta.y < 0)
                        monitor.setBrightness(monitor.brightness - Config.services.brightnessIncrement);
                }

                FilledSlider {
                    anchors.fill: parent

                    icon: `brightness_${(Math.round(value * 6) + 1)}`
                    value: root.monitor?.brightness ?? 0
                    onMoved: root.monitor?.setBrightness(value)
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property bool shouldBeActive

        Layout.preferredHeight: shouldBeActive ? Config.osd.sizes.sliderHeight : 0
        opacity: shouldBeActive ? 1 : 0
        active: opacity > 0
        asynchronous: true
        visible: active

        Behavior on Layout.preferredHeight {
            Anim {
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
