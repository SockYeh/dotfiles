pragma Singleton

import Caelestia
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.services

/**
 * PowerManagement
 *
 * The firmware's ACPI platform profile and the battery's charge threshold are
 * root-owned sysfs files, so writes go through the caelestia-power helper,
 * which is allowed via a passwordless sudo rule. Reads are watched so the UI
 * follows changes made elsewhere.
 */
Singleton {
    id: root

    readonly property string platformProfilePath: "/sys/firmware/acpi/platform_profile"
    readonly property string platformProfileChoicesPath: "/sys/firmware/acpi/platform_profile_choices"
    readonly property string helperPath: "/usr/local/bin/caelestia-power"
    // displayDevice is an aggregate whose nativePath is empty; the real battery
    // device is the one that names its sysfs node.
    readonly property var batteryDevice: (UPower.devices?.values ?? []).find(device => device.isLaptopBattery && device.nativePath) ?? null
    readonly property string batteryPath: {
        const native = root.batteryDevice?.nativePath ?? "";
        if (!native)
            return "";
        return native.startsWith("/") ? native : `/sys/class/power_supply/${native}`;
    }
    readonly property string chargeLimitPath: root.batteryPath ? `${root.batteryPath}/charge_control_end_threshold` : ""

    readonly property bool profileAvailable: root.platformProfile.length > 0 && root.platformProfileChoices.length > 0
    readonly property bool chargeLimitAvailable: root.chargeLimit >= 0
    readonly property bool busy: writeProc.running

    readonly property int minChargeLimit: 50
    readonly property int maxChargeLimit: 100

    property string platformProfile: ""
    property list<string> platformProfileChoices: []
    property int chargeLimit: -1
    property var pendingWrite: null

    signal writeFailed

    function setPlatformProfile(profile: string): void {
        if (!root.platformProfileChoices.includes(profile) || profile === root.platformProfile)
            return;
        root.writeValue("platform", profile);
    }

    function setChargeLimit(limit: int): void {
        if (!root.chargeLimitAvailable)
            return;

        const clamped = Math.max(root.minChargeLimit, Math.min(root.maxChargeLimit, Math.round(limit)));
        if (clamped === root.chargeLimit)
            return;

        root.writeValue("charge-limit", String(clamped));
    }

    function writeValue(command: string, value: string): void {
        if (writeProc.running) {
            root.pendingWrite = [command, value];
            return;
        }

        // The helper validates both the command and its value itself, so a
        // passwordless sudo rule cannot be used to write arbitrary files.
        writeProc.exec(["/usr/bin/sudo", "-n", root.helperPath, command, value]);
    }

    FileView {
        id: profileView

        path: root.platformProfilePath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.platformProfile = text().trim()
    }

    FileView {
        id: choicesView

        path: root.platformProfileChoicesPath

        onLoaded: root.platformProfileChoices = text().trim().split(/\s+/).filter(Boolean)
    }

    FileView {
        id: limitView

        path: root.chargeLimitPath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            const value = parseInt(text().trim(), 10);
            root.chargeLimit = Number.isNaN(value) ? -1 : value;
        }
    }

    Process {
        id: writeProc

        property string errorText: ""

        stderr: StdioCollector {
            onStreamFinished: writeProc.errorText = text
        }

        onExited: (code, status) => {
            if (code !== 0) {
                const raw = writeProc.errorText.trim();
                const message = raw.includes("password") ? qsTr("The power helper is not set up yet") : (raw || qsTr("Could not apply the setting"));
                console.warn("[PowerManagement] write failed:", code, raw);
                Toaster.toast(qsTr("Power setting not changed"), message, "error", Toast.Error);
                root.pendingWrite = null;
                root.writeFailed();
            }

            writeProc.errorText = "";
            profileView.reload();
            limitView.reload();

            if (root.pendingWrite) {
                const next = root.pendingWrite;
                root.pendingWrite = null;
                root.writeValue(next[0], next[1]);
            }
        }
    }
}
