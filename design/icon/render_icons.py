"""Draws the Usisa app icon (mark D3) as PNGs from the same geometry as usisa-app-icon.svg.

Usage: python render_icons.py <android res dir> <preview dir>
Writes mipmap-*/ic_launcher.png (legacy launchers, Android 7 and older) and a 1024 px preview.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

INDIGO, WHITE, YELLOW, ORANGE = (74, 68, 201), (255, 255, 255), (255, 214, 107), (255, 138, 76)
SS = 4  # supersampling for smooth edges


def arc(cx, cy, r, a0, a1, n=96):
    """Points on a circle from angle a0 to a1 (radians, screen coordinates)."""
    return [(cx + r * math.cos(a0 + (a1 - a0) * i / n), cy + r * math.sin(a0 + (a1 - a0) * i / n)) for i in range(n + 1)]


def cubic(p0, p1, p2, p3, n=40):
    out = []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        out.append(tuple(mt**3 * a + 3 * mt * mt * t * b + 3 * mt * t * t * c + t**3 * d for a, b, c, d in zip(p0, p1, p2, p3)))
    return out


def ang(cx, cy, x, y):
    return math.atan2(y - cy, x - cx)


def mark_shapes():
    """Bubble, lens circle and overlap as polygons in the 256 mark space."""
    c1, r1 = (112, 144), 80
    # Bubble: the long way round the circle from (72,213.3) to (34.7,164.7), then the rounded tail back.
    a_start, a_end = ang(*c1, 72, 213.3), ang(*c1, 34.7, 164.7)
    # Counter-clockwise on screen (decreasing angle) the long way.
    while a_end > a_start:
        a_end -= 2 * math.pi
    bubble = arc(*c1, r1, a_start, a_end, 240)
    bubble += cubic((34.7, 164.7), (31, 186), (27, 206), (26, 220))
    # Tail tip: arc r 9 from (26,220) to (39,229), centre found from the two points (the side below the chord).
    (x0, y0), (x1, y1) = (26, 220), (39, 229)
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    half = math.dist((x0, y0), (x1, y1)) / 2
    off = math.sqrt(max(9 * 9 - half * half, 0))
    nx, ny = -(y1 - y0) / (2 * half), (x1 - x0) / (2 * half)
    cx, cy = mx - nx * off, my - ny * off
    t0, t1 = ang(cx, cy, x0, y0), ang(cx, cy, x1, y1)
    while t1 > t0:
        t1 -= 2 * math.pi
    bubble += arc(cx, cy, 9, t0, t1, 24)
    bubble += cubic((39, 229), (51, 225), (62, 220), (72, 213.3))
    c2, r2 = (177, 88), 70
    a, b = (111.24, 64.01), (191, 156.59)
    s0, s1 = ang(*c1, *a), ang(*c1, *b)
    while s1 < s0:
        s1 += 2 * math.pi
    u0, u1 = ang(*c2, *b), ang(*c2, *a)
    while u1 < u0:
        u1 += 2 * math.pi
    overlap = arc(*c1, r1, s0, s1) + arc(*c2, r2, u0, u1)
    return bubble, (c2, r2), overlap


def render(size, rounded=True):
    big = size * SS
    img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    k = big / 256
    if rounded:
        d.rounded_rectangle([0, 0, big - 1, big - 1], radius=56 * k, fill=INDIGO)
    else:
        d.rectangle([0, 0, big, big], fill=INDIGO)
    # Same transform as the SVG: translate(128 128) scale(.7) translate(-136 -126).
    def t(p):
        return ((128 + .7 * (p[0] - 136)) * k, (128 + .7 * (p[1] - 126)) * k)
    bubble, ((cx, cy), r), overlap = mark_shapes()
    d.polygon([t(p) for p in bubble], fill=WHITE)
    (x0, y0), (x1, y1) = t((cx - r, cy - r)), t((cx + r, cy + r))
    d.ellipse([x0, y0, x1, y1], fill=YELLOW)
    d.polygon([t(p) for p in overlap], fill=ORANGE)
    return img.resize((size, size), Image.LANCZOS)


def main():
    res, preview = Path(sys.argv[1]), Path(sys.argv[2])
    for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        out = res / f'mipmap-{folder}' / 'ic_launcher.png'
        render(px).save(out)
        print(out, px)
    render(1024).save(preview / 'usisa-app-icon-1024.png')
    render(512, rounded=False).save(preview / 'usisa-app-icon-512-square.png')


if __name__ == '__main__':
    main()
