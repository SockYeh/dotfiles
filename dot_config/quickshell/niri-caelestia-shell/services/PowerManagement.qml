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
    property var inFlight: null

    signal writeFailed

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

    function setPlatformProfile(profile: string): void {
        if (root.busy || !root.platformProfileChoices.includes(profile) || profile === root.platformProfile)
            return;

        // Move the indicator immediately; the file watcher confirms it later.
        const previous = root.platformProfile;
        root.platformProfile = profile;
        root.writeValue("platform", profile, previous);
    }

    function setChargeLimit(limit: int): void {
        if (root.busy || !root.chargeLimitAvailable)
            return;

        const clamped = Math.max(root.minChargeLimit, Math.min(root.maxChargeLimit, Math.round(limit)));
        if (clamped === root.chargeLimit)
            return;

        // Show the new limit right away instead of waiting for the sysfs watcher.
        const previous = root.chargeLimit;
        root.chargeLimit = clamped;
        root.writeValue("charge-limit", String(clamped), previous);
    }

    function writeValue(command: string, value: string, previous: var): void {
        if (writeProc.running)
            return;

        root.inFlight = {
            command,
            value,
            previous
        };

        // The helper validates both the command and its value itself, so a
        // passwordless sudo rule cannot be used to write arbitrary files.
        writeProc.exec(["/usr/bin/sudo", "-n", root.helperPath, command, value]);
    }

    function notifySuccess(): void {
        const command = root.inFlight?.command ?? "";
        const value = root.inFlight?.value ?? "";

        if (command === "platform")
            Toaster.toast(qsTr("Power profile changed"), qsTr("Now using %1").arg(root.profileLabel(value)), "tune");
        else if (command === "charge-limit")
            Toaster.toast(qsTr("Charge limit changed"), parseInt(value) >= root.maxChargeLimit ? qsTr("Charging to full") : qsTr("Stops charging at %1%").arg(value), "battery_charging_full");
    }

    FileView {
        id: profileView

        path: root.platformProfilePath
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            if (!root.busy)
                root.platformProfile = text().trim();
        }
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
            if (root.busy)
                return;

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
            if (code === 0) {
                root.notifySuccess();
            } else {
                const raw = writeProc.errorText.trim();
                const message = raw.includes("password") ? qsTr("The power helper is not set up yet") : (raw || qsTr("Could not apply the setting"));
                console.warn("[PowerManagement] write failed:", code, raw);

                // Put the UI back to the value that was actually on disk.
                if (root.inFlight?.command === "platform")
                    root.platformProfile = root.inFlight.previous;
                else if (root.inFlight?.command === "charge-limit")
                    root.chargeLimit = root.inFlight.previous;

                Toaster.toast(qsTr("Power setting not changed"), message, "error", Toast.Error);
                root.writeFailed();
            }

            root.inFlight = null;
            writeProc.errorText = "";
            profileView.reload();
            limitView.reload();
        }
    }
}
