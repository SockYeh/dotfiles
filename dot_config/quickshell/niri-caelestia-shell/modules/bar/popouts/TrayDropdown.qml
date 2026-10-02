pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

StyledRect {
    id: root

    // The bar popouts wrapper; used to switch to a per-item tray menu
    property var popouts

    readonly property int entrySize: Appearance.font.size.larger * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full

    implicitWidth: layout.implicitWidth + Appearance.padding.lg * 2
    implicitHeight: layout.implicitHeight + Appearance.padding.lg * 2

    Row {
        id: layout

        anchors.centerIn: parent
        spacing: Appearance.spacing.sm

        Repeater {
            model: ScriptModel {
                values: [...SystemTray.items.values]
            }

            Item {
                id: entry

                required property SystemTrayItem modelData
                required property int index

                implicitWidth: root.entrySize
                implicitHeight: root.entrySize

                StyledRect {
                    anchors.fill: parent

                    radius: Appearance.rounding.full
                    color: area.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"
                }

                ColouredIcon {
                    id: trayIcon

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.xs

                    source: Icons.getTrayIcon(entry.modelData.id, entry.modelData.icon, Config.bar.tray.iconSubs)
                    colour: Colours.palette.m3secondary
                    layer.enabled: Config.bar.tray.recolour
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: event => {
                        if (event.button === Qt.LeftButton) {
                            entry.modelData.activate();
                        } else if (entry.modelData.menu) {
                            // Right-click opens the item's menu as a popout
                            root.popouts.currentName = `traymenu${entry.index}`;
                            root.popouts.hasCurrent = true;
                        }
                    }
                }
            }
        }
    }
}
// reload 1790885938
