pragma ComponentBehavior: Bound

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Artwork image that mirrors the dashboard's cover: it displays `remoteSource`
 * by first fetching it with curl into Paths.imagecache and then painting the
 * local copy.
 *
 * Qt's own http stack can stall for minutes on hosts whose AAAA record points
 * at an unreachable IPv6 address (it sits in SYN-SENT and never falls back),
 * while curl tries IPv4 immediately. Fetching through curl makes artwork load
 * in ~200ms and be instant on every later track change, since it is cached on
 * disk.
 */
Image {
    id: root

    /** Remote url to display; empty shows nothing (use a fallback icon). */
    property url remoteSource: ""

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: Math.max(1, Math.round(width))
    sourceSize.height: Math.max(1, Math.round(height))

    function cacheFileFor(url: string): string {
        const withoutQuery = url.split("?")[0];
        const lastSegment = withoutQuery.substring(withoutQuery.lastIndexOf("/") + 1).trim();
        const name = (lastSegment || "art").replace(/[^A-Za-z0-9._-]/g, "_");
        return `${Paths.imagecache}/remote/${name}`;
    }

    function load(): void {
        const url = String(root.remoteSource ?? "");

        if (!url) {
            root.source = "";
            return;
        }

        if (url.startsWith("file:")) {
            root.source = url;
            return;
        }

        const out = root.cacheFileFor(url);
        const dir = out.substring(0, out.lastIndexOf("/"));
        const quotedUrl = url.replace(/'/g, `'\\''`);
        const script = `mkdir -p '${dir}'; if [ ! -s '${out}' ]; then curl -fsSL --max-time 8 -o '${out}.part' '${quotedUrl}' && mv -f '${out}.part' '${out}'; fi; [ -s '${out}' ]`;

        root.source = "";
        fetch.running = false;
        fetch.wanted = url;
        fetch.out = out;
        fetch.command = ["sh", "-c", script];
        fetch.running = true;
    }

    onRemoteSourceChanged: load()
    Component.onCompleted: load()

    Process {
        id: fetch

        property string wanted: ""
        property string out: ""

        onExited: (exitCode) => {
            if (exitCode === 0 && String(root.remoteSource ?? "") === fetch.wanted)
                root.source = `file://${fetch.out}`;
        }
    }
}
