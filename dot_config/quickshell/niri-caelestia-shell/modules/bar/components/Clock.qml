pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3primary
    readonly property int padding: Config.bar.clock.background ? Appearance.padding.normal : Appearance.padding.small

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: Config.bar.sizes.innerWidth

    color: Qt.alpha(Colours.palette.m3surface, Config.bar.clock.background ? 0.4 : 0)
    radius: Appearance.rounding.full

    Row {
        id: layout
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Loader {
            anchors.verticalCenter: parent.verticalCenter

            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }
        
        StyledText {
            anchors.verticalCenter: parent.verticalCenter

            visible: Config.bar.clock.showDate

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format("ddd d")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.clock
            color: root.colour
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.bar.clock.showDate
            width: visible ? 1 : 0
            height: parent.height * 0.6
            color: root.colour
            opacity: 0.2
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format(Config.services.useTwelveHourClock ? "hh:mm A" : "hh:mm")
            font.pointSize: Appearance.font.size.larger
            font.family: Appearance.font.family.clock
            font.weight: Font.Medium
            color: root.colour
        }
    }
}
