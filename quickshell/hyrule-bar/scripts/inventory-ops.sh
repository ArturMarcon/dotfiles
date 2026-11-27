#!/usr/bin/env bash

# File operations and thumbnails for the Inventory file manager (InventoryView.qml).
# Every command prints a short error on stderr and exits non-zero on failure.
# Commands that change things print what they did on stdout, one line per
# item, so the Inventory can undo them.
#
#   thumb   SRC OUT KIND            render a thumbnail (pdf|video|audio|image) into OUT
#   paste   copy|move|link DEST SRC...   never overwrites; prints "MODE<tab>SRC<tab>TARGET"
#   paste-clipboard DEST            paste the files on the Wayland clipboard (moves
#                                   them if Dolphin cut them); prints like paste
#   rename  SRC NEWNAME             prints the new path
#   rename-many PATTERN SRC...      "#" in PATTERN becomes 1, 2, 3...; prints like paste
#   move-back TARGET<tab>SRC...     undo a move or rename, refusing to overwrite
#   mkdir   DEST NAME               prints the new folder's path
#   touch   DEST NAME               a new empty file; prints its path
#   extract DEST ARCHIVE...         into a folder named after the archive, or just the
#                                   one thing inside it if that's all there is; prints paths
#   compress zip|tar.gz DEST SRC... prints the archive's path
#   trash   PATH...                 prints each one's name inside the Trash
#   restore NAME...                 names inside the Trash; prints where each went back to
#   purge   NAME...                 delete from the Trash for good
#   empty-trash
#   apps    FILE                    "D<tab>id" for the default app, "R<tab>id" for the others
#   launch  DESKTOP-ID FILE...      open files with that app
#   resolve PATH                    prints "d<tab>PATH" or "f<tab>PATH" for an existing path
#   search  DIR QUERY HIDDEN(0|1)   "type<tab>size<tab>mtime<tab>path" for matches below DIR
#   props   PATH                    "permissions<tab>owner"
#   du      PATH                    total size in bytes (gives up on huge trees)
#   eject   MOUNTPOINT
#   df      PATH                    prints "total available" in bytes

set -u

trash_dir=${XDG_DATA_HOME:-$HOME/.local/share}/Trash

# "name.ext" -> "name (2).ext", "name (3).ext", ... until it is free
unique() {
    local target=$1
    [ -e "$target" ] || [ -L "$target" ] || { printf '%s' "$target"; return; }
    local dir base ext n=2
    dir=$(dirname "$target"); base=$(basename "$target")
    if [[ "$base" == ?*.* && ! -d "$target" ]]; then
        ext=".${base##*.}"; base="${base%.*}"
    else
        ext=""
    fi
    while [ -e "$dir/$base ($n)$ext" ] || [ -L "$dir/$base ($n)$ext" ]; do n=$((n + 1)); done
    printf '%s' "$dir/$base ($n)$ext"
}

