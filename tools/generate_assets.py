#!/usr/bin/env python3
"""
Procedural pixel-art asset & BMFont generator for Football Unity (Godot 4).
Generates:
1. Crisp pixel-art AngelCode BMFonts (pixel_ui.fnt, pixel_display.fnt)
2. 2.5D Stadium & Match textures (striped pitch with lines, net, ad boards, stands, ball)
3. Pixel-art scene backdrops (locker room, dinner room, press wall, TV studio, manager office, city map)
4. Layered pixel-art character sprites (base body, kit overlays, hairstyles, boots, NPCs)
5. UI / Trophy / Boot icons
"""

import os
import math
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")


def ensure_dir(path: str):
    os.makedirs(path, exist_ok=True)


# ---------------------------------------------------------------------------
# 1. CRISP PIXEL BITMAP FONTS (5x7 UI + 7x9 Display)
# ---------------------------------------------------------------------------
# Hand-crafted 5x7 bitmap glyphs (each row is 5 bits, 7 rows tall)
GLYPHS_5X7 = {
    " ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
    "!": ["00100", "00100", "00100", "00100", "00100", "00000", "00100"],
    '"': ["01010", "01010", "01010", "00000", "00000", "00000", "00000"],
    "#": ["01010", "11111", "01010", "01010", "11111", "01010", "00000"],
    "$": ["00100", "01111", "10100", "01110", "00101", "11110", "00100"],
    "%": ["11001", "11010", "00010", "00100", "01000", "01011", "10011"],
    "&": ["01100", "10010", "10100", "01000", "10101", "10010", "01101"],
    "'": ["00100", "00100", "01000", "00000", "00000", "00000", "00000"],
    "(": ["00010", "00100", "01000", "01000", "01000", "00100", "00010"],
    ")": ["01000", "00100", "00010", "00010", "00010", "00100", "01000"],
    "*": ["00100", "10101", "01110", "11111", "01110", "10101", "00100"],
    "+": ["00000", "00100", "00100", "11111", "00100", "00100", "00000"],
    ",": ["00000", "00000", "00000", "00000", "00000", "00100", "01000"],
    "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "01100", "01100"],
    "/": ["00001", "00010", "00010", "00100", "01000", "01000", "10000"],
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00110", "01000", "10000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
    ":": ["00000", "01100", "01100", "00000", "01100", "01100", "00000"],
    ";": ["00000", "01100", "01100", "00000", "01100", "00100", "01000"],
    "<": ["00010", "00100", "01000", "10000", "01000", "00100", "00010"],
    "=": ["00000", "00000", "11111", "00000", "11111", "00000", "00000"],
    ">": ["01000", "00100", "00010", "00001", "00010", "00100", "01000"],
    "?": ["01110", "10001", "00001", "00110", "00100", "00000", "00100"],
    "@": ["01110", "10001", "10111", "10101", "10110", "10000", "01110"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
    "D": ["11100", "10010", "10001", "10001", "10001", "10010", "11100"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "G": ["01110", "10001", "10000", "10111", "10001", "10001", "01110"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
    "J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
    "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
    "[": ["01110", "01000", "01000", "01000", "01000", "01000", "01110"],
    "\\": ["10000", "01000", "01000", "00100", "00010", "00010", "00001"],
    "]": ["01110", "00010", "00010", "00010", "00010", "00010", "01110"],
    "^": ["00100", "01010", "10001", "00000", "00000", "00000", "00000"],
    "_": ["00000", "00000", "00000", "00000", "00000", "00000", "11111"],
    "`": ["01000", "00100", "00000", "00000", "00000", "00000", "00000"],
    "a": ["00000", "00000", "01110", "00001", "01111", "10001", "01111"],
    "b": ["10000", "10000", "11110", "10001", "10001", "10001", "11110"],
    "c": ["00000", "00000", "01110", "10000", "10000", "10001", "01110"],
    "d": ["00001", "00001", "01111", "10001", "10001", "10001", "01111"],
    "e": ["00000", "00000", "01110", "10001", "11111", "10000", "01110"],
    "f": ["00110", "01001", "01000", "11100", "01000", "01000", "01000"],
    "g": ["00000", "00000", "01111", "10001", "01111", "00001", "01110"],
    "h": ["10000", "10000", "11110", "10001", "10001", "10001", "10001"],
    "i": ["00100", "00000", "01100", "00100", "00100", "00100", "01110"],
    "j": ["00010", "00000", "00110", "00010", "00010", "10010", "01100"],
    "k": ["10000", "10000", "10010", "10100", "11000", "10100", "10010"],
    "l": ["01100", "00100", "00100", "00100", "00100", "00100", "01110"],
    "m": ["00000", "00000", "11010", "10101", "10101", "10101", "10001"],
    "n": ["00000", "00000", "11110", "10001", "10001", "10001", "10001"],
    "o": ["00000", "00000", "01110", "10001", "10001", "10001", "01110"],
    "p": ["00000", "00000", "11110", "10001", "11110", "10000", "10000"],
    "q": ["00000", "00000", "01111", "10001", "01111", "00001", "00001"],
    "r": ["00000", "00000", "10110", "11001", "10000", "10000", "10000"],
    "s": ["00000", "00000", "01111", "10000", "01110", "00001", "11110"],
    "t": ["01000", "01000", "11100", "01000", "01000", "01001", "00110"],
    "u": ["00000", "00000", "10001", "10001", "10001", "10011", "01101"],
    "v": ["00000", "00000", "10001", "10001", "10001", "01010", "00100"],
    "w": ["00000", "00000", "10001", "10001", "10101", "11011", "10001"],
    "x": ["00000", "00000", "10001", "01010", "00100", "01010", "10001"],
    "y": ["00000", "00000", "10001", "10001", "01111", "00001", "01110"],
    "z": ["00000", "00000", "11111", "00010", "00100", "01000", "11111"],
    "{": ["00010", "00100", "00100", "01000", "00100", "00100", "00010"],
    "|": ["00100", "00100", "00100", "00100", "00100", "00100", "00100"],
    "}": ["01000", "00100", "00100", "00010", "00100", "00100", "01000"],
    "~": ["00000", "00000", "01001", "10110", "00000", "00000", "00000"],
    "•": ["00000", "00000", "00100", "01110", "00100", "00000", "00000"],
    "×": ["00000", "00000", "10001", "01010", "00100", "01010", "10001"],
    "≈": ["00000", "01001", "10110", "00000", "01001", "10110", "00000"],
    "→": ["00000", "00100", "00010", "11111", "00010", "00100", "00000"],
    "←": ["00000", "00100", "01000", "11111", "01000", "00100", "00000"],
    "▲": ["00000", "00100", "01110", "11111", "00000", "00000", "00000"],
    "▼": ["00000", "00000", "11111", "01110", "00100", "00000", "00000"],
    "★": ["00100", "00100", "11111", "01110", "01010", "10001", "00000"],
    "✓": ["00000", "00001", "00010", "10100", "01000", "00000", "00000"],
    "▸": ["01000", "01100", "01110", "01111", "01110", "01100", "01000"],
    "●": ["00000", "01110", "11111", "11111", "11111", "01110", "00000"],
    "○": ["00000", "01110", "10001", "10001", "10001", "01110", "00000"],
    "⚙": ["00100", "10101", "01110", "11011", "01110", "10101", "00100"],
    "☰": ["11111", "00000", "11111", "00000", "11111", "00000", "11111"],
    "✎": ["00011", "00110", "01100", "11000", "11000", "10000", "00000"],
    "⚡": ["00110", "01100", "11111", "00110", "01100", "11000", "10000"],
    "∅": ["00111", "01001", "10101", "10101", "10101", "10010", "11100"],
    "ä": ["01010", "00000", "01110", "00001", "01111", "10001", "01111"],
    "ö": ["01010", "00000", "01110", "10001", "10001", "10001", "01110"],
    "å": ["00100", "00000", "01110", "00001", "01111", "10001", "01111"],
    "é": ["00010", "00100", "01110", "10001", "11111", "10000", "01110"],
    "á": ["00010", "00100", "01110", "00001", "01111", "10001", "01111"],
    "í": ["00010", "00100", "01100", "00100", "00100", "00100", "01110"],
    "ó": ["00010", "00100", "01110", "10001", "10001", "10001", "01110"],
    "ú": ["00010", "00100", "10001", "10001", "10001", "10011", "01101"],
    "ñ": ["01101", "10010", "11110", "10001", "10001", "10001", "10001"],
    "Ä": ["01010", "01110", "10001", "11111", "10001", "10001", "10001"],
    "Ö": ["01010", "01110", "10001", "10001", "10001", "10001", "01110"],
    "Å": ["00100", "01110", "10001", "11111", "10001", "10001", "10001"],
    "Á": ["00010", "01110", "10001", "11111", "10001", "10001", "10001"],
    "î": ["00100", "01010", "01100", "00100", "00100", "00100", "01110"],
    "—": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
    "▶": ["01000", "01100", "01110", "01111", "01110", "01100", "01000"],
}


def generate_bmfont(out_dir: str, name: str, scale: int, bold_x: bool = False):
    """Generates a crisp AngelCode BMFont (.fnt + _0.png) scaled cleanly by integer scale."""
    ensure_dir(out_dir)
    cols = 16
    cell_w = (6 if bold_x else 5) * scale + 2 * scale
    cell_h = 8 * scale + 2 * scale
    chars = list(GLYPHS_5X7.keys())
    rows = math.ceil(len(chars) / cols)
    img_w = 1
    while img_w < cols * cell_w:
        img_w *= 2
    img_h = 1
    while img_h < rows * cell_h:
        img_h *= 2

    img = Image.new("RGBA", (img_w, img_h), (0, 0, 0, 0))
    px = img.load()
    entries = []

    for idx, ch in enumerate(chars):
        gx = (idx % cols) * cell_w
        gy = (idx // cols) * cell_h
        bmp = GLYPHS_5X7[ch]
        gw = 6 if bold_x else 5
        gh = 7
        for r_i, row_bits in enumerate(bmp):
            for c_i, bit in enumerate(row_bits):
                if bit == "1":
                    for sy in range(scale):
                        for sx in range(scale):
                            px[gx + c_i * scale + sx, gy + r_i * scale + sy] = (255, 255, 255, 255)
                            if bold_x:
                                px[gx + (c_i + 1) * scale + sx, gy + r_i * scale + sy] = (255, 255, 255, 255)
        adv = (7 if bold_x else 6) * scale
        if ch in "iIl!.,;:'|":
            adv = (5 if bold_x else 4) * scale
        entries.append((ord(ch), gx, gy, gw * scale, gh * scale, 0, scale, adv))

    png_name = f"{name}_0.png"
    img.save(os.path.join(out_dir, png_name))

    line_h = 9 * scale
    base = 7 * scale
    fnt_lines = [
        f'info face="{name}" size={8 * scale} bold={1 if bold_x else 0} italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=1,1',
        f'common lineHeight={line_h} base={base} scaleW={img_w} scaleH={img_h} pages=1 packed=0',
        f'page id=0 file="{png_name}"',
        f'chars count={len(entries)}',
    ]
    for cid, x, y, w, h, xo, yo, xa in entries:
        fnt_lines.append(f"char id={cid} x={x} y={y} width={w} height={h} xoffset={xo} yoffset={yo} xadvance={xa} page=0 chnl=15")

    with open(os.path.join(out_dir, f"{name}.fnt"), "w", encoding="utf-8") as f:
        f.write("\n".join(fnt_lines) + "\n")


# ---------------------------------------------------------------------------
# 2. STADIUM & MATCH TEXTURES (Point-filtered pixel art for 3D)
# ---------------------------------------------------------------------------
def generate_pitch_textures(out_dir: str):
    ensure_dir(out_dir)

    # 2a. HD 1024x2048 Championship Turf: dual mow stripes + subtle cross-hatch + penalty box wear + sharp chalk lines
    W, H = 1024, 2048
    img = Image.new("RGBA", (W, H), (30, 108, 46, 255))
    draw = ImageDraw.Draw(img)

    # Alternating wide horizontal mow bands
    stripe_count = 20
    for i in range(stripe_count):
        y0 = int(i * H / stripe_count)
        y1 = int((i + 1) * H / stripe_count)
        base = (46, 146, 64, 255) if i % 2 == 0 else (33, 118, 50, 255)
        draw.rectangle([0, y0, W, y1], fill=base)
        # Subtle vertical cross-mow checker tint
        for vx in range(0, W, 128):
            if ((vx // 128) + i) % 2 == 0:
                draw.rectangle([vx, y0, vx + 127, y1], fill=(base[0] + 5, base[1] + 6, base[2] + 4, 255))

    # Turf texture grain & vignette depth
    px = img.load()
    for y in range(0, H, 2):
        for x in range(0, W, 2):
            h = (x * 73 + y * 139) % 29
            if h < 4:
                r, g, b, a = px[x, y]
                delta = -8 if h < 2 else 7
                px[x, y] = (max(0, min(255, r + delta)), max(0, min(255, g + delta)), max(0, min(255, b + delta // 2)), a)

    # Penalty box slight turf wear near goals
    for gy in (95, H - 155):
        draw.ellipse([W // 2 - 70, gy, W // 2 + 70, gy + 60], fill=(76, 124, 58, 120))

    mx = 48
    my = 72
    pw = W - 2 * mx
    ph = H - 2 * my
    lc = (242, 248, 244, 255)
    ls = (28, 86, 42, 160)
    lw = 7

    # Crisp chalk markings + subtle green shadow edge
    draw.rectangle([mx - 2, my - 2, mx + pw + 2, my + ph + 2], outline=ls, width=lw + 2)
    draw.rectangle([mx, my, mx + pw, my + ph], outline=lc, width=lw)
    mid_y = my + ph // 2
    draw.line([(mx, mid_y), (mx + pw, mid_y)], fill=lc, width=lw)
    cr = int(pw * (9.15 / 68.0))
    draw.ellipse([W // 2 - cr, mid_y - cr, W // 2 + cr, mid_y + cr], outline=lc, width=lw)
    draw.ellipse([W // 2 - 7, mid_y - 7, W // 2 + 7, mid_y + 7], fill=lc)

    box_w = int(pw * (40.32 / 68.0))
    box_h = int(ph * (16.5 / 105.0))
    six_w = int(pw * (18.32 / 68.0))
    six_h = int(ph * (5.5 / 105.0))
    pen_d = int(ph * (11.0 / 105.0))

    bx0 = W // 2 - box_w // 2
    draw.rectangle([bx0, my, bx0 + box_w, my + box_h], outline=lc, width=lw)
    sx0 = W // 2 - six_w // 2
    draw.rectangle([sx0, my, sx0 + six_w, my + six_h], outline=lc, width=lw)
    draw.ellipse([W // 2 - 6, my + pen_d - 6, W // 2 + 6, my + pen_d + 6], fill=lc)
    draw.arc([W // 2 - cr, my + pen_d - cr, W // 2 + cr, my + pen_d + cr], start=36, end=144, fill=lc, width=lw)

    draw.rectangle([bx0, my + ph - box_h, bx0 + box_w, my + ph], outline=lc, width=lw)
    draw.rectangle([sx0, my + ph - six_h, sx0 + six_w, my + ph], outline=lc, width=lw)
    draw.ellipse([W // 2 - 6, my + ph - pen_d - 6, W // 2 + 6, my + ph - pen_d + 6], fill=lc)
    draw.arc([W // 2 - cr, my + ph - pen_d - cr, W // 2 + cr, my + ph - pen_d + cr], start=216, end=324, fill=lc, width=lw)

    ca = 26
    draw.arc([mx - ca, my - ca, mx + ca, my + ca], 0, 90, fill=lc, width=lw)
    draw.arc([mx + pw - ca, my - ca, mx + pw + ca, my + ca], 90, 180, fill=lc, width=lw)
    draw.arc([mx - ca, my + ph - ca, mx + ca, my + ph + ca], 270, 360, fill=lc, width=lw)
    draw.arc([mx + pw - ca, my + ph - ca, mx + pw + ca, my + ph + ca], 180, 270, fill=lc, width=lw)
    img.save(os.path.join(out_dir, "pitch_turf.png"))

    # 2b. Crisp Woven Goal Net (128x128)
    net = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    nd = ImageDraw.Draw(net)
    for i in range(0, 128, 12):
        nd.line([(i, 0), (i, 127)], fill=(242, 248, 252, 185), width=2)
        nd.line([(0, i), (127, i)], fill=(242, 248, 252, 185), width=2)
    net.save(os.path.join(out_dir, "goal_net.png"))

    # 2c. HD Glowing LED Perimeter Ad Boards (1024x96)
    ad = Image.new("RGBA", (1024, 96), (10, 20, 42, 255))
    ad_d = ImageDraw.Draw(ad)
    panels = [
        (0, 256, (18, 56, 134, 255), (255, 255, 255, 255), (72, 196, 255, 255), "LIGA KE-3"),
        (256, 512, (16, 36, 84, 255), (128, 224, 255, 255), (245, 205, 65, 255), "FOOTBALL UNITY"),
        (512, 768, (26, 78, 156, 255), (255, 220, 75, 255), (255, 255, 255, 255), "LEGACY CUP"),
        (768, 1024, (124, 24, 46, 255), (255, 255, 255, 255), (255, 195, 70, 255), "TALLERES RACA"),
    ]
    for x0, x1, bg, fg, trim, label in panels:
        ad_d.rectangle([x0, 0, x1 - 1, 95], fill=bg, outline=(6, 10, 20, 255), width=4)
        ad_d.rectangle([x0 + 6, 6, x1 - 7, 14], fill=trim)
        ad_d.rectangle([x0 + 6, 82, x1 - 7, 90], fill=trim)
        tx = x0 + 20
        for ch in label[:13]:
            if ch in GLYPHS_5X7:
                for ry, bits in enumerate(GLYPHS_5X7[ch]):
                    for cx, b in enumerate(bits):
                        if b == "1":
                            ad_d.rectangle([tx + cx * 3, 28 + ry * 5, tx + cx * 3 + 2, 28 + ry * 5 + 4], fill=fg)
            tx += 17
    ad.save(os.path.join(out_dir, "ad_board.png"))

    # 2d. HD Tiered Stadium Crowd with Banners, Stairs & Atmosphere (512x256)
    crowd = Image.new("RGBA", (512, 256), (18, 24, 34, 255))
    cd = ImageDraw.Draw(crowd)
    shirt_cols = [
        (225, 52, 56, 255), (42, 118, 232, 255), (240, 242, 246, 255),
        (242, 198, 52, 255), (48, 178, 86, 255), (160, 74, 195, 255), (34, 40, 52, 255)
    ]
    for row in range(20):
        ry = row * 12 + 12
        shade = 22 + (row % 2) * 8 + int(row * 0.6)
        cd.rectangle([0, ry, 511, ry + 11], fill=(shade, shade + 6, shade + 18, 255))
        cd.line([(0, ry), (511, ry)], fill=(shade + 22, shade + 28, shade + 40, 255), width=1)
        for col in range(0, 512, 10):
            if (col // 10) % 16 == 8:
                cd.rectangle([col, ry, col + 8, ry + 11], fill=(90, 96, 108, 255))  # concrete stairs
                continue
            seed = (row * 97 + col * 31) % 100
            if seed < 84:
                sc = shirt_cols[(row * 13 + col * 7) % len(shirt_cols)]
                skin = (228, 186, 150, 255) if seed % 3 != 0 else (142, 96, 66, 255)
                cd.rectangle([col + 2, ry + 5, col + 7, ry + 11], fill=sc)
                cd.rectangle([col + 3, ry + 1, col + 6, ry + 4], fill=skin)
                if seed % 11 == 0:
                    cd.rectangle([col + 1, ry + 2, col + 8, ry + 4], fill=(242, 204, 64, 255))  # scarf/flag
    # Top stadium floodlight canopy band
    cd.rectangle([0, 0, 511, 14], fill=(12, 18, 28, 255))
    for fx in range(32, 512, 96):
        cd.rectangle([fx, 2, fx + 36, 10], fill=(235, 245, 255, 255))
    crowd.save(os.path.join(out_dir, "stands_crowd.png"))

    # 2e. 64x64 Sculpted & Specular-Shaded Soccer Ball
    ball = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    bd = ImageDraw.Draw(ball)
    bd.ellipse([4, 4, 59, 59], fill=(244, 247, 250, 255), outline=(18, 22, 30, 255), width=3)
    bd.arc([7, 7, 56, 56], 20, 125, fill=(182, 194, 208, 255), width=6)
    bd.ellipse([14, 10, 26, 20], fill=(255, 255, 255, 255))  # specular highlight
    bd.polygon([(32, 22), (42, 29), (38, 41), (26, 41), (22, 29)], fill=(26, 32, 42, 255))
    for px0, py0, px1, py1 in [(28, 6, 36, 14), (7, 29, 15, 37), (49, 29, 57, 37), (18, 48, 26, 56), (38, 48, 46, 56)]:
        bd.polygon([(px0, (py0 + py1) // 2), ((px0 + px1) // 2, py0), (px1, (py0 + py1) // 2), ((px0 + px1) // 2, py1)], fill=(30, 36, 48, 255))
    ball.save(os.path.join(out_dir, "ball_sprite.png"))


# ---------------------------------------------------------------------------
# 3. SCENE BACKDROPS (Locker Room, Dinner, Press, TV Studio, Manager, City)
# ---------------------------------------------------------------------------
def generate_backgrounds(out_dir: str):
    ensure_dir(out_dir)

    # 3a. HD Locker Room (540 x 280) with overhead warm spotlight gradient, detailed wood grain & louvers
    lr = Image.new("RGBA", (540, 280), (28, 32, 38, 255))
    d = ImageDraw.Draw(lr)
    for y in range(204):
        shade = int(46 + 24 * math.sin((y / 204.0) * math.pi))
        d.line([(0, y), (539, y)], fill=(shade, shade + 4, shade + 10, 255))
    for i in range(4):
        lx = 14 + i * 132
        d.rectangle([lx, 14, lx + 120, 206], fill=(46, 33, 24, 255), outline=(18, 12, 8, 255), width=3)
        d.rectangle([lx + 8, 20, lx + 112, 58], fill=(64, 46, 32, 255), outline=(28, 20, 14, 255), width=2)
        for v in range(68, 86, 6):
            d.line([(lx + 24, v), (lx + 96, v)], fill=(22, 16, 12, 255), width=2)  # locker louvers
        d.polygon([(lx + 60, 88), (lx + 46, 98), (lx + 74, 98)], fill=(214, 178, 92, 255), outline=(120, 92, 38, 255))
    # Overhead warm cone spotlights
    for sx in [80, 212, 344, 476]:
        d.ellipse([sx - 36, 0, sx + 36, 18], fill=(255, 232, 165, 55))
    # Reflective timber floorboards & sculpted bench
    d.rectangle([0, 204, 539, 279], fill=(38, 28, 20, 255))
    for i in range(-40, 580, 36):
        d.line([(i, 204), (i - 22, 279)], fill=(24, 18, 12, 255), width=2)
    d.rectangle([34, 208, 246, 224], fill=(128, 84, 46, 255), outline=(24, 16, 10, 255), width=2)
    d.rectangle([42, 210, 238, 214], fill=(154, 104, 62, 255))  # bench top highlight
    d.rectangle([48, 224, 60, 248], fill=(82, 52, 28, 255))
    d.rectangle([220, 224, 232, 248], fill=(82, 52, 28, 255))
    d.rectangle([386, 212, 466, 248], fill=(48, 54, 64, 255), outline=(18, 22, 28, 255), width=2)
    d.ellipse([54, 244, 78, 268], fill=(238, 244, 250, 255), outline=(22, 26, 34, 255), width=2)
    lr.save(os.path.join(out_dir, "locker_room.png"))

    # 3b. HD Dinner Room (540 x 440) with pendant halos, brick depth & tables
    dr = Image.new("RGBA", (540, 440), (30, 20, 14, 255))
    dd = ImageDraw.Draw(dr)
    for y in range(440):
        t = y / 440.0
        r = int(42 + 54 * math.sin(t * math.pi))
        g = int(28 + 38 * math.sin(t * math.pi))
        b = int(18 + 18 * math.sin(t * math.pi))
        dd.line([(0, y), (539, y)], fill=(r, g, b, 255))
    for lx in [130, 270, 410]:
        dd.line([(lx, 0), (lx, 112)], fill=(18, 14, 12, 255), width=4)
        dd.polygon([(lx - 28, 136), (lx + 28, 136), (lx + 12, 112), (lx - 12, 112)], fill=(236, 224, 198, 255), outline=(60, 48, 34, 255))
        dd.ellipse([lx - 65, 132, lx + 65, 220], fill=(255, 220, 135, 36))
    for tx, ty, tw in [(40, 240, 72), (224, 272, 92), (400, 250, 88)]:
        dd.rectangle([tx, ty, tx + tw, ty + 64], fill=(122, 112, 108, 255), outline=(56, 50, 48, 255), width=2)
        dd.ellipse([tx - 4, ty - 12, tx + tw + 4, ty + 12], fill=(208, 202, 196, 255))
        dd.rectangle([tx + tw // 2 - 3, ty - 16, tx + tw // 2 + 3, ty - 4], fill=(255, 242, 190, 255))
    dr.save(os.path.join(out_dir, "dinner_room.png"))

    # 3c. HD Press Wall (540 x 720) beveled step-and-repeat sponsor backdrop
    pw_img = Image.new("RGBA", (540, 720), (18, 52, 116, 255))
    pd = ImageDraw.Draw(pw_img)
    cw, ch = 108, 56
    for row in range(14):
        for col in range(6):
            x0 = col * cw - (54 if row % 2 == 1 else 0)
            y0 = row * ch
            bg = (232, 238, 246, 255) if (row + col) % 2 == 0 else (22, 76, 156, 255)
            fg = (20, 62, 128, 255) if (row + col) % 2 == 0 else (232, 240, 248, 255)
            pd.rectangle([x0, y0, x0 + cw - 4, y0 + ch - 4], fill=bg, outline=(12, 32, 68, 255), width=2)
            pd.rectangle([x0 + 18, y0 + 20, x0 + cw - 22, y0 + 32], fill=fg)
    pw_img.save(os.path.join(out_dir, "press_wall.png"))

    # 3d. HD TV Broadcast Studio (540 x 720) with neon arches, glass desk sheen & monitor wall
    st = Image.new("RGBA", (540, 720), (10, 12, 28, 255))
    sd = ImageDraw.Draw(st)
    for y in range(520):
        sd.line([(0, y), (539, y)], fill=(12 + y // 30, 14 + y // 32, 36 + y // 22, 255))
    for x in range(0, 540, 76):
        sd.rectangle([x + 12, 80, x + 64, 520], fill=(48, 32, 112, 255))
        sd.rectangle([x + 20, 96, x + 56, 504], fill=(74, 48, 154, 255), outline=(120, 88, 210, 255), width=2)
    sd.line([(0, 84), (539, 84)], fill=(215, 72, 152, 255), width=6)
    sd.line([(0, 448), (539, 448)], fill=(58, 212, 242, 255), width=6)
    sd.rectangle([0, 520, 539, 719], fill=(16, 22, 42, 255))
    sd.rectangle([0, 508, 539, 524], fill=(168, 58, 86, 255))
    st.save(os.path.join(out_dir, "studio_desk.png"))

    # 3e. Manager Office (540 x 280)
    mo = Image.new("RGBA", (540, 280), (32, 36, 44, 255))
    md = ImageDraw.Draw(mo)
    md.rectangle([0, 0, 539, 200], fill=(54, 60, 70, 255))
    md.rectangle([20, 84, 112, 196], fill=(76, 84, 96, 255), outline=(36, 38, 44, 255), width=3)
    md.line([(240, 0), (240, 68)], fill=(18, 18, 22, 255), width=4)
    md.rectangle([220, 68, 260, 84], fill=(235, 232, 218, 255))
    md.ellipse([40, 188, 500, 276], fill=(102, 72, 46, 255), outline=(44, 30, 18, 255), width=3)
    md.rectangle([236, 184, 252, 216], fill=(235, 240, 245, 255))
    md.rectangle([192, 204, 208, 220], fill=(215, 205, 190, 255))
    mo.save(os.path.join(out_dir, "manager_office.png"))

    # 3f. HD City Map (540 x 520)
    cm = Image.new("RGBA", (540, 520), (24, 44, 28, 255))
    cd = ImageDraw.Draw(cm)
    cd.rectangle([36, 52, 504, 428], fill=(48, 54, 64, 255), outline=(88, 102, 120, 255), width=2)
    for rx in [56, 132]:
        for ry in [68, 124]:
            cd.rectangle([rx, ry, rx + 64, ry + 44], fill=(52, 134, 62, 255), outline=(104, 78, 52, 255), width=3)
    cd.rectangle([220, 60, 336, 156], fill=(84, 94, 108, 255), outline=(156, 122, 78, 255), width=3)
    cd.rectangle([240, 76, 316, 136], fill=(42, 162, 68, 255), outline=(232, 242, 232, 255), width=2)
    cd.rectangle([372, 212, 492, 364], fill=(46, 140, 66, 255), outline=(32, 92, 44, 255), width=2)
    cd.rectangle([0, 0, 28, 519], fill=(74, 82, 92, 255))
    for dy in range(8, 520, 24):
        cd.line([(14, dy), (14, dy + 12)], fill=(224, 228, 232, 255), width=3)
    cd.line([(36, 184), (504, 184)], fill=(124, 134, 148, 255), width=8)
    cd.line([(270, 184), (270, 456)], fill=(124, 134, 148, 255), width=8)
    cd.line([(36, 372), (504, 372)], fill=(124, 134, 148, 255), width=8)
    cm.save(os.path.join(out_dir, "city_map.png"))


# ---------------------------------------------------------------------------
# 4. PIXEL-ART MODULAR CHARACTER SPRITES & ICONS
# ---------------------------------------------------------------------------
def draw_pixel_person(
    img: Image.Image,
    ox: int,
    oy: int,
    skin=(230, 186, 148, 255),
    hair=(92, 56, 36, 255),
    jersey=(36, 104, 205, 255),
    stripe=(242, 246, 252, 255),
    shorts=(242, 246, 252, 255),
    boots=(45, 115, 220, 255),
    long_sleeve=False,
    pose="idle",
    back_view=False,
    hair_style=0,
    beard=False,
    is_female=False,
):
    """Draws a crisp 24x36 pixel-art character with black outline."""
    d = ImageDraw.Draw(img)
    blk = (16, 18, 24, 255)
    eye = (22, 24, 30, 255)

    # Head outline & fill
    d.rectangle([ox + 7, oy + 3, ox + 16, oy + 12], fill=skin, outline=blk)
    # Hair
    if hair_style == 0:  # Curly/fluffy top
        d.rectangle([ox + 6, oy + 1, ox + 17, oy + 4], fill=hair, outline=blk)
        d.rectangle([ox + 7, oy + 2, ox + 16, oy + 4], fill=hair)
        d.rectangle([ox + 7, oy + 4, ox + 8, oy + 6], fill=hair)
        d.rectangle([ox + 15, oy + 4, ox + 16, oy + 6], fill=hair)
    elif hair_style == 1:  # Long / flowing
        d.rectangle([ox + 6, oy + 1, ox + 17, oy + 5], fill=hair, outline=blk)
        d.rectangle([ox + 5, oy + 4, ox + 7, oy + 14], fill=hair, outline=blk)
        d.rectangle([ox + 16, oy + 4, ox + 18, oy + 14], fill=hair, outline=blk)
    elif hair_style == 2:  # Short swept
        d.rectangle([ox + 7, oy + 2, ox + 16, oy + 4], fill=hair, outline=blk)
    else:  # Buzz / fade
        d.rectangle([ox + 8, oy + 2, ox + 15, oy + 3], fill=hair)

    if not back_view:
        # Eyes + brows + mouth
        d.point((ox + 9, oy + 7), fill=eye)
        d.point((ox + 14, oy + 7), fill=eye)
        d.line([(ox + 9, oy + 6), (ox + 10, oy + 6)], fill=hair)
        d.line([(ox + 13, oy + 6), (ox + 14, oy + 6)], fill=hair)
        d.line([(ox + 11, oy + 10), (ox + 12, oy + 10)], fill=(170, 105, 95, 255))
        if beard:
            d.rectangle([ox + 8, oy + 9, ox + 15, oy + 12], fill=hair)
            d.line([(ox + 11, oy + 10), (ox + 12, oy + 10)], fill=(215, 165, 145, 255))
    else:
        d.rectangle([ox + 7, oy + 3, ox + 16, oy + 9], fill=hair)

    # Torso / Jersey
    d.rectangle([ox + 6, oy + 13, ox + 17, oy + 23], fill=jersey, outline=blk)
    if stripe is not None:
        d.rectangle([ox + 9, oy + 14, ox + 10, oy + 22], fill=stripe)
        d.rectangle([ox + 13, oy + 14, ox + 14, oy + 22], fill=stripe)

    # Arms
    arm_y_l = oy + 14
    arm_y_r = oy + 14
    if pose == "run1":
        arm_y_l -= 1
        arm_y_r += 1
    elif pose == "run2":
        arm_y_l += 1
        arm_y_r -= 1

    sleeve_h = 8 if long_sleeve else 4
    d.rectangle([ox + 3, arm_y_l, ox + 6, arm_y_l + 8], fill=skin, outline=blk)
    d.rectangle([ox + 3, arm_y_l, ox + 6, arm_y_l + sleeve_h], fill=jersey, outline=blk)
    d.rectangle([ox + 17, arm_y_r, ox + 20, arm_y_r + 8], fill=skin, outline=blk)
    d.rectangle([ox + 17, arm_y_r, ox + 20, arm_y_r + sleeve_h], fill=jersey, outline=blk)

    # Shorts / Skirt
    if is_female:
        d.rectangle([ox + 6, oy + 23, ox + 17, oy + 31], fill=shorts, outline=blk)
    else:
        d.rectangle([ox + 6, oy + 23, ox + 17, oy + 27], fill=shorts, outline=blk)
        d.line([(ox + 11, oy + 25), (ox + 12, oy + 25)], fill=blk)

    # Legs + Socks + Boots
    l_off = 0
    r_off = 0
    if pose == "run1":
        l_off = -1
        r_off = 1
    elif pose == "run2":
        l_off = 1
        r_off = -1
    elif pose == "kick":
        r_off = -2

    # Left leg
    d.rectangle([ox + 7, oy + 27 + l_off, ox + 10, oy + 32 + l_off], fill=skin, outline=blk)
    d.rectangle([ox + 7, oy + 30 + l_off, ox + 10, oy + 32 + l_off], fill=jersey, outline=blk)
    d.rectangle([ox + 6, oy + 32 + l_off, ox + 10, oy + 34 + l_off], fill=boots, outline=blk)
    # Right leg
    d.rectangle([ox + 13, oy + 27 + r_off, ox + 16, oy + 32 + r_off], fill=skin, outline=blk)
    d.rectangle([ox + 13, oy + 30 + r_off, ox + 16, oy + 32 + r_off], fill=jersey, outline=blk)
    d.rectangle([ox + 13, oy + 32 + r_off, ox + 17, oy + 34 + r_off], fill=boots, outline=blk)


def generate_characters_and_icons(out_dir: str):
    char_dir = os.path.join(out_dir, "characters")
    ui_dir = os.path.join(out_dir, "ui")
    ensure_dir(char_dir)
    ensure_dir(ui_dir)

    # White/tintable layered spritesheets (4 frames x 24x36 each = 96x36) for 2.5D billboard sprites!
    # Layer 1: skin+outline base, Layer 2: jersey primary (white -> modulated), Layer 3: jersey stripes (white -> modulated), Layer 4: shorts, Layer 5: hair
    poses = ["idle", "run1", "run2", "kick"]

    # Supersampled 48x72-per-frame sheets (192x144) for razor-sharp shaded 3D billboard characters!
    def make_layer(draw_fn, filename):
        sheet = Image.new("RGBA", (96, 72), (0, 0, 0, 0))
        for i, p in enumerate(poses):
            draw_fn(sheet, i * 24, 0, p, False)
            draw_fn(sheet, i * 24, 36, p, True)
        # Upscale 2x with crisp nearest base + add clean subtle rim/fold shading in 192x144
        hd = sheet.resize((192, 144), Image.NEAREST)
        hp = hd.load()
        for y in range(144):
            for x in range(192):
                r, g, b, a = hp[x, y]
                if a > 200 and (r + g + b) > 100:
                    # Subtle top-left highlight & bottom-right shading inside character silhouette
                    lx = x % 48
                    ly = y % 72
                    if lx <= 18 or ly in (28, 29):
                        hp[x, y] = (min(255, r + 14), min(255, g + 14), min(255, b + 12), a)
                    elif lx >= 30:
                        hp[x, y] = (max(0, r - 18), max(0, g - 18), max(0, b - 16), a)
        hd.save(os.path.join(char_dir, filename))

    # Full pre-colored default player & opponent sheets for immediate crisp 2.5D billboards + tintable layers
    make_layer(
        lambda im, x, y, p, bv: draw_pixel_person(
            im, x, y,
            skin=(230, 186, 148, 255), hair=(92, 56, 36, 255),
            jersey=(255, 255, 255, 255), stripe=(200, 200, 200, 255),
            shorts=(245, 245, 245, 255), boots=(35, 38, 44, 255),
            pose=p, back_view=bv
        ),
        "player_white_sheet.png"
    )
    make_layer(
        lambda im, x, y, p, bv: draw_pixel_person(
            im, x, y,
            skin=(230, 186, 148, 255), hair=(92, 56, 36, 255),
            jersey=(36, 108, 212, 255), stripe=(240, 245, 252, 255),
            shorts=(240, 245, 252, 255), boots=(45, 125, 230, 255),
            pose=p, back_view=bv
        ),
        "player_home_sheet.png"
    )
    make_layer(
        lambda im, x, y, p, bv: draw_pixel_person(
            im, x, y,
            skin=(224, 178, 140, 255), hair=(50, 38, 28, 255),
            jersey=(208, 46, 52, 255), stripe=(175, 32, 38, 255),
            shorts=(34, 36, 42, 255), boots=(230, 230, 230, 255),
            pose=p, back_view=bv
        ),
        "player_away_sheet.png"
    )
    make_layer(
        lambda im, x, y, p, bv: draw_pixel_person(
            im, x, y,
            skin=(230, 186, 148, 255), hair=(64, 42, 28, 255),
            jersey=(136, 64, 184, 255), stripe=(108, 46, 152, 255),
            shorts=(36, 26, 54, 255), boots=(240, 185, 45, 255),
            long_sleeve=True, pose=p, back_view=bv
        ),
        "keeper_sheet.png"
    )

    # NPCs for Interview / Studio / Manager / Nora (48x72 crisp portrait-scale)
    npcs = Image.new("RGBA", (144, 36), (0, 0, 0, 0))
    # 0: Female reporter (with mic), 1: Nora (green sweater + skirt), 2: Manager (suit + beard), 3: Pundit, 4: Agent, 5: Star teammate
    draw_pixel_person(npcs, 0, 0, skin=(226, 178, 142, 255), hair=(155, 92, 46, 255),
                      jersey=(26, 28, 34, 255), stripe=None, shorts=(26, 28, 34, 255),
                      boots=(32, 32, 36, 255), long_sleeve=True, hair_style=1, is_female=True)
    # Mic in reporter hand
    nd = ImageDraw.Draw(npcs)
    nd.rectangle([10, 19, 13, 24], fill=(240, 145, 40, 255), outline=(16, 18, 24, 255))
    nd.line([(11, 25), (11, 29)], fill=(30, 32, 38, 255), width=2)

    draw_pixel_person(npcs, 24, 0, skin=(205, 156, 118, 255), hair=(84, 52, 32, 255),
                      jersey=(34, 108, 56, 255), stripe=None, shorts=(92, 64, 38, 255),
                      boots=(55, 38, 24, 255), long_sleeve=True, hair_style=1, is_female=True)
    draw_pixel_person(npcs, 48, 0, skin=(226, 184, 148, 255), hair=(112, 74, 46, 255),
                      jersey=(28, 32, 42, 255), stripe=(225, 230, 236, 255), shorts=(28, 32, 42, 255),
                      boots=(20, 20, 24, 255), long_sleeve=True, hair_style=2, beard=True)
    draw_pixel_person(npcs, 72, 0, skin=(215, 170, 134, 255), hair=(175, 175, 180, 255),
                      jersey=(44, 56, 78, 255), stripe=(210, 220, 235, 255), shorts=(32, 38, 52, 255),
                      boots=(24, 24, 28, 255), long_sleeve=True, hair_style=2, beard=True)
    draw_pixel_person(npcs, 96, 0, skin=(235, 195, 160, 255), hair=(225, 185, 85, 255),
                      jersey=(32, 36, 44, 255), stripe=(190, 50, 55, 255), shorts=(32, 36, 44, 255),
                      boots=(20, 20, 24, 255), long_sleeve=True, hair_style=2)
    draw_pixel_person(npcs, 120, 0, skin=(236, 198, 162, 255), hair=(230, 196, 86, 255),
                      jersey=(242, 246, 252, 255), stripe=(36, 108, 212, 255), shorts=(30, 62, 130, 255),
                      boots=(32, 34, 40, 255), hair_style=1)
    npcs.save(os.path.join(char_dir, "npcs_sheet.png"))

    # 4b. 11 Pixel-Art Boots Strip (352 x 32 -> 11 x 32x32)
    boots_img = Image.new("RGBA", (352, 32), (0, 0, 0, 0))
    bd = ImageDraw.Draw(boots_img)
    boot_palettes = [
        ((32, 36, 44, 255), (225, 232, 240, 255)),     # Classic Black
        ((232, 236, 242, 255), (36, 108, 212, 255)),   # Pearl Blue
        ((215, 42, 48, 255), (245, 220, 65, 255)),     # Crimson Gold
        ((42, 124, 228, 255), (110, 235, 255, 255)),   # Cobalt Cyan
        ((242, 198, 56, 255), (34, 34, 40, 255)),      # Gold Edition
        ((218, 72, 152, 255), (245, 245, 250, 255)),   # Neon Pink
        ((64, 212, 92, 255), (24, 32, 28, 255)),       # Volt Green
        ((238, 118, 36, 255), (250, 240, 215, 255)),   # Blaze Orange
        ((22, 28, 38, 255), (42, 235, 210, 255)),      # Eclipse X
        ((132, 62, 210, 255), (245, 195, 65, 255)),    # Royal Purple
        ((245, 205, 72, 255), (255, 255, 255, 255)),   # Legacy Legend
    ]
    for idx, (main_c, acc_c) in enumerate(boot_palettes):
        bx = idx * 32
        # Boot silhouette
        bd.polygon([(bx + 4, 22), (bx + 26, 22), (bx + 28, 18), (bx + 18, 14), (bx + 12, 8), (bx + 5, 10)],
                   fill=main_c, outline=(14, 16, 20, 255))
        # Accent stripe / swoosh
        bd.line([(bx + 8, 15), (bx + 18, 19), (bx + 24, 18)], fill=acc_c, width=2)
        # Laces
        bd.line([(bx + 13, 11), (bx + 19, 15)], fill=(245, 248, 250, 255), width=2)
        # Studs
        for sx in [7, 11, 15, 21, 25]:
            bd.rectangle([bx + sx, 23, bx + sx + 1, 25], fill=acc_c)
    boots_img.save(os.path.join(ui_dir, "boots_strip.png"))

    # 4c. 8 Pixel-Art Trophies Strip (256 x 32 -> 8 x 32x32)
    trophies = Image.new("RGBA", (256, 32), (0, 0, 0, 0))
    td = ImageDraw.Draw(trophies)
    trophy_cols = [
        (146, 98, 228, 255),   # 0: Terbaik Sepanjang Masa
        (242, 196, 56, 255),   # 1: Kejuaraan Dunia
        (232, 180, 48, 255),   # 2: Kejuaraan Dunia Klub
        (218, 168, 46, 255),   # 3: Piala Antarbenua
        (212, 220, 232, 255),  # 4: Piala Elite (Silver)
        (206, 214, 224, 255),  # 5: Piala Kejayaan
        (234, 184, 52, 255),   # 6: Piala Utara
        (220, 172, 46, 255),   # 7: Piala Timur
    ]
    for idx, col in enumerate(trophy_cols):
        tx = idx * 32
        outline = (22, 24, 30, 255)
        if idx in (0, 2, 3):  # Plate / Disk trophy
            td.ellipse([tx + 6, 4, tx + 25, 23], fill=col, outline=outline, width=2)
            td.ellipse([tx + 11, 9, tx + 20, 18], fill=(32, 36, 48, 255))
            td.rectangle([tx + 12, 24, tx + 19, 28], fill=(80, 62, 42, 255), outline=outline)
        else:  # Cup trophy
            td.polygon([(tx + 8, 5), (tx + 23, 5), (tx + 20, 17), (tx + 11, 17)], fill=col, outline=outline)
            # Handles
            td.arc([tx + 4, 6, tx + 11, 14], 90, 270, fill=col, width=2)
            td.arc([tx + 20, 6, tx + 27, 14], 270, 90, fill=col, width=2)
            td.rectangle([tx + 14, 17, tx + 17, 23], fill=col, outline=outline)
            td.rectangle([tx + 10, 23, tx + 21, 28], fill=(88, 66, 42, 255), outline=outline)
    trophies.save(os.path.join(ui_dir, "trophies_strip.png"))

    # 4d. Pixel Soccer Ball UI emblem (32x32)
    logo = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    ld = ImageDraw.Draw(logo)
    ld.ellipse([3, 3, 28, 28], fill=(242, 246, 252, 255), outline=(14, 22, 36, 255), width=2)
    ld.polygon([(16, 10), (21, 14), (19, 20), (13, 20), (11, 14)], fill=(20, 28, 42, 255))
    ld.rectangle([14, 4, 17, 7], fill=(20, 28, 42, 255))
    ld.rectangle([5, 15, 8, 19], fill=(20, 28, 42, 255))
    ld.rectangle([23, 15, 26, 19], fill=(20, 28, 42, 255))
    ld.rectangle([10, 24, 14, 27], fill=(20, 28, 42, 255))
    ld.rectangle([18, 24, 22, 27], fill=(20, 28, 42, 255))
    logo.save(os.path.join(ui_dir, "logo_ball.png"))


def main():
    generate_bmfont(os.path.join(ASSETS, "fonts"), "pixel_ui", scale=2, bold_x=False)
    generate_bmfont(os.path.join(ASSETS, "fonts"), "pixel_display", scale=2, bold_x=True)
    generate_pitch_textures(os.path.join(ASSETS, "sprites", "pitch"))
    generate_backgrounds(os.path.join(ASSETS, "sprites", "backgrounds"))
    generate_characters_and_icons(os.path.join(ASSETS, "sprites"))
    print("All Football Unity pixel assets generated successfully.")


if __name__ == "__main__":
    main()
