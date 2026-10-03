import qs.components
import qs.components.effects
import qs.services
import qs.config
import Caelestia
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property Toast modelData

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight + Appearance.padding.sm * 2

    // Stadium ends: fully rounded left and right, like a pill.
    radius: height / 2
    // Flat neutral veil rather than the panel frost — over a dark backdrop
    // this lands on the plain dark grey the toasts are supposed to read as.
    // The type colour lives in the icon plate below instead.
    color: Qt.alpha(Colours.palette.m3onSurface, 0.2)

    border.width: 0

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 3
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.sm
        anchors.leftMargin: Appearance.padding.md
        anchors.rightMargin: Appearance.padding.md
        spacing: Appearance.spacing.lg

        StyledRect {
            radius: Appearance.rounding.normal
            color: {
                if (root.modelData.type === Toast.Success)
                    return Qt.alpha(Colours.palette.m3success, 0.85);
                if (root.modelData.type === Toast.Warning)
                    return Qt.alpha(Colours.palette.m3secondaryContainer, 0.85);
                if (root.modelData.type === Toast.Error)
                    return Qt.alpha(Colours.palette.m3error, 0.85);
                // m3surfaceContainerHigh is pure black on OLED schemes, which
                // reads as a hole punched in the toast.
                return Qt.alpha(Colours.palette.m3onSurface, 0.12);
            }

            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Appearance.padding.sm * 2

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.modelData.icon
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccess;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondaryContainer;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onError;
                    return Colours.palette.m3onSurfaceVariant;
                }
                font.pointSize: Math.round(Appearance.font.size.titleMedium * 1.2)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title

                Layout.fillWidth: true
                text: root.modelData.title
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
                }
                font.pointSize: Appearance.font.size.bodyMedium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: root.modelData.message
                color: {
                    if (root.modelData.type === Toast.Success)
                        return Colours.palette.m3onSuccessContainer;
                    if (root.modelData.type === Toast.Warning)
                        return Colours.palette.m3onSecondary;
                    if (root.modelData.type === Toast.Error)
                        return Colours.palette.m3onErrorContainer;
                    return Colours.palette.m3onSurface;
                }
                opacity: 0.8
                elide: Text.ElideRight
            }
        }
    }

    Behavior on color {
        CAnim {}
    }

    Behavior on border.color {
        CAnim {}
    }
}
