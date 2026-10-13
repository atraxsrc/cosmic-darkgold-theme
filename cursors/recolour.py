#!/usr/bin/env python3
"""Recolour an Oxygen Xcursor theme to one palette colour.

    ./cursors/recolour.py --base cursors/Oxygen-DarkGold-Gold \
        --out cursors/Oxygen-Noir-Sage --name "Oxygen Noir Sage" \
        --colour '#88A57D' --preview assets/cursors/Oxygen-Noir-Sage.png --bg '#171717'

Every body pixel keeps its shading but takes the hue and saturation of the
target colour; the white border, black outline and drop shadow are left alone.
Symlinks in the base theme (the COSMIC cursor-name fix) are recreated as is.
Pure Python, no dependencies. Xcursor files are rewritten in place of their
pixel data only, so hotspots, sizes and animation delays are untouched.
"""
import argparse
import colorsys
import os
import shutil
import struct
import sys
import zlib

IMAGE_TYPE = 0xFFFD0002
BODY_SAT = 0.12       # below this a pixel is outline / border / shadow, not body
SPREAD = 0.18         # the body gradient spans target lightness +- this


def parse_hex(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) / 255 for i in (0, 2, 4))


def chunks(data):
    """Yield (offset_of_pixels, width, height) for every image chunk."""
    magic, _hdr, _ver, ntoc = struct.unpack_from("<4sIII", data, 0)
    if magic != b"Xcur":
        raise ValueError("not an Xcursor file")
    for i in range(ntoc):
        typ, _sub, pos = struct.unpack_from("<III", data, 16 + 12 * i)
        if typ != IMAGE_TYPE:
            continue
        w, h = struct.unpack_from("<II", data, pos + 16)
        yield pos + 36, w, h


def pixels(data, off, w, h):
    """Straight-alpha (r, g, b, a) floats 0..1 for one image chunk."""
    out = []
    for i in range(off, off + 4 * w * h, 4):
        b, g, r, a = data[i], data[i + 1], data[i + 2], data[i + 3]
        if a == 0:
            out.append((0.0, 0.0, 0.0, 0.0))
            continue
        out.append((min(1.0, r / a), min(1.0, g / a), min(1.0, b / a), a / 255))
    return out


def body_stats(data):
    """Lightness 5th/95th percentile and median saturation of the body pixels."""
    ls, ss = [], []
    for off, w, h in chunks(data):
        for r, g, b, a in pixels(data, off, w, h):
            if a < 0.95:
                continue
            hh, l, s = colorsys.rgb_to_hls(r, g, b)
            if s >= BODY_SAT:
                ls.append(l)
                ss.append(s)
    if not ls:
        sys.exit("base left_ptr has no saturated body pixels; pick a coloured base")
    ls.sort()
    ss.sort()
    return ls[len(ls) // 20], ls[-max(1, len(ls) // 20)], ss[len(ss) // 2]


def recolour_file(src, dst, target, stats):
    l1, l2, s_base = stats
    th, tl, ts = colorsys.rgb_to_hls(*target)
    lo, hi = max(0.04, tl - SPREAD), min(0.96, tl + SPREAD)
    data = bytearray(open(src, "rb").read())
    for off, w, h in chunks(data):
        px = pixels(data, off, w, h)
        for n, (r, g, b, a) in enumerate(px):
            if a == 0:
                continue
            hh, l, s = colorsys.rgb_to_hls(r, g, b)
            if s < BODY_SAT:
                continue
            t = (l - l1) / (l2 - l1) if l2 > l1 else 0.5
            nl = min(hi, max(lo, lo + t * (hi - lo)))
            ns = ts * min(1.0, s / s_base) if s_base else 0.0
            nr, ng, nb = colorsys.hls_to_rgb(th, nl, ns)
            i = off + 4 * n
            data[i] = round(nb * a * 255)
            data[i + 1] = round(ng * a * 255)
            data[i + 2] = round(nr * a * 255)
    with open(dst, "wb") as f:
        f.write(data)


def write_png(path, w, h, rows):
    """rows: list of bytes, each 3*w RGB."""
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(tag, body):
        c = struct.pack(">I", len(body)) + tag + body
        return c + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def preview(theme_dir, target, bg, path):
    """96x64 swatch: the 48 px arrow on the rice background, the colour beside it."""
    W, H = 96, 64
    canvas = [[bg for _ in range(W)] for _ in range(H)]
    data = open(os.path.join(theme_dir, "cursors", "left_ptr"), "rb").read()
    best = max(chunks(data), key=lambda c: c[1])
    off, w, h = best
    px = pixels(data, off, w, h)
    scale = 48 / w
    for y in range(48):
        for x in range(48):
            r, g, b, a = px[int(y / scale) * w + int(x / scale)]
            if a == 0:
                continue
            cy, cx = 8 + y, 8 + x
            br, bgc, bb = canvas[cy][cx]
            canvas[cy][cx] = (r * a + br * (1 - a), g * a + bgc * (1 - a), b * a + bb * (1 - a))
    for y in range(8, 56):
        for x in range(60, 88):
            canvas[y][x] = target
    rows = [bytes(round(c * 255) for p in row for c in p) for row in canvas]
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    write_png(path, W, H, rows)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", required=True, help="an Oxygen theme folder with a coloured body (any variant)")
    ap.add_argument("--out", required=True, help="theme folder to write; replaced if it exists")
    ap.add_argument("--name", required=True, help="Name= for index.theme, e.g. 'Oxygen Noir Sage'")
    ap.add_argument("--colour", required=True, help="target body colour, #RRGGBB")
    ap.add_argument("--preview", help="write a 96x64 PNG swatch here")
    ap.add_argument("--bg", default="#1B1B1B", help="background behind the preview arrow")
    a = ap.parse_args()

    target = parse_hex(a.colour)
    src_cur = os.path.join(a.base, "cursors")
    stats = body_stats(open(os.path.join(src_cur, "left_ptr"), "rb").read())

    if os.path.isdir(a.out):
        shutil.rmtree(a.out)
    dst_cur = os.path.join(a.out, "cursors")
    os.makedirs(dst_cur)
    comment = "Oxygen mouse theme. Oxygenize your desktop!"
    for line in open(os.path.join(a.base, "index.theme"), encoding="utf-8"):
        if line.startswith("Comment"):
            comment = line.split("=", 1)[1].strip()
    with open(os.path.join(a.out, "index.theme"), "w", encoding="utf-8") as f:
        f.write(f"[Icon Theme]\nName = {a.name}\nComment = {comment}\n")

    files = links = skipped = 0
    for n in sorted(os.listdir(src_cur)):
        s, d = os.path.join(src_cur, n), os.path.join(dst_cur, n)
        if os.path.islink(s):
            os.symlink(os.readlink(s), d)
            links += 1
            continue
        with open(s, "rb") as f:
            is_cursor = f.read(4) == b"Xcur"
        if not is_cursor:          # e.g. a stray KDE .directory file
            skipped += 1
            continue
        recolour_file(s, d, target, stats)
        files += 1
    if a.preview:
        preview(a.out, target, parse_hex(a.bg), a.preview)
    print(f"{a.out}: {files} cursors recoloured to {a.colour.upper()}, {links} symlinks kept")


if __name__ == "__main__":
    main()
