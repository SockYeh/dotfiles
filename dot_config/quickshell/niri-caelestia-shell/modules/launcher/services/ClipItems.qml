pragma Singleton

import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history as a searchable list, so ">clip " filtering goes through
// the same Searcher (and the same matcher choice) as apps, actions, schemes,
// variants and wallpapers instead of a hand-rolled substring test.
Searcher {
    id: root

    key: "entryText"
    useFuzzy: Config.launcher.useFuzzy.clip

    // Rebuilt wholesale on each refresh; the launcher asks for a fresh read
    // whenever the clipboard mode is entered.
    property list<var> entries: []

    readonly property int count: entries.length

    function refresh(): void {
        cliphistProc.running = true;
    }

    function remove(entryId: string): void {
        const next = [];
        for (const entry of entries) {
            if (entry.entryId !== entryId)
                next.push(entry);
        }
        entries = next;
    }

    Variants {
        id: instances

        model: root.entries

        QtObject {
            required property var modelData

            readonly property string entryId: modelData?.entryId ?? ""
            readonly property string entryText: modelData?.entryText ?? ""
            readonly property bool isImage: modelData?.isImage ?? false
        }
    }

    list: instances.instances

    Process {
        id: cliphistProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = [];
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    if (!line)
                        continue;
                    const parts = line.split("\t");
                    parsed.push({
                        entryId: parts[0],
                        entryText: parts.slice(1).join("\t"),
                        isImage: line.includes("[[ binary data")
                    });
                }
                root.entries = parsed;
            }
        }
    }
}