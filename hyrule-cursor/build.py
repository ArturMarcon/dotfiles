#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow>=10"]
# ///
"""Build the Hyrule XCursor theme into ~/.local/share/icons/Hyrule.

Each cursor is an SVG on a 32x32 grid, rendered with rsvg-convert at every
nominal size and packed into XCursor files. Cursors not drawn here fall back
to breeze_cursors (see index.theme).
"""

import io
import math
import os
import pathlib
import shutil
import struct
import subprocess

from PIL import Image

OUT = pathlib.Path.home() / ".local/share/icons/Hyrule"
SIZES = [24, 32, 48, 64]

# Glazed-ceramic slab: cream face, tan side, red Sheikah emblem
FACE_LIGHT = "#fcf7ee"
FACE = "#f0e4cf"
FACE_SHADE = "#d6b792"
BEVEL = "#a5754d"
BEVEL_DARK = "#6f4a2f"
SIDE = "#bf9672"
RED = "#a51c05"
# Clickable: the eye wakes up Sheikah blue, like a shrine switching on
SHEIKAH = "#1386dc"
SHEIKAH_GLOW = "#4fd2ff"

DEFS = f"""<defs>
  <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
    <feGaussianBlur in="SourceAlpha" stdDeviation="1"/>
    <feOffset dx="0.6" dy="1.3"/>
    <feComponentTransfer><feFuncA type="linear" slope="0.45"/></feComponentTransfer>
    <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
    <feGaussianBlur stdDeviation="9"/>
  </filter>
  <filter id="aura" x="-50%" y="-50%" width="200%" height="200%">
    <feGaussianBlur stdDeviation="16"/>
  </filter>
  <linearGradient id="pickface" x1="0.85" y1="0" x2="0.3" y2="1">
    <stop offset="0" stop-color="{FACE_LIGHT}"/>
    <stop offset="0.45" stop-color="#f2e7d6"/>
    <stop offset="0.8" stop-color="#dcc0a0"/>
    <stop offset="1" stop-color="#c9a37f"/>
  </linearGradient>
  <linearGradient id="face" x1="1" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{FACE_LIGHT}"/>
    <stop offset="0.5" stop-color="{FACE}"/>
    <stop offset="1" stop-color="{FACE_SHADE}"/>
  </linearGradient>
</defs>"""

# The pick and its emblem are traced on the reference artwork's pixel grid
# (tip near 40,16) and scaled onto the 32-unit cursor grid
REF = "translate(3.2 2.8) scale(0.0833) translate(-40 -16)"
# Slightly concave sides, like a guitar pick
PICK = "M52 28 Q174 90 296 138 Q205 190 142 272 Q110 148 52 28 Z"
MOVE = ("M16 3.2 L20.4 8.4 H17.7 V14.3 H23.6 V11.6 L28.8 16 L23.6 20.4 V17.7 H17.7 V23.6 H20.4 "
        "L16 28.8 L11.6 23.6 H14.3 V17.7 H8.4 V20.4 L3.2 16 L8.4 11.6 V14.3 H14.3 V8.4 H11.6 Z")
DOUBLE = "M16 3.5 L22 10.6 H18.1 V21.4 H22 L16 28.5 L10 21.4 H13.9 V10.6 H10 Z"
CELL = "M13 4.5 H19 V13 H27.5 V19 H19 V27.5 H13 V19 H4.5 V13 H13 Z"
IBEAM = "M11.5 5.5 Q16 5.5 16 8.5 Q16 5.5 20.5 5.5 M16 8.5 V23.5 M11.5 26.5 Q16 26.5 16 23.5 Q16 26.5 20.5 26.5"


