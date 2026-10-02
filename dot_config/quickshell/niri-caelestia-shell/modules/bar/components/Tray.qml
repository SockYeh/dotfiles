pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Services.SystemTray
import QtQuick

StyledRect {
    id: root

    // Single button; all tray items live in the trayDropdown popout
    readonly property alias button: button

    clip: true
    visible: width > 0 && height > 0 // To avoid warnings about being visible with no size

    readonly property int pad: Config.bar.tray.background ? Appearance.padding.md : Appearance.padding.xs

    implicitWidth: SystemTray.items.values.length > 0 ? icon.implicitWidth + pad * 2 : 0
    implicitHeight: Config.bar.sizes.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.tray.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Appearance.rounding.full

    MouseArea {
        id: button

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        MaterialIcon {
            id: icon

            anchors.centerIn: parent

            animate: true
            text: "expand_more"
            color: Colours.palette.m3secondary
        }
    }
}
