pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
import "popouts" as BarPopouts
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts

    // On an empty workspace there's nothing to make room for, so keep the bar
    // permanently visible instead of the hover-to-show behaviour. "Empty" has to
    // mean niri told us so: until its IPC is up there are no workspaces and no
    // windows either, and treating that as an empty workspace pins the bar
    // visible with its exclusive zone reserved for the whole session.
    readonly property bool emptyWorkspace: Niri.niriAvailable && Niri.allWorkspaces?.length > 0 && Niri.getActiveWorkspaceWindows().length === 0

    readonly property int padding: Math.max(Appearance.padding.sm, Config.border.thickness)
    readonly property int contentHeight: Config.bar.sizes.innerWidth + padding * 2
    readonly property int exclusiveZone: Config.bar.persistent || emptyWorkspace || visibilities.bar ? contentHeight : 0
    readonly property bool shouldBeVisible: Config.bar.persistent || emptyWorkspace || visibilities.bar || isHovered
    property bool isHovered

    function checkPopout(x: real): void {
        content.item?.checkPopout(x);
    }

    function handleWheel(x: real, angleDelta: point): void {
        content.item?.handleWheel(x, angleDelta);
    }

    function clockHovered(mx: real, my: real): bool {
        return content.item?.clockHovered(mx, my) ?? false;
    }

    visible: height > Config.border.thickness
    implicitHeight: Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitHeight: root.contentHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }
    ]

    Loader {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        active: root.shouldBeVisible || root.visible

        sourceComponent: Bar {
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }
}