def svg(body: str) -> str:
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">{DEFS}<g filter="url(#shadow)">{body}</g></svg>'


def slab(path: str, transform: str = "", rounding: float = 2.6) -> str:
    """A thick ceramic piece: bevel showing below, rounded cream face on top.
    The bevel offset stays in screen space so light comes from the same side."""
    t = f' transform="{transform}"' if transform else ""
    return (f'<g transform="translate(0.3 2.2)"><path d="{path}"{t} fill="{BEVEL_DARK}" stroke="{BEVEL_DARK}" '
            f'stroke-width="{rounding + 1}" stroke-linejoin="round"/></g>'
            f'<g transform="translate(0.15 1.1)"><path d="{path}"{t} fill="{BEVEL}" stroke="{BEVEL}" '
            f'stroke-width="{rounding + 0.6}" stroke-linejoin="round"/></g>'
            f'<path d="{path}"{t} fill="none" stroke="{BEVEL_DARK}" stroke-width="{rounding + 0.9}" stroke-linejoin="round" opacity="0.55"/>'
            f'<path d="{path}"{t} fill="url(#face)" stroke="url(#face)" stroke-width="{rounding}" stroke-linejoin="round"/>')


def emblem(color: str) -> str:
    """Sheikah eye on the reference grid: teardrop and stem, inner ring, an outer
    ring open on the right with a hook and crescent, a curl, three arrowheads.
    Strokes are a little heavier than the artwork so it survives at 24px."""
    return (f'<g fill="none" stroke="{color}" stroke-width="13" stroke-linecap="round">'
            f'<circle cx="150" cy="130" r="27"/>'
            f'<path d="M188.5 157 A47 47 0 1 1 169.9 87.4 C182 82 193 77 202 80 C209 82 212 87 211 93"/>'
            f'<path d="M121 101 Q98 82 78 63" stroke-width="10"/>'
            f'<path d="M107 158 C102 174 104 186 115 191" stroke-width="10"/>'
            f'</g>'
            f'<g fill="{color}">'
            f'<ellipse cx="70" cy="55" rx="15" ry="11.5" transform="rotate(40 70 55)"/>'
            f'<path d="M183 87 C202 97 205 128 186 143 C194 124 193 104 183 87 Z"/>'
            f'<path d="M212 101 L242 128 L210 144 Z"/>'
            f'<path d="M204 155 L219 197 L172 186 Z"/>'
            f'<path d="M123 192 L164 192 L150 220 Z"/>'
            f'</g>')


def pick(active: bool = False) -> str:
    """The ceramic pick: a wide tan side face down the left, cream top, gloss on the top edge.
    Active (something clickable underneath): blue aura and a glowing blue eye."""
    rounding = 'stroke-width="30" stroke-linejoin="round"'
    aura = (f'<path d="{PICK}" fill="{SHEIKAH_GLOW}" stroke="{SHEIKAH_GLOW}" stroke-width="56" stroke-linejoin="round" '
            f'filter="url(#aura)"/>') if active else ""
    body = (f'<path d="{PICK}" transform="translate(-14 26)" fill="{BEVEL_DARK}" stroke="{BEVEL_DARK}" {rounding}/>'
            f'<path d="{PICK}" transform="translate(-17 15)" fill="{SIDE}" stroke="{SIDE}" {rounding}/>'
            f'<path d="{PICK}" fill="url(#pickface)" stroke="url(#pickface)" {rounding}/>'
            f'<path d="M58 22 L268 116" stroke="#ffffff" stroke-width="8" stroke-linecap="round" opacity="0.75"/>')
    if active:
        mark = f'<g filter="url(#glow)">{emblem(SHEIKAH_GLOW)}</g>' + emblem(SHEIKAH)
    else:
        mark = emblem(RED)
    return f'<g transform="{REF}">{aura}{body}{mark}</g>'


def outlined(d: str, color: str = FACE, width: float = 1.9, extra: str = "") -> str:
    return (f'<path d="{d}" fill="none" stroke="{BEVEL_DARK}" stroke-width="{width + 2}" '
            f'stroke-linecap="round" stroke-linejoin="round" {extra}/>'
            f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
            f'stroke-linecap="round" stroke-linejoin="round" {extra}/>')


def spinner(cx: float, cy: float, r: float, angle: float, width: float) -> str:
    """Ceramic ring with a red arc turning around it."""
    circ = 2 * math.pi * r
    return (f'<circle cx="{cx + 0.2}" cy="{cy + 1.2}" r="{r}" fill="none" stroke="{BEVEL_DARK}" stroke-width="{width + 1.2}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{BEVEL}" stroke-width="{width + 1.2}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{FACE}" stroke-width="{width}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{RED}" stroke-width="{width * 0.55}" stroke-linecap="round" '
            f'stroke-dasharray="{circ * 0.3:.2f} {circ:.2f}" transform="rotate({angle - 90} {cx} {cy})"/>')


def badge(cx: float, cy: float, inner: str) -> str:
    return (f'<circle cx="{cx + 0.2}" cy="{cy + 1}" r="5.6" fill="{BEVEL_DARK}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="5.6" fill="url(#face)" stroke="{BEVEL}" stroke-width="0.8"/>' + inner)


# Small red marks for the badge in the pick's lower right (centred on 23.6,23.4)
PLUS = f'<path d="M23.6 20.7 V26.1 M20.9 23.4 H26.3" stroke="{RED}" stroke-width="1.7" stroke-linecap="round"/>'
LINK = (f'<path d="M21.3 26 Q21.3 21.9 25.2 21.9" fill="none" stroke="{RED}" stroke-width="1.5" stroke-linecap="round"/>'
        f'<path d="M23.9 20.2 L26.4 21.9 L23.9 23.6 Z" fill="{RED}"/>')
MENU = f'<path d="M21 21.3 H26.2 M21 23.4 H26.2 M21 25.5 H26.2" stroke="{RED}" stroke-width="1.2" stroke-linecap="round"/>'
DRAG = f'<path d="M23.6 19.8 L24.6 22.4 L27.2 23.4 L24.6 24.4 L23.6 27 L22.6 24.4 L20 23.4 L22.6 22.4 Z" fill="{RED}"/>'


def magnifier(zoom_in: bool) -> str:
    """Ceramic magnifying glass with a red + or -."""
    mark = "M10.2 13 H15.8" + (" M13 10.2 V15.8" if zoom_in else "")
    return (outlined("M18.4 18.4 L26 26", FACE, 3.2)
            + outlined("M13 6 A7 7 0 1 1 12.99 6 Z", FACE, 2.6)
            + f'<circle cx="13" cy="13" r="5.7" fill="{FACE_LIGHT}" fill-opacity="0.6"/>'
            + f'<path d="{mark}" stroke="{RED}" stroke-width="1.8" stroke-linecap="round"/>')


SPIN_FRAMES = 16
SPIN_DELAY = 55  # ms

HOT = (3.4, 2.9)  # tip of the pick
# name -> (frames as SVG strings, hotspot on the 32 grid, aliases)
CURSORS = {
    "default": ([svg(pick())], HOT,
                ["left_ptr", "arrow", "top_left_arrow", "left_arrow"]),
    "pointer": ([svg(pick(active=True))], HOT,
                ["hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822"]),
    "text": ([svg(outlined(IBEAM) + f'<path d="M14.6 16 H17.4" stroke="{RED}" stroke-width="1.4" stroke-linecap="round"/>')],
             (16, 16), ["xterm", "ibeam"]),
    "vertical-text": ([svg(outlined(IBEAM, extra='transform="rotate(90 16 16)"')
                           + f'<path d="M16 14.6 V17.4" stroke="{RED}" stroke-width="1.4" stroke-linecap="round"/>')],
                      (16, 16), []),
    "context-menu": ([svg(pick() + badge(23.6, 23.4, MENU))], HOT, ["08ffe1cb5fe6fc01f906f1c063814ccf"]),
    "copy": ([svg(pick() + badge(23.6, 23.4, PLUS))], HOT,
             ["dnd-copy", "1081e37283d90000800003c07f3ef6bf", "6407b0e94181790501fd1e167b474872", "b66166c04f8c3109214a4fbd64a50fc8"]),
    "alias": ([svg(pick() + badge(23.6, 23.4, LINK))], HOT,
              ["link", "dnd-link", "3085a0e285430894940527032f8b26df", "640fb0e74195791501fd1ed57b41487f", "a2a266d0498c3104214a47bd64ab0fc8"]),
    "grab": ([svg(pick() + badge(23.6, 23.4, DRAG))], HOT, ["openhand", "5aca4d189052212118709018842178c0"]),
    # Holding: the eye lights up while something is being dragged
    "grabbing": ([svg(pick(active=True) + badge(23.6, 23.4, DRAG))], HOT,
                 ["closedhand", "dnd-move", "dnd-none", "208530c400c041818281048008011002"]),
    "zoom-in": ([svg(magnifier(True))], (13, 13), []),
    "zoom-out": ([svg(magnifier(False))], (13, 13), []),
    "cell": ([svg(slab(CELL, rounding=1.4) + f'<circle cx="16" cy="16" r="1.4" fill="{RED}"/>')], (16, 16), ["plus"]),
    "crosshair": ([svg(outlined("M16 3.5 V12 M16 20 V28.5 M3.5 16 H12 M20 16 H28.5")
                       + f'<path d="M16 13.5 L18.5 16 L16 18.5 L13.5 16 Z" fill="{RED}" stroke="{BEVEL_DARK}" stroke-width="0.7"/>')],
                  (16, 16), ["cross", "tcross", "cross_reverse", "diamond_cross"]),
    "not-allowed": ([svg(f'<circle cx="16" cy="16" r="9.3" fill="{FACE}" fill-opacity="0.85"/>'
                         + outlined("M16 6.7 A9.3 9.3 0 1 1 15.99 6.7 Z M9.4 9.4 L22.6 22.6", RED, 2.4))], (16, 16),
                    ["crossed_circle", "forbidden", "no-drop", "circle", "dnd-no-drop", "03b6e0fcb3499374a867c041f52298f0"]),
    "help": ([svg(pick() + badge(23.6, 23.4, f'<text x="23.6" y="27.1" font-family="Noto Serif" font-weight="bold" '
                                            f'font-size="10" text-anchor="middle" fill="{RED}">?</text>'))],
             HOT, ["question_arrow", "whats_this", "left_ptr_help", "5c6cd98b3f3ebcb1f9c7f1c204630408", "d9ce0ab605698f320427677b458ad60b"]),
    "move": ([svg(slab(MOVE, rounding=1.6) + f'<circle cx="16" cy="16" r="1.7" fill="{RED}"/>')], (16, 16),
             ["fleur", "all-scroll", "size_all",
              "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f", "fcf21c00b30f7e3f83fe0dfd12e71cff"]),
    "ns-resize": ([svg(slab(DOUBLE, rounding=1.6))], (16, 16),
                  ["n-resize", "s-resize", "row-resize", "size_ver", "v_double_arrow", "sb_v_double_arrow", "top_side",
                   "bottom_side", "double_arrow", "00008160000006810000408080010102", "2870a09082c103050810ffdffffe0204"]),
    "ew-resize": ([svg(slab(DOUBLE, "rotate(90 16 16)", rounding=1.6))], (16, 16),
                  ["e-resize", "w-resize", "col-resize", "size_hor", "h_double_arrow", "sb_h_double_arrow", "left_side",
                   "right_side", "028006030e0e7ebffc7f7070c0600140", "14fef782d02440884392942c11205230"]),
    "nwse-resize": ([svg(slab(DOUBLE, "rotate(-45 16 16)", rounding=1.6))], (16, 16),
                    ["nw-resize", "se-resize", "size_fdiag", "bd_double_arrow", "top_left_corner", "bottom_right_corner",
                     "c7088f0f3e6c8088236ef8e1e3e70000"]),
    "nesw-resize": ([svg(slab(DOUBLE, "rotate(45 16 16)", rounding=1.6))], (16, 16),
                    ["ne-resize", "sw-resize", "size_bdiag", "fd_double_arrow", "top_right_corner", "bottom_left_corner",
                     "fcf1c3c7cd4491d801f1e1c78f100000"]),
    "wait": ([svg(spinner(16, 15.5, 8.6, i * 360 / SPIN_FRAMES, 3.6)) for i in range(SPIN_FRAMES)], (16, 16), ["watch"]),
    "progress": ([svg(pick() + spinner(24, 23.6, 4.2, i * 360 / SPIN_FRAMES, 2.4)) for i in range(SPIN_FRAMES)], HOT,
                 ["left_ptr_watch", "half-busy", "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"]),
}


def render(svg_text: str, size: int) -> Image.Image:
    png = subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size)],
                         input=svg_text.encode(), capture_output=True, check=True).stdout
    return Image.open(io.BytesIO(png)).convert("RGBA")


