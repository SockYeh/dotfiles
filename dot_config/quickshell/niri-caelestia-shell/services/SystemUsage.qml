pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import Caelestia.Services

Singleton {
    id: root

    // CPU properties
    property string cpuName: cleanCpuName(SysMonitor.cpu.model || "")
    property real cpuPerc
    property real cpuTemp: SysMonitor.cpu.temperature || 0

    // GPU properties
    readonly property string gpuType: Config.services.gpuType.toUpperCase() || SysMonitor.gpu.type || "NONE"
    property string gpuName: cleanGpuName(SysMonitor.gpu.name || "")
    property real gpuPerc: SysMonitor.gpu.utilization || 0
    property real gpuTemp: SysMonitor.gpu.temperature || 0

    // Memory properties
    property real memUsed
    property real memTotal
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0

    // Storage properties (aggregated)
    readonly property real storagePerc: {
        let totalUsed = 0;
        let totalSize = 0;
        for (const disk of disks) {
            totalUsed += disk.used;
            totalSize += disk.total;
        }
        return totalSize > 0 ? totalUsed / totalSize : 0;
    }

    // Individual disks: Array of { mount, used, total, free, perc }
    property var disks: []

    property real lastCpuIdle
    property real lastCpuTotal

    property int refCount

    function cleanCpuName(name: string): string {
        if (!name) return "";
        let cleaned = name.replace(/\(R\)/gi, "").replace(/\(TM\)/gi, "").replace(/CPU/gi, "").replace(/\d+th Gen /gi, "").replace(/\d+nd Gen /gi, "").replace(/\d+rd Gen /gi, "").replace(/\d+st Gen /gi, "").replace(/Core /gi, "").replace(/Processor/gi, "").replace(/\s+/g, " ").trim();

        if (cleaned.length > 25) {
            cleaned = cleaned.substring(0, 22) + "...";
        }
        return cleaned;
    }

    function cleanGpuName(name: string): string {
        if (!name) return "";
        let cleaned = name.replace(/NVIDIA GeForce /gi, "")
                          .replace(/NVIDIA /gi, "")
                          .replace(/AMD Radeon /gi, "")
                          .replace(/AMD /gi, "")
                          .replace(/Intel\(R\) /gi, "")
                          .replace(/Intel /gi, "")
                          .replace(/\(R\)/gi, "")
                          .replace(/\(TM\)/gi, "")
                          .replace(/Graphics/gi, "")
                          .replace(/ Laptop GPU/gi, "")
                          .replace(/ Mobile/gi, "")
                          .replace(/ Desktop/gi, "")
                          .replace(/\s+/g, " ")
                          .trim();

        if (cleaned.length > 25) {
            cleaned = cleaned.substring(0, 22) + "...";
        }
        return cleaned;
    }

    function formatKib(kib: real): var {
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

        if (kib >= tib)
            return {
                value: kib / tib,
                unit: "TiB"
            };
        if (kib >= gib)
            return {
                value: kib / gib,
                unit: "GiB"
            };
        if (kib >= mib)
            return {
                value: kib / mib,
                unit: "MiB"
            };
        return {
            value: kib,
            unit: "KiB"
        };
    }

    // Power in watts. Prefers the CPU package counter (intel-rapl), which needs
    // the energy file to be readable; falls back to summing the power supplies
    // the shell can always see, which only report a figure while the battery
    // is actually discharging.
    property real watts
    property bool raplReadable: false
    property real _lastEnergyUj
    property real _lastEnergyAt

    // Returns true when it produced a reading, so the caller knows whether the
    // fallback still needs running.
    function updateWattageRapl(): bool {
        raplFile.reload();
        const text = raplFile.text();
        if (!text) {
            root.raplReadable = false;
            return false;
        }

        const energy = parseFloat(text);
        if (isNaN(energy)) {
            root.raplReadable = false;
            return false;
        }

        const now = Date.now();
        // The counter wraps at max_energy_range_uj; a backwards jump means a
        // wrap, so skip this tick's figure instead of reporting a spike.
        if (root._lastEnergyUj !== undefined && energy >= root._lastEnergyUj) {
            const seconds = (now - root._lastEnergyAt) / 1000;
            if (seconds > 0) {
                root.watts = (energy - root._lastEnergyUj) / 1e6 / seconds;
                root.raplReadable = true;
            }
        }

        root._lastEnergyUj = energy;
        root._lastEnergyAt = now;
        return root.raplReadable;
    }

    FileView {
        id: raplFile

        path: "/sys/class/powercap/intel-rapl:0/energy_uj"
    }

    Process {
        id: powerProc

        // One line per supply in microwatts: current_now (µA) x voltage_now
        // (µV). Kept in µW so sub-watt draws survive the shell's integer maths;
        // the conversion to watts happens below.
        command: ["sh", "-c", "for f in /sys/class/power_supply/*/current_now; do d=${f%/current_now}; v=$(cat $d/voltage_now 2>/dev/null) || continue; [ -n \"$v\" ] || continue; echo $(( $(cat $f 2>/dev/null) * v )); done 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                // RAPL won, if it is readable: it measures the package
                // whether or not the machine is on battery.
                if (root.raplReadable)
                    return;

                let total = 0;
                for (const line of this.text.split("\n")) {
                    const microwatts = parseFloat(line);
                    // Signed drivers differ on which way is discharge; the
                    // magnitude is what a wattage readout wants.
                    if (!isNaN(microwatts))
                        total += Math.abs(microwatts);
                }
                root.watts = total / 1e6;
            }
        }
    }

    Timer {
        running: root.refCount > 0
        interval: Config.dashboard.resourceUpdateInterval
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            SysMonitor.updateAll();

            if (!root.updateWattageRapl() && !powerProc.running)
                powerProc.running = true;
        }
    }
    
    Connections {
        target: SysMonitor
        
        function onCpuChanged() {
            let data = SysMonitor.cpu;
            root.cpuName = root.cleanCpuName(data.model || "");
            root.cpuTemp = data.temperature || 0;
            
            if (data.total && data.total.length >= 8) {
                const totalArray = Array.from(data.total);
                const total = totalArray.reduce((a, b) => a + b, 0);
                const idle = totalArray[3] + (totalArray[4] || 0);

                const totalDiff = total - root.lastCpuTotal;
                const idleDiff = idle - root.lastCpuIdle;
                root.cpuPerc = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;

                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }
        }
        
        function onMemoryChanged() {
            let m = SysMonitor.memory;
            root.memTotal = m.total || 1;
            const free = m.free || 0;
            const buf = m.buffers || 0;
            const cached = m.cached || 0;
            root.memUsed = (root.memTotal - (m.available || (free + buf + cached)));
        }
        
        function onDiskmountsChanged() {
            let mounts = SysMonitor.diskmounts;
            let diskList = [];
            for (let mount of mounts) {
                if (mount.fstype !== "tmpfs" && mount.fstype !== "devtmpfs") {
                    // C++ provides size in GB. We format disks in KiB, so GB * 1024 * 1024.
                    diskList.push({
                        mount: mount.device,
                        used: mount.used * 1024 * 1024,
                        total: mount.size * 1024 * 1024,
                        free: mount.avail * 1024 * 1024,
                        perc: mount.percent / 100.0
                    });
                }
            }
            root.disks = diskList;
        }
    }

}
