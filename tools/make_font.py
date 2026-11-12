#!/usr/bin/env python3
"""Generate a B612 Bold bitmap font (.fnt + .png) in the same format as the BMFont
files in resources/fonts, without needing the Windows BMFont tool.

Usage: python3 tools/make_font.py <size> [output-folder]
  e.g. python3 tools/make_font.py 140        -> resources/fonts/B612-Bold_140.fnt

<size> is the BMFont line height, matching the numbers in the existing file names.
Only the characters the app displays are included.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

TTF = "resources/fonts/b612-master/fonts/ttf/B612-Bold.ttf"
CHARS = " +-.0123456789:amp"


def main():
    size = int(sys.argv[1])
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "resources/fonts"
    font = ImageFont.truetype(TTF, round(size * 0.75))  # BMFont size is line height; 0.75 em matches the existing files
    ascent, _ = font.getmetrics()

    glyphs = []
    for ch in CHARS:
        canvas = Image.new("L", (size * 2, size * 2), 0)
        pad = size // 2
        ImageDraw.Draw(canvas).text((pad, 0), ch, font=font, fill=255)
        box = canvas.getbbox()
        advance = round(font.getlength(ch))
        if box is None:  # space
            glyphs.append((ch, Image.new("L", (1, 1), 0), 0, size - 1, advance))
        else:
            glyphs.append((ch, canvas.crop(box), box[0] - pad, box[1], advance))

    for side in (256, 512, 1024):
        x = y = row = 0
        places, ok = [], True
        for ch, img, xo, yo, adv in sorted(glyphs, key=lambda g: -g[1].height):
            if x + img.width + 1 > side:
                x, y, row = 0, y + row + 1, 0
            if y + img.height + 1 > side:
                ok = False
                break
            places.append((ch, img, x, y, xo, yo, adv))
            x += img.width + 1
            row = max(row, img.height)
        if ok:
            break

    atlas = Image.new("L", (side, side), 0)
    for ch, img, x, y, xo, yo, adv in places:
        atlas.paste(img, (x, y))
    name = "B612-Bold_%d" % size
    atlas.save(os.path.join(out_dir, name + "_0.png"))
    with open(os.path.join(out_dir, name + ".fnt"), "w") as f:
        f.write('info face="B612" size=%d bold=1 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1 outline=0\n' % size)
        f.write("common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0\n" % (size, ascent, side, side))
        f.write('page id=0 file="%s_0.png"\n' % name)
        f.write("chars count=%d\n" % len(places))
        for ch, img, x, y, xo, yo, adv in sorted(places, key=lambda p: ord(p[0])):
            f.write("char id=%-4d x=%-5d y=%-5d width=%-5d height=%-5d xoffset=%-5d yoffset=%-5d xadvance=%-5d page=0  chnl=15\n"
                    % (ord(ch), x, y, img.width, img.height, xo, yo, adv))
    print("wrote %s (%dx%d atlas)" % (os.path.join(out_dir, name + ".fnt"), side, side))


if __name__ == "__main__":
    main()
