pragma ComponentBehavior: Bound

import "items"
import "services"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

StyledListView {
    id: root

    required property TextField search
    required property PersistentProperties visibilities

    // Debounce search text to avoid re-filtering on every keystroke
    property string _debouncedText: search.text
    Timer {
        id: _searchDebounce
        interval: 120
        onTriggered: root._debouncedText = root.search.text
    }
    Connections {
        target: root.search
        function onTextChanged(): void {
            // Immediate update for short strings (mode detection), debounce for actual search
            if (root.search.text.length <= 1)
                root._debouncedText = root.search.text;
            else
                _searchDebounce.restart();
        }
    }

    // Clipboard entries live in the ClipItems searcher; this only strips the
    // ">clip " prefix so the query that reaches the matcher is the bare text.
    readonly property string _clipQuery: _debouncedText.startsWith(`${Config.launcher.actionPrefix}clip `)
        ? _debouncedText.slice(`${Config.launcher.actionPrefix}clip `.length).toLowerCase()
        : ""

    function refreshClipboard(): void { ClipItems.refresh(); }

    function removeClipEntry(entryId: string): void { ClipItems.remove(entryId); }

    // Read count alongside the query so this binding re-evaluates when the
    // clipboard history is replaced, not only when the search text changes.
    readonly property var listValues: {
        const clipCount = ClipItems.count;
        switch (state) {
            case "actions":
                return Actions.query(_debouncedText);
            case "calc":
                return [0];
            case "scheme":
                return Schemes.query(_debouncedText);
            case "variant":
                return M3Variants.query(_debouncedText);
            case "clip":
                return clipCount >= 0 ? ClipItems.query(_clipQuery) : [];
            case "emoji":
                return [0];
            case "web":
                return [0];
        }
        return Apps.search(_debouncedText);
    }

    model: ScriptModel {
        id: model

        // One place picks what the list shows. This used to live in each
        // state's PropertyChanges, which meant a mode entered before its
        // source had data kept a stale snapshot: the binding did not
        // re-evaluate when ClipItems' history arrived from cliphist a moment
        // later, leaving ">clip" empty on the first open.
        values: root.listValues
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Appearance.spacing.sm
    orientation: Qt.Vertical
    implicitHeight: {
        if (state === "emoji")
            return Math.min(Config.launcher.maxShown * Config.launcher.sizes.itemHeight, 400);
        return (Config.launcher.sizes.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing;
    }

    highlightMoveDuration: Appearance.anim.durations.normal
    highlightResizeDuration: 0

    highlight: StyledRect {
        radius: Appearance.rounding.small
        color: Colours.palette.m3onSurface
        opacity: 0.08
    }

    state: {
        const text = _debouncedText;
        const prefix = Config.launcher.actionPrefix;
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "scheme", "variant", "clip", "emoji", "web"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;

            return "actions";
        }

        return "apps";
    }

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
        if (state === "clip")
            refreshClipboard();
    }

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                root.delegate: calcItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"

            PropertyChanges {
                root.delegate: variantItem
            }
        },
        State {
            name: "clip"

            PropertyChanges {
                root.delegate: clipItem
            }
        },
        State {
            name: "emoji"

            PropertyChanges {
                root.delegate: emojiItem
            }
        },
        State {
            name: "web"

            PropertyChanges {
                root.delegate: webItem
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                }
            }
            PropertyAction {
                targets: [model, root]
                properties: "values,delegate"
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Appearance.anim.durations.small
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    ScrollBar.vertical: StyledScrollBar {}

    add: Transition {
        enabled: !root.state

        Anim {
            properties: "opacity,scale"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            properties: "opacity,scale"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            duration: Appearance.anim.durations.small
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            properties: "opacity,scale"
            to: 1
        }
    }

    Component {
        id: appItem

        AppItem {
            visibilities: root.visibilities
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }

    Component {
        id: clipItem

        ClipItem {
            list: root
        }
    }

    Component {
        id: emojiItem

        EmojiList {
            search: root.search
            visibilities: root.visibilities
        }
    }

    Component {
        id: webItem

        WebItem {
            list: root
        }
    }
}
