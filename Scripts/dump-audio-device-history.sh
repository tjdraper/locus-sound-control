#!/usr/bin/env bash
#
# Lists every audio device UID this Mac has ever seen, from CoreAudio's own records.
#
# The companion dump-audio-devices.swift shows more per device, but needs the Swift compiler.
# This needs nothing that is not already on a stock Mac, so it runs on a machine that has never
# had developer tools installed. It also reads history rather than what is attached right now,
# which is what makes a UID's instability visible: a device that shows up under several UIDs here
# is one the priority list cannot key on (Plans/HighLevelPlan.md, slices 6 and 7).

set -euo pipefail

readonly SETTINGS="/Library/Preferences/Audio/com.apple.audio.SystemSettings.plist"

[[ -r "$SETTINGS" ]] || {
    echo "error: cannot read $SETTINGS" >&2
    exit 1
}

echo "host:  $(scutil --get ComputerName 2>/dev/null || hostname)"
echo "date:  $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo

plutil -p "$SETTINGS" \
    | grep -oE '"device\.[^"]+"' \
    | sed 's/^"device\.//; s/"$//' \
    | sort -u \
    | sed 's/^/  /'

echo
echo "Devices by how many identities they have accumulated:"
{
    # A USB audio UID ends in :<serial or location id>:<interface>. When that field holds a location
    # id it changes with the port, so one device gains an entry per port it has been plugged into.
    plutil -p "$SETTINGS" \
        | grep -oE '"device\.AppleUSBAudioEngine:[^"]+"' \
        | sed 's/^"device\.AppleUSBAudioEngine://; s/"$//' \
        | awk -F: '{ print "usb      " $1 ":" $2 }'

    # Display audio repeats its EDID-derived id with an _XXXXXXXX suffix that varies per connection.
    plutil -p "$SETTINGS" \
        | grep -oE '"device\.[0-9A-F]{8}-[0-9A-F-]+(_[0-9A-F]{8})?"' \
        | sed 's/^"device\.//; s/"$//; s/_[0-9A-F]\{8\}$//' \
        | awk '{ print "display  " $0 }'

    # Screen sharing and AirPlay taps carry a per-session number, so every session is a new identity.
    plutil -p "$SETTINGS" \
        | grep -oE '"device\.[0-9A-F-]{36}-[0-9]+-screen"' \
        | sed -E 's/^"device\.([0-9A-F-]{36})-.*/screen   \1/'
} | sort | uniq -c | sort -rn | sed 's/^/  /'
