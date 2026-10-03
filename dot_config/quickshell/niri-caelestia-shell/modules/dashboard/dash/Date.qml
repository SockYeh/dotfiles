pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Small date card: weekday, day number, month. Reads the same reactive clock
// the old time widget did, just showing the date instead of the time.
Item {
    id: root

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Config.dashboard.sizes.dateTimeWidth

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: -(font.pointSize * 0.4)
            text: Time.format("ddd").toUpperCase()
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.labelLarge
            font.family: Appearance.font.family.clock
            font.weight: 600
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format("d")
            color: Colours.palette.m3secondary
            font.pointSize: Appearance.font.size.displaySmall
            font.family: Appearance.font.family.clock
            font.weight: 600
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -(font.pointSize * 0.4)
            text: Time.format("MMMM").toUpperCase()
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.labelLarge
            font.family: Appearance.font.family.clock
            font.weight: 600
        }
    }
}