def xcursor(frames: list[str], hotspot: tuple[float, float]) -> bytes:
    """Pack frames at every size into the XCursor format (premultiplied ARGB32)."""
    images = []
    for size in SIZES:
        hx = min(size - 1, round(hotspot[0] * size / 32))
        hy = min(size - 1, round(hotspot[1] * size / 32))
        for frame in frames:
            # "RGBa" is premultiplied; BGRA byte order is ARGB32 little-endian
            pixels = render(frame, size).convert("RGBa").tobytes("raw", "BGRa")
            delay = SPIN_DELAY if len(frames) > 1 else 0
            header = struct.pack("<9I", 36, 0xFFFD0002, size, 1, size, size, hx, hy, delay)
            images.append((size, header + pixels))

    toc_end = 16 + 12 * len(images)
    out = struct.pack("<4sIII", b"Xcur", 16, 0x10000, len(images))
    pos = toc_end
    for size, chunk in images:
        out += struct.pack("<III", 0xFFFD0002, size, pos)
        pos += len(chunk)
    return out + b"".join(chunk for _, chunk in images)


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    cursors = OUT / "cursors"
    cursors.mkdir(parents=True)
    theme = "[Icon Theme]\nName=Hyrule\nComment=Glazed ceramic cursors with the Sheikah eye\nInherits=breeze_cursors\n"
    (OUT / "index.theme").write_text(theme)
    (OUT / "cursor.theme").write_text(theme)

    for name, (frames, hotspot, aliases) in CURSORS.items():
        (cursors / name).write_bytes(xcursor(frames, hotspot))
        for alias in aliases:
            os.symlink(name, cursors / alias)
        print(f"{name:12} {len(frames):2} frame(s), {len(aliases)} aliases")


if __name__ == "__main__":
    main()
