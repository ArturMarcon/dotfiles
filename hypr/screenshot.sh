#!/usr/bin/env bash

# Screenshot save folder
SAVE_DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
FILENAME="${SAVE_DIR}/Screenshot_${TIMESTAMP}.png"

MODE="${1:-region}"

case "$MODE" in
    region|area)
        # Select an area or window interactively using slurp
        GEOM=$(slurp)
        [ -z "$GEOM" ] && exit 0
        sleep 0.1
        grim -g "$GEOM" "$FILENAME"
        ;;
    window)
        # Capture the currently active window
        GEOM=$(hyprctl activewindow | awk '/at:/ {at=$2} /size:/ {size=$2; sub(",", "x", size); print at " " size; exit}')
        if [ -n "$GEOM" ]; then
            grim -g "$GEOM" "$FILENAME"
        else
            grim "$FILENAME"
        fi
        ;;
    full|fullscreen|*)
        # Capture entire screen
        grim "$FILENAME"
        ;;
esac

if [ -f "$FILENAME" ]; then
    # Copy to clipboard if wl-copy is installed
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy --type image/png < "$FILENAME"
    fi

    # Send notification with thumbnail preview
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Screenshot" -i "$FILENAME" "Screenshot Saved" "Saved to $(basename "$FILENAME")"
    fi
fi
