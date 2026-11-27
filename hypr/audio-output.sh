#!/usr/bin/env bash

# Switch audio output between the headset and the laptop speakers.
# Usage: audio-output.sh [toggle|headset|speaker|status]
# The top bar's output slot runs `toggle` on click and `status` to pick its icon.

# Sinks are matched by part of their name, so they survive replugging the receiver
HEADSET_MATCH="Dell_HR024"
SPEAKER_MATCH="HiFi__Speaker__sink"

find_sink() {
    pactl list short sinks | awk -v m="$1" 'index($2, m) { print $2; exit }'
}

current() {
    case "$(pactl get-default-sink)" in
        *"$HEADSET_MATCH"*) echo headset ;;
        *) echo speaker ;;
    esac
}

switch_to() {
    local match label sink
    if [ "$1" = headset ]; then
        match="$HEADSET_MATCH"; label="Headset"
    else
        match="$SPEAKER_MATCH"; label="Speakers"
    fi

    sink=$(find_sink "$match")
    if [ -z "$sink" ]; then
        notify-send -a "Hyrule" "$label not found" "Is the device connected?"
        exit 1
    fi

    pactl set-default-sink "$sink"
    # Bring along anything already playing, including streams pinned to the old output
    pactl list short sink-inputs | cut -f1 | while read -r id; do
        pactl move-sink-input "$id" "$sink"
    done
}

case "${1:-toggle}" in
    status)  current ;;
    headset) switch_to headset ;;
    speaker) switch_to speaker ;;
    toggle)
        if [ "$(current)" = headset ]; then switch_to speaker; else switch_to headset; fi
        ;;
    *)
        echo "Usage: $0 [toggle|headset|speaker|status]" >&2
        exit 2
        ;;
esac
