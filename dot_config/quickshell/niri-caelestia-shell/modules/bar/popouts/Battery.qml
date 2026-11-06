pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Column {
    id: root

    spacing: Appearance.spacing.lg
    width: Math.max(Config.bar.sizes.batteryWidth, header.implicitWidth)

    readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
    readonly property string remainingText: root.hasBattery ? qsTr("Remaining: %1%").arg(Math.round(UPower.displayDevice.percentage * 100)) : qsTr("No battery detected")
    readonly property string timeText: root.hasBattery ? (UPower.onBattery ? root.formatSeconds(UPower.displayDevice.timeToEmpty, "Calculating...") : root.formatSeconds(UPower.displayDevice.timeToFull, "Fully charged!")) : qsTr("Power profile: %1").arg(PowerManagement.platformProfile || qsTr("Unknown"))

    function formatSeconds(s: int, fallback: string): string {
        const day = Math.floor(s / 86400);
        const hr = Math.floor(s / 3600) % 60;
        const min = Math.floor(s / 60) % 60;

        let comps = [];
        if (day > 0)
            comps.push(`${day} days`);
        if (hr > 0)
            comps.push(`${hr} hours`);
        if (min > 0)
            comps.push(`${min} mins`);

        return comps.join(", ") || fallback;
    }

    function profileIcon(profile: string): string {
        switch (profile) {
        case "low-power":
            return "energy_savings_leaf";
        case "quiet":
            return "volume_off";
        case "balanced":
            return "balance";
        case "performance":
            return "rocket_launch";
        default:
            return "tune";
        }
    }

    function profileLabel(profile: string): string {
        switch (profile) {
        case "low-power":
            return qsTr("Low power");
        case "quiet":
            return qsTr("Quiet");
        case "balanced":
            return qsTr("Balanced");
        case "performance":
            return qsTr("Performance");
        default:
            return profile;
        }
    }

    RowLayout {
        id: header

        width: parent.width
        spacing: Appearance.spacing.xs

        StyledText {
            Layout.fillWidth: true
            text: root.remainingText
        }

        StyledText {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            text: root.timeText
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.labelMedium
        }
    }

    Loader {
        anchors.horizontalCenter: parent.horizontalCenter

        active: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
        asynchronous: true

        height: active ? (item?.implicitHeight ?? 0) : 0

        sourceComponent: StyledRect {
            implicitWidth: child.implicitWidth + Appearance.padding.md * 2
            implicitHeight: child.implicitHeight + Appearance.padding.sm * 2

            color: Colours.palette.m3error
            radius: Appearance.rounding.normal

            Column {
                id: child

                anchors.centerIn: parent

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Appearance.spacing.sm

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Performance Degraded")
                        color: Colours.palette.m3onError
                        font.family: Appearance.font.family.mono
                        font.weight: 500
                    }

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -font.pointSize / 10

                        text: "warning"
                        color: Colours.palette.m3onError
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: qsTr("Reason: %1").arg(PerformanceDegradationReason.toString(PowerProfiles.degradationReason))
                    color: Colours.palette.m3onError
                }
            }
        }
    }

    RowLayout {
        width: parent.width
        spacing: Appearance.spacing.sm
        visible: PowerManagement.chargeLimitAvailable

        StyledText {
            text: qsTr("Charge limit")
            font.weight: 500
        }

        Item {
            Layout.fillWidth: true
        }

        StyledInputField {
            id: limitInput

            Layout.preferredWidth: 58

            text: `${Math.max(PowerManagement.minChargeLimit, PowerManagement.chargeLimit)}`
            placeholderText: qsTr("%")
            horizontalAlignment: TextInput.AlignHCenter
            validator: IntValidator {
                bottom: PowerManagement.minChargeLimit
                top: PowerManagement.maxChargeLimit
            }

            onHasFocusChanged: {
                // The field starts with the current limit; clear it so typing
                // replaces the value instead of appending an invalid number.
                if (hasFocus)
                    text = "";
            }

            onEditingFinished: {
                const val = parseInt(text);
                if (isNaN(val)) {
                    text = `${PowerManagement.chargeLimit}`;
                    return;
                }

                text = `${Math.max(PowerManagement.minChargeLimit, Math.min(PowerManagement.maxChargeLimit, val))}`;
                PowerManagement.setChargeLimit(val);
            }
        }

        StyledText {
            text: "%"
            color: Colours.palette.m3outline
            font.pointSize: Appearance.font.size.bodySmall
        }
    }

    StyledRect {
        id: profiles

        anchors.horizontalCenter: parent.horizontalCenter
        visible: PowerManagement.profileAvailable

        implicitWidth: profileRow.implicitWidth + Appearance.padding.md * 2
        implicitHeight: profileRow.implicitHeight + Appearance.padding.xs * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        Row {
            id: profileRow

            anchors.centerIn: parent

            Repeater {
                model: PowerManagement.platformProfileChoices

                delegate: Profile {
                    required property string modelData

                    profile: modelData
                }
            }
        }
    }

    Connections {
        target: PowerManagement

        function onChargeLimitChanged(): void {
            if (!limitInput.hasFocus)
                limitInput.text = `${PowerManagement.chargeLimit}`;
        }

        function onWriteFailed(): void {
            limitInput.text = `${PowerManagement.chargeLimit}`;
        }
    }

    component Profile: Item {
        id: profileItem

        required property string profile

        readonly property bool active: PowerManagement.platformProfile === profileItem.profile

        implicitWidth: icon.implicitHeight + Appearance.padding.xs * 2
        implicitHeight: icon.implicitHeight + Appearance.padding.xs * 2

        StyledRect {
            anchors.fill: parent
            radius: Appearance.rounding.full
            color: Colours.palette.m3primary
            opacity: profileItem.active ? 1 : 0

            Behavior on opacity {
                Anim {}
            }
        }

        StateLayer {
            radius: Appearance.rounding.full
            color: profileItem.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            function onClicked(): void {
                PowerManagement.setPlatformProfile(profileItem.profile);
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent

            text: root.profileIcon(profileItem.profile)
            font.pointSize: Appearance.font.size.titleMedium
            color: profileItem.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            fill: profileItem.active ? 1 : 0

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.anim.durations.normal
                }
            }

            Behavior on fill {
                Anim {}
            }
        }

        Tooltip {
            target: profileItem
            text: root.profileLabel(profileItem.profile)
        }
    }
}
