pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property Item bar

    anchors.fill: parent
    visible: Config.border.thickness > 0

    StyledRect {
        anchors.fill: parent
        // Same base as the dashboard panel: a touch of translucency (the
        // drawers group multiplies this by transparency.base) so the blur
        // behind the bar strip reads through.
        color: Qt.alpha(Colours.palette.m3surface, 0.8)

        layer.enabled: root.visible
        layer.effect: MultiEffect {
            maskSource: mask
            maskEnabled: true
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: root.visible
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Config.border.thickness
            anchors.topMargin: root.bar.implicitHeight
            radius: Config.border.rounding
        }
    }
}
