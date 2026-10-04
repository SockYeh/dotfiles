pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.modules.bar
import qs.modules.bar.popouts as BarPopouts
import qs.modules.dashboard
import qs.modules.launcher as LauncherModule
import qs.modules.osd as OsdModule
import qs.modules.quicktoggles as QuickTogglesModule
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            bar: bar
        }

        StyledWindow {
            id: win

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || visibilities.keybinds || visibilities.editingWeatherLocation || visibilities.dashboard || panels.popouts.isDetached ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                x: Config.border.thickness
                y: bar.implicitHeight
                // While the launcher is open, take input everywhere so clicks
                // outside it reach the shell and close it.
                width: visibilities.launcher ? 0 : win.width - Config.border.thickness * 2
                height: visibilities.launcher ? 0 : win.height - bar.implicitHeight - Config.border.thickness
                intersection: Intersection.Xor

                regions: regions.instances
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            // Frosted glass behind the shell's panels using
            // ext-background-effect-v1. The bar strip is gone — it was a
            // full-width frosted extension over the workspace. Blur now only
            // carries over the dashboard, and its sub-regions are defined in
            // modules/dashboard/BlurRegion.qml so those rectangles vanish
            // when the panel is not on screen.
            // The dashboard's fill lives with the dashboard because the
            // region for it must collapse when the panel is not drawn.
            BackgroundEffect.blurRegion: Region {
                Region {
                    // Strip behind the bar backdrop. Collapsed while the bar is
                    // down, otherwise its border.thickness height leaves a
                    // blurred lip along the top of the screen.
                    x: 0
                    y: 0
                    width: win.width
                    height: bar.visible ? bar.implicitHeight : 0
                }

                BlurRegion {
                    dashboard: panels.dashboard
                    bar: bar
                }

                // Launcher and quick toggles carry the dashboard's flared silhouette,
                // so their blur regions have to follow the fill out to the
                // tips — otherwise the flare sits outside the blurred area
                // and reads as tint smeared over sharp wallpaper.
                LauncherModule.BlurRegion {
                    launcher: panels.launcher
                    bar: bar
                }

                Region {
                    item: panels.notifications
                    radius: Config.border.rounding
                }

                BarPopouts.BlurRegion {
                    wrapper: panels.popouts
                    bar: bar
                    invertBottomRounding: panels.popouts.animY + panels.popouts.height + 1 >= panels.height
                }

                QuickTogglesModule.BlurRegion {
                    quicktoggles: panels.quicktoggles
                    bar: bar
                }

                // The OSD fill is a plain rounded rectangle, so its blur is a
                // plain rounded rectangle that tracks the animating width.
                OsdModule.BlurRegion {
                    osd: panels.osd
                    bar: bar
                }

                // No blur behind the toasts or the now-playing popup: they
                // are flat translucent slabs, not frosted glass.
            }

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + Config.border.thickness
                    y: modelData.y + bar.implicitHeight
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
                }
            }

            // TODO: Implement focus grab for Niri when available

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
                color: Colours.palette.m3scrim

                Behavior on opacity {
                    Anim {}
                }
            }

            Item {
                anchors.fill: parent
                opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
                }


                Backgrounds {
                    panels: panels
                    bar: bar
                }
            }

            PersistentProperties {
                id: visibilities

                property bool bar
                property bool osd
                // Which OSD to show: "volume", "mic" or "brightness"
                property string osdMode: "volume"
                property bool nowPlaying
                property bool session
                property bool launcher
                property bool dashboard
                property bool utilities
                property bool clipboardRequested
                property bool wallpaperRequested
                property bool quicktoggles
                property bool keybinds
                property bool editingWeatherLocation
                property bool notifsExpanded

                Component.onCompleted: Visibilities.screens[scope.modelData.name] = this
            }

            Interactions {
                screen: scope.modelData
                popouts: panels.popouts
                visibilities: visibilities
                panels: panels
                bar: bar

                Panels {
                    id: panels

                    screen: scope.modelData
                    visibilities: visibilities
                    bar: bar
                }

                BarWrapper {
                    id: bar

                    anchors.left: parent.left
                    anchors.right: parent.right

                    screen: scope.modelData
                    visibilities: visibilities
                    popouts: panels.popouts

                    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                }
            }
        }
    }

}
