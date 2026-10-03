import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Row {
    id: root

    required property PersistentProperties visibilities
    required property PersistentProperties state

    padding: Appearance.padding.xl
    spacing: Appearance.spacing.lg

    // Machine identity and today's date, in place of the distro and compositor.
    // None of it changes while the dashboard is open, so it is read once.
    property string identity: ""
    property string kernel: ""

    function ordinalDay(): string {
        const day = Time.date.getDate();
        const suffixes = ["th", "st", "nd", "rd"];
        const v = day % 100;
        return `${day}${suffixes[(v - 20) % 10] ?? suffixes[v] ?? suffixes[0]}`;
    }

    Process {
        id: identProc

        // "user@host kernel-release", in one shot: env vars aren't reliable
        // for either half (HOSTNAME is often unset in a user session).
        command: ["sh", "-c", "echo \"$(id -un)@$(hostname) $(uname -r)\""]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(" ");
                root.identity = parts[0] ?? "";
                root.kernel = parts.slice(1).join(" ");
            }
        }
    }

    StyledClippingRect {
        implicitWidth: info.implicitHeight
        implicitHeight: info.implicitHeight

        radius: Appearance.rounding.large
        color: Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 2)

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            fill: 1
            grade: 200
            font.pointSize: Math.floor(info.implicitHeight / 2) || 1
        }

        CachingImage {
            id: pfp

            anchors.fill: parent
            path: `${Paths.home}/.face`
        }

        CachingImage {
            id: wallpaperFallback

            anchors.fill: parent
            path: Wallpapers.getColorSource(Wallpapers.current)
            visible: pfp.status !== Image.Ready && Config.dashboard.useWallpaperAvatar
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            StyledRect {
                anchors.fill: parent

                color: Qt.alpha(Colours.palette.m3scrim, 0.5)
                opacity: parent.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                    }
                }
            }

            StyledRect {
                anchors.centerIn: parent

                implicitWidth: selectIcon.implicitHeight + Appearance.padding.xs * 2
                implicitHeight: selectIcon.implicitHeight + Appearance.padding.xs * 2

                radius: Appearance.rounding.normal
                color: Colours.palette.m3primary
                scale: parent.containsMouse ? 1 : 0.5
                opacity: parent.containsMouse ? 1 : 0

                StateLayer {
                    color: Colours.palette.m3onPrimary

                    function onClicked(): void {
                        root.visibilities.launcher = false;
                        root.state.facePicker.open();
                    }
                }

                MaterialIcon {
                    id: selectIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -font.pointSize * 0.02

                    text: "frame_person"
                    color: Colours.palette.m3onPrimary
                    font.pointSize: Appearance.font.size.headlineLarge
                }

                Behavior on scale {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                        easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                    }
                }

                Behavior on opacity {
                    Anim {
                        duration: Appearance.anim.durations.expressiveFastSpatial
                    }
                }
            }
        }
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.lg

        InfoLine {
            icon: "terminal"
            text: root.identity.length > 0 ? `${root.identity} (${root.kernel})` : qsTr("unknown host")
            colour: Colours.palette.m3primary
        }

        InfoLine {
            icon: "calendar_month"
            text: `${Time.format("dddd")}, ${root.ordinalDay()} ${Time.format("MMMM")}`
            colour: Colours.palette.m3secondary
        }

        InfoLine {
            id: uptime

            icon: "timer"
            text: qsTr("up %1").arg(SysInfo.uptime)
            colour: Colours.palette.m3tertiary
        }
    }

    component InfoLine: Item {
        id: line

        required property string icon
        required property string text
        required property color colour

        implicitWidth: icon.implicitWidth + text.width + text.anchors.leftMargin
        implicitHeight: Math.max(icon.implicitHeight, text.implicitHeight)

        MaterialIcon {
            id: icon

            anchors.left: parent.left
            anchors.leftMargin: (Config.dashboard.sizes.infoIconSize - implicitWidth) / 2

            fill: 1
            text: line.icon
            color: line.colour
            font.pointSize: Appearance.font.size.bodyMedium
        }

        StyledText {
            id: text

            anchors.verticalCenter: icon.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: icon.anchors.leftMargin
            text: `:  ${line.text}`
            font.pointSize: Appearance.font.size.bodyMedium

            // Grow with the text rather than clipping at the configured info
            // width: the host line (user@host plus kernel release) is wider
            // than the uptime line it used to be sized around.
            width: Math.max(Config.dashboard.sizes.infoWidth, implicitWidth)
            elide: Text.ElideRight
        }
    }
}
