#!/usr/bin/env bash
# Small background helpers for the session, spawned by cfg/autostart.kdl.
# Keeps spawn-at-startup tidy: one line here instead of one per command.
set -u

# Clipboard history for the shell's clipboard panel (Super+V).
# Guarded so running it twice doesn't stack duplicate watchers.
if ! pgrep -f "wl-paste --type text --watch cliphist store" >/dev/null; then
    wl-paste --type text --watch cliphist store &
fi
if ! pgrep -f "wl-paste --type image --watch cliphist store" >/dev/null; then
    wl-paste --type image --watch cliphist store &
fi

wait
