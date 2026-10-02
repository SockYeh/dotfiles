pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.modules.bar
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
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || visibilities.keybinds || visibilities.editingWeatherLocation || visibilities.dashboard || visibilities.manga || visibilities.novel || panels.popouts.isDetached ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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

            // Frosted glass behind the shell's own panels, using
            // ext-background-effect-v1. One region per panel, so the bar strip
            // and the dashboard share the same blurred base; panels with zero
            // height (closed) collapse to an empty region.
            BackgroundEffect.blurRegion: Region {
                Region {
                    // Strip behind the bar — Border fills it, so blur it too.
                    x: 0
                    y: 0
                    width: win.width
                    height: bar.implicitHeight
                }

                // The dashboard's fill (modules/dashboard/Background.qml) is
                // wider than the body at the very top — the top edge runs out
                // to a tip either side and each shoulder is a concave cove back
                // down to the body's edge. A Region is only ever a rect or an
                // ellipse, so the same silhouette is built here as "body plus a
                // flared top band, minus the two cove bites", where each bite
                // is the top half of an ellipse centred on the body's top
                // corner — exactly the curve the fill's shoulder arc draws.
                //
                // This has to track the fill precisely. If the blur is merely a
                // rectangle, its edge reads as the panel's edge and the flare
                // disappears; if it reaches past the body lower down, it leaves
                // bright strips down both sides.
                Region {
                    id: dashBlur

                    readonly property int flare: Config.border.rounding
                    readonly property int bodyX: panels.dashboard.x + Config.border.thickness
                    readonly property int bodyY: panels.dashboard.y + bar.implicitHeight
                    readonly property int bodyW: panels.dashboard.width

                    // Body plus the wings, then carve it back to shape. Every
                    // Region in a boolean chain needs its own rect — an unset
                    // one is empty, so Subtract/Intersect would collapse.
                    //
                    // `intersection` on a node says how that node folds into
                    // its *parent's* region, so the carves below carry Subtract
                    // and this node stays a Combine. Putting Subtract here
                    // instead subtracts the whole panel from the entire blur
                    // region and leaves no frost at all.
                    x: dashBlur.bodyX - dashBlur.flare
                    y: dashBlur.bodyY
                    width: dashBlur.bodyW + dashBlur.flare * 2
                    height: panels.dashboard.height
                    radius: 0

                    // Wings only exist in the top band; trim them off below it.
                    Region {
                        intersection: Intersection.Subtract
                        x: dashBlur.bodyX - dashBlur.flare
                        y: dashBlur.bodyY + dashBlur.flare
                        width: dashBlur.flare
                        height: panels.dashboard.height - dashBlur.flare
                    }

                    Region {
                        intersection: Intersection.Subtract
                        x: dashBlur.bodyX + dashBlur.bodyW
                        y: dashBlur.bodyY + dashBlur.flare
                        width: dashBlur.flare
                        height: panels.dashboard.height - dashBlur.flare
                    }

                    // Top-left cove. This node's own rect is the clip that
                    // keeps the ellipse to its top half; the ellipse child
                    // intersects with it, and the node subtracts the result.
                    Region {
                        intersection: Intersection.Subtract
                        x: dashBlur.bodyX - dashBlur.flare * 2
                        y: dashBlur.bodyY
                        width: dashBlur.flare * 4
                        height: dashBlur.flare

                        Region {
                            shape: RegionShape.Ellipse
                            intersection: Intersection.Intersect
                            x: dashBlur.bodyX - dashBlur.flare * 2
                            y: dashBlur.bodyY
                            width: dashBlur.flare * 2
                            height: dashBlur.flare * 2
                        }
                    }

                    // Top-right cove, mirrored.
                    Region {
                        intersection: Intersection.Subtract
                        x: dashBlur.bodyX + dashBlur.bodyW - dashBlur.flare * 2
                        y: dashBlur.bodyY
                        width: dashBlur.flare * 4
                        height: dashBlur.flare

                        Region {
                            shape: RegionShape.Ellipse
                            intersection: Intersection.Intersect
                            x: dashBlur.bodyX + dashBlur.bodyW
                            y: dashBlur.bodyY
                            width: dashBlur.flare * 2
                            height: dashBlur.flare * 2
                        }
                    }
                }
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

                Border {
                    bar: bar
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
                property bool manga
                property bool novel

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