# A name inside the Trash, checked so it can't point anywhere else
trash_item() {
    [[ -n "$1" && "$1" != */* && "$1" != . && "$1" != .. ]] || { echo "Not a Trash item: $1" >&2; return 1; }
    [ -e "$trash_dir/files/$1" ] || [ -L "$trash_dir/files/$1" ] || { echo "$1 isn't in the Trash" >&2; return 1; }
}

# The name each just-trashed path got inside the Trash (newest match wins)
trashed_names() {
    python3 - "$trash_dir/info" "$@" <<'EOF'
import glob, os, sys, urllib.parse
info, wanted = sys.argv[1], sys.argv[2:]
found = {}
for f in glob.glob(os.path.join(info, "*.trashinfo")):
    try:
        with open(f) as fh:
            for line in fh:
                if line.startswith("Path="):
                    path = urllib.parse.unquote(line[5:].strip())
                    m = os.path.getmtime(f)
                    if path in wanted and (path not in found or m > found[path][0]):
                        found[path] = (m, os.path.basename(f)[:-len(".trashinfo")])
                    break
    except OSError:
        pass
for w in wanted:
    if w in found:
        print(found[w][1])
EOF
}

# Where a Trash item came from
trash_origin() {
    python3 - "$trash_dir/info/$1.trashinfo" <<'EOF'
import sys, urllib.parse
try:
    for line in open(sys.argv[1]):
        if line.startswith("Path="):
            print(urllib.parse.unquote(line[5:].strip()))
            break
except OSError:
    pass
EOF
}

# "photos.tar.gz" -> "photos"
archive_stem() {
    local name=$1
    for ext in .tar.gz .tar.xz .tar.bz2 .tar.zst .tar.lz4 .tgz .tbz2 .txz .zip .7z .rar .tar .gz .xz .bz2 .zst .lz4 .deb .rpm .iso .cbz .cbr; do
        if [[ "${name,,}" == *"$ext" && ${#name} -gt ${#ext} ]]; then
            printf '%s' "${name:0:${#name}-${#ext}}"
            return
        fi
    done
    printf '%s' "${name%.*}"
}

do_paste() {
    local mode=$1 dest=$2; shift 2
    local status=0 src name target
    for src in "$@"; do
        [ -e "$src" ] || [ -L "$src" ] || { echo "Missing: $src" >&2; status=1; continue; }
        name=$(basename "$src")
        if [ "$mode" = move ] && [ "$(dirname "$(realpath -s "$src")")" = "$(realpath "$dest")" ]; then
            continue    # already here
        fi
        if [ "$mode" != link ]; then
            case "$(realpath "$dest")/" in
                "$(realpath "$src")"/*) echo "Can't put $name inside itself" >&2; status=1; continue ;;
            esac
        fi
        target=$(unique "$dest/$name")
        case "$mode" in
            move) mv -n -- "$src" "$target" || { status=1; continue; } ;;
            copy) cp -a -- "$src" "$target" || { status=1; continue; } ;;
            link) ln -s -- "$(realpath -s "$src")" "$target" || { status=1; continue; } ;;
        esac
        printf '%s\t%s\t%s\n' "$mode" "$src" "$target"
    done
    return $status
}

cmd=${1:-}
shift || true

case "$cmd" in
    thumb)
        src=$1 out=$2 kind=$3
        [ -s "$out" ] && exit 0
        [ -e "$out.none" ] && exit 1
        mkdir -p "$(dirname "$out")"
        tmp="$out.tmp.$$"
        case "$kind" in
            pdf)
                timeout 20 pdftoppm -png -singlefile -f 1 -l 1 -scale-to 384 "$src" "$tmp" 2>/dev/null \
                    && mv "$tmp.png" "$out" ;;
            video)
                timeout 20 ffmpeg -v error -y -ss 4 -i "$src" -frames:v 1 -vf "scale=384:-2" -f image2 "$tmp.png" 2>/dev/null
                [ -s "$tmp.png" ] || timeout 20 ffmpeg -v error -y -i "$src" -frames:v 1 -vf "scale=384:-2" -f image2 "$tmp.png" 2>/dev/null
                [ -s "$tmp.png" ] && mv "$tmp.png" "$out" ;;
            image)
                # Formats Qt can't decode itself (webp, heic, ...)
                timeout 20 ffmpeg -v error -y -i "$src" -frames:v 1 -vf "scale='min(384,iw)':-2" -f image2 "$tmp.png" 2>/dev/null
                [ -s "$tmp.png" ] && mv "$tmp.png" "$out" ;;
            audio)
                # Embedded cover art, if the file has any
                timeout 20 ffmpeg -v error -y -i "$src" -an -frames:v 1 -vf "scale=384:-2" -f image2 "$tmp.png" 2>/dev/null \
                    && [ -s "$tmp.png" ] && mv "$tmp.png" "$out" ;;
        esac
        rm -f "$tmp" "$tmp.png"
        if [ -s "$out" ]; then exit 0; fi
        touch "$out.none"   # remember there is nothing to show
        exit 1
        ;;

    paste)
        mode=$1; shift
        do_paste "$mode" "$@"
        ;;

    paste-clipboard)
        dest=$1
        types=$(wl-paste --list-types 2>/dev/null)
        grep -qx 'text/uri-list' <<<"$types" || { echo "No files on the clipboard" >&2; exit 1; }
        mapfile -t paths < <(wl-paste --type text/uri-list | tr -d '\r' | grep '^file://' \
            | python3 -c 'import sys, urllib.parse; [print(urllib.parse.unquote(l.strip()[7:])) for l in sys.stdin if l.strip()]')
        [ ${#paths[@]} -gt 0 ] || { echo "No files on the clipboard" >&2; exit 1; }
        mode=copy
        # Dolphin marks a cut with this type
        if grep -qx 'application/x-kde-cutselection' <<<"$types" \
            && [ "$(wl-paste --type application/x-kde-cutselection 2>/dev/null)" = 1 ]; then
            mode=move
        fi
        do_paste "$mode" "$dest" "${paths[@]}"
        ;;

    rename)
        src=$1 new=$2
        [[ "$new" == */* || -z "$new" ]] && { echo "A name can't contain /" >&2; exit 1; }
        target="$(dirname "$src")/$new"
        [ "$target" = "$src" ] && { printf '%s\n' "$target"; exit 0; }
        [ -e "$target" ] && { echo "$new already exists" >&2; exit 1; }
        mv -n -- "$src" "$target" && printf '%s\n' "$target"
        ;;

    rename-many)
        pattern=$1; shift
        [[ "$pattern" == */* || -z "$pattern" ]] && { echo "A name can't contain /" >&2; exit 1; }
        [[ "$pattern" == *"#"* ]] || pattern="$pattern #"
        count=$#
        width=${#count}     # 1..9, 01..12, 001..120
        status=0 n=1
        for src in "$@"; do
            num=$(printf "%0${width}d" "$n"); n=$((n + 1))
            name=${pattern//#/$num}
            # Keep each file's own extension unless the pattern gave one
            if [ ! -d "$src" ] && [[ "$name" != *.* ]] && [[ "$(basename "$src")" == ?*.* ]]; then
                name="$name.${src##*.}"
            fi
            target="$(dirname "$src")/$name"
            [ "$target" = "$src" ] && continue
            if [ -e "$target" ]; then echo "$name already exists" >&2; status=1; continue; fi
            mv -n -- "$src" "$target" && printf 'move\t%s\t%s\n' "$src" "$target" || status=1
        done
        exit $status
        ;;

    move-back)
        status=0
        for pair in "$@"; do
            from=${pair%%$'\t'*} to=${pair#*$'\t'}
            if [ -e "$to" ] || [ -L "$to" ]; then echo "$(basename "$to") is back already" >&2; status=1; continue; fi
            mv -n -- "$from" "$to" || status=1
        done
        exit $status
        ;;

    mkdir)
        dest=$1 name=$2
        [[ "$name" == */* || -z "$name" ]] && { echo "A name can't contain /" >&2; exit 1; }
        target=$(unique "$dest/$name")
        mkdir -- "$target" && printf '%s\n' "$target"
        ;;

    touch)
        dest=$1 name=$2
        [[ "$name" == */* || -z "$name" ]] && { echo "A name can't contain /" >&2; exit 1; }
        target=$(unique "$dest/$name")
        (set -C; : > "$target") && printf '%s\n' "$target"
        ;;

    extract)
        dest=$1; shift
        status=0
        for archive in "$@"; do
            name=$(basename "$archive")
            stem=$(archive_stem "$name")
            lower=${name,,}
            case "$lower" in
                *.tar.*|*.tgz|*.tbz2|*.txz|*.zip|*.7z|*.rar|*.tar|*.deb|*.rpm|*.iso|*.cbz|*.cbr)
                    tmp=$(mktemp -d "$dest/.inventory-extract-XXXXXX") || { status=1; continue; }
                    if ! bsdtar -xf "$archive" -C "$tmp" 2>/dev/null; then
                        echo "Couldn't unpack $name" >&2
                        rm -rf -- "$tmp"
                        status=1
                        continue
                    fi
                    shopt -s nullglob dotglob
                    entries=("$tmp"/*)
                    shopt -u nullglob dotglob
                    if [ ${#entries[@]} -eq 1 ]; then
                        # Just one thing inside: no extra folder around it
                        target=$(unique "$dest/$(basename "${entries[0]}")")
                        mv -n -- "${entries[0]}" "$target" && rmdir -- "$tmp"
                    else
                        target=$(unique "$dest/$stem")
                        mv -n -- "$tmp" "$target"
                    fi
                    printf '%s\n' "$target"
                    ;;
                *.gz|*.xz|*.bz2|*.zst|*.lz4)
                    # A single compressed file
                    target=$(unique "$dest/$stem")
                    case "$lower" in
                        *.gz) tool=(gzip -dc) ;;
                        *.xz) tool=(xz -dc) ;;
                        *.bz2) tool=(bzip2 -dc) ;;
                        *.zst) tool=(zstd -dcq) ;;
                        *.lz4) tool=(lz4 -dc) ;;
                    esac
                    if "${tool[@]}" -- "$archive" > "$target" 2>/dev/null; then
                        printf '%s\n' "$target"
                    else
                        rm -f -- "$target"
                        echo "Couldn't unpack $name" >&2
                        status=1
                    fi
                    ;;
                *)
                    echo "$name isn't an archive I can open" >&2
                    status=1
                    ;;
            esac
        done
        exit $status
        ;;

    compress)
        fmt=$1 dest=$2; shift 2
        if [ $# -eq 1 ]; then
            base=$(basename "$1")
            [ -d "$1" ] || base=${base%.*}
            [ -n "$base" ] || base=$(basename "$1")
        else
            base=$(basename "$dest")
            [ "$dest" = / ] && base=Archive
        fi
        target=$(unique "$dest/$base.$fmt")
        # bsdtar picks the format from the name
        names=()
        for src in "$@"; do names+=(-C "$(dirname "$src")" "$(basename "$src")"); done
        if bsdtar -a -cf "$target" "${names[@]}" 2>/dev/null; then
            printf '%s\n' "$target"
        else
            rm -f -- "$target"
            echo "Couldn't make $(basename "$target")" >&2
            exit 1
        fi
        ;;

    trash)
        gio trash -- "$@" || exit 1
        trashed_names "$@"
        ;;

    # Restoring and deleting follow the freedesktop Trash layout directly
    # (gio only can with gvfs installed)
    restore)
        status=0
        for name in "$@"; do
            trash_item "$name" || { status=1; continue; }
            origin=$(trash_origin "$name")
            if [ -z "$origin" ]; then echo "Don't know where $name came from" >&2; status=1; continue; fi
            if [ -e "$origin" ] || [ -L "$origin" ]; then echo "$(basename "$origin") exists again where it was" >&2; status=1; continue; fi
            mkdir -p -- "$(dirname "$origin")" \
                && mv -n -- "$trash_dir/files/$name" "$origin" \
                && rm -f -- "$trash_dir/info/$name.trashinfo" \
                && printf '%s\n' "$origin" || status=1
        done
        exit $status
        ;;

    purge)
        status=0
        for name in "$@"; do
            trash_item "$name" || { status=1; continue; }
            rm -rf -- "${trash_dir:?}/files/$name" && rm -f -- "$trash_dir/info/$name.trashinfo" || status=1
        done
        exit $status
        ;;

    empty-trash)
        [ -d "$trash_dir/files" ] || exit 0
        find "${trash_dir:?}/files" "$trash_dir/info" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + \
            && rm -f -- "$trash_dir/directorysizes"
        ;;

    apps)
        mime=$(xdg-mime query filetype "$1" 2>/dev/null)
        [ -n "$mime" ] || exit 0
        gio mime "$mime" 2>/dev/null | awk '
            /^Default application/ { if (match($0, /: [^ ]+\.desktop/)) print "D\t" substr($0, RSTART + 2, RLENGTH - 2); next }
            /^[A-Z]/ { next }
            /\.desktop/ { gsub(/^[ \t]+/, ""); print "R\t" $0 }
        ' | awk '!seen[$2]++'
        ;;

    launch)
        id=$1; shift
        for dir in "${XDG_DATA_HOME:-$HOME/.local/share}" ${XDG_DATA_DIRS//:/ } /usr/local/share /usr/share; do
            desktop="$dir/applications/$id"
            [ -f "$desktop" ] && exec gio launch "$desktop" "$@"
        done
        echo "Can't find $id" >&2
        exit 1
        ;;

    resolve)
        target=$(realpath -e -- "${1/#\~/$HOME}" 2>/dev/null) || { echo "Nothing at $1" >&2; exit 1; }
        if [ -d "$target" ]; then printf 'd\t%s\n' "$target"; else printf 'f\t%s\n' "$target"; fi
        ;;

    search)
        dir=$1 query=$2 hidden=${3:-0}
        # Glob characters in the query are meant literally
        pat=$(printf '%s' "$query" | sed 's/[][*?\\]/\\&/g')
        if [ "$hidden" = 1 ]; then
            timeout 20 find "$dir" -xdev -mindepth 1 -iname "*$pat*" -printf '%Y\t%s\t%T@\t%p\n' 2>/dev/null | head -n 2000
        else
            timeout 20 find "$dir" -xdev -mindepth 1 -name '.*' -prune -o -iname "*$pat*" -printf '%Y\t%s\t%T@\t%p\n' 2>/dev/null | head -n 2000
        fi
        exit 0
        ;;

    props)
        stat --printf '%A\t%U\n' -- "$1"
        ;;

    du)
        out=$(timeout 8 nice -n 19 du -sb -- "$1" 2>/dev/null | cut -f1)
        [ -n "$out" ] || exit 1
        printf '%s\n' "$out"
        ;;

    eject)
        gio mount -e "$1" 2>/dev/null || gio mount -u "$1"
        ;;

    df)
        df -B1 --output=size,avail -- "$1" | tail -1
        ;;

    *)
        echo "Unknown command: $cmd" >&2
        exit 2
        ;;
esac
