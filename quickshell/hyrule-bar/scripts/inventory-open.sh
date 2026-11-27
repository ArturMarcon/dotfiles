#!/usr/bin/env bash

# Open the Inventory file manager (Super+E, or `inv` in fish).
#
#   inventory-open.sh          open it at Home
#   inventory-open.sh PATH     open a folder, or a file's folder with the file selected
#   inventory-open.sh TAB      a tab by name or its start (projects, down, trash, ...),
#                              when there's no PATH by that name here
#
# Like a new Dolphin window, it opens on the workspace you're on and tiles
# there. Starts the Inventory's own Quickshell instance on first use, and
# falls back to Dolphin if that fails.

shell=$(realpath "$(dirname "$(realpath "$0")")/../inventory.qml")

places=(
    "Home:$HOME"
    "Desktop:$HOME/Desktop"
    "Downloads:$HOME/Downloads"
    "Documents:$HOME/Documents"
    "Pictures:$HOME/Pictures"
    "Music:$HOME/Music"
    "Videos:$HOME/Videos"
    "Projects:$HOME/Projects"
    "Trash:$HOME/.local/share/Trash/files"
)

fn=open
target=$HOME
if [ -n "${1:-}" ]; then
    if [ -e "$1" ]; then
        target=$(realpath -- "$1")
        [ -d "$target" ] || fn=reveal
    else
        want=${1,,}
        target=""
        for place in "${places[@]}"; do
            name=${place%%:*}
            if [[ ${name,,} == "$want"* ]]; then
                target=${place#*:}
                break
            fi
        done
        if [ -z "$target" ]; then
            echo "inv: no folder or tab called '$1'" >&2
            exit 1
        fi
    fi
fi

# The calls return nothing; any output ("Not ready to accept queries yet" while
# reloading, or no instance) means it didn't get through, whatever the exit code
call() {
    local out
    out=$(qs ipc -p "$shell" call inventory "$@" 2>&1) && [ -z "$out" ]
}

# Showing on another workspace: close it there, so it opens here instead
# (it comes back on the same folder)
elsewhere=$(hyprctl -j clients 2>/dev/null | python3 -c '
import json, sys
clients = json.load(sys.stdin)
here = int(sys.argv[1])
print("yes" if any(c["title"] == "Inventory" and c["class"] == "org.quickshell"
                   and c["workspace"]["id"] != here for c in clients) else "")
' "$(hyprctl -j activeworkspace 2>/dev/null | python3 -c 'import json, sys; print(json.load(sys.stdin)["id"])')" 2>/dev/null)
[ -n "$elsewhere" ] && call close

if ! call "$fn" "$target"; then
    qs -p "$shell" -n -d >/dev/null 2>&1   # -n: does nothing if it's already running
    opened=false
    # A running instance can be slow to answer right after a config reload,
    # so only give up on it (for Dolphin) once it has died
    for i in $(seq 150); do
        sleep 0.1
        if call "$fn" "$target"; then opened=true; break; fi
        if [ "$i" -ge 30 ] && ! pgrep -f -- "qs -p $shell" >/dev/null; then break; fi
    done
    if ! $opened; then
        exec dolphin ${target:+"$target"}
    fi
fi

hyprctl dispatch 'hl.dsp.focus({ window = "title:^Inventory$" })' >/dev/null 2>&1
exit 0
