#!/usr/bin/env python3
"""Offline preview of the main layout for a given screen, without the simulator.

Usage: python3 tools/layout_preview.py <family> <width> <height> <out.png> [resource-folder]
  e.g. python3 tools/layout_preview.py round 454 454 /tmp/454.png

It reads the same resource and layout XML the app uses, draws the custom B612 bitmap
fonts exactly, and approximates Garmin's small system fonts (the blue unit labels).
Run it from the project folder. It is a design aid, not a substitute for the simulator.
"""
import os, re, sys
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

# which custom font the app assigns to each label (see onLayout in ppgInstrumentMain.mc)
LABEL_FONTS = {"lblVs": "B612Bold_m", "lblSpeed": "B612Bold_xl", "lblHeading": "B612Bold_m",
               "lblAltMsl": "B612Bold_xl", "lblCurrentTime": "B612Bold_s",
               "lblMissionTimer": "B612Bold_xl", "lblDistHome": "B612Bold_m", "lblDistTrack": "B612Bold_m"}
# widest realistic values
SAMPLE = {"lblVs": "-888", "lblSpeed": "88", "lblHeading": "888", "lblAltMsl": "8888",
          "lblCurrentTime": "12:38:58pm", "lblMissionTimer": "1:28", "lblDistHome": "88.8", "lblDistTrack": "888"}
COLORS = {"Graphics.COLOR_BLACK": (0, 0, 0), "Graphics.COLOR_WHITE": (255, 255, 255),
          "Graphics.COLOR_DK_BLUE": (0, 0, 170), "Graphics.COLOR_DK_GRAY": (85, 85, 85)}
SYSTEM = {"Graphics.FONT_XTINY": 0.050, "Graphics.FONT_TINY": 0.066}  # rough height as a fraction of width


class BMFont:
    def __init__(self, path):
        txt = open(path).read()
        self.chars = {}
        page = re.search(r'page id=0 file="([^"]+)"', txt).group(1)
        self.img = Image.open(os.path.join(os.path.dirname(path), page)).convert("L")
        for m in re.finditer(r"char id=(\d+)\s+x=(\d+)\s+y=(\d+)\s+width=(\d+)\s+height=(\d+)\s+xoffset=(-?\d+)\s+yoffset=(-?\d+)\s+xadvance=(\d+)", txt):
            self.chars[chr(int(m[1]))] = tuple(int(m[i]) for i in range(2, 9))

    def width(self, text):
        return sum(self.chars[c][6] for c in text if c in self.chars)

    def draw(self, canvas, x, y, text, color):
        for c in text:
            if c not in self.chars:
                continue
            gx, gy, w, h, xo, yo, adv = self.chars[c]
            glyph = self.img.crop((gx, gy, gx + w, gy + h))
            canvas.paste(Image.new("RGB", (w, h), color), (int(x + xo), int(y + yo)), glyph)
            x += adv


def coord(v, total, default=0):
    if v is None:
        return default
    if v == "center":
        return total / 2
    if v == "fill":
        return total
    return total * float(v[:-1]) / 100 if v.endswith("%") else float(v)


def load_xml(path):
    return ET.fromstring("<root>" + re.sub(r"<!--.*?-->", "", open(path).read(), flags=re.S) + "</root>")


def main():
    family, W, H, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    folder = sys.argv[5] if len(sys.argv) > 5 else "resources-%s-%dx%d" % (family, W, H)
    res_path = os.path.join(folder, "resource.xml")
    if not os.path.exists(res_path):
        folder, res_path = "resources", "resources/resource.xml"
    lay_path = os.path.join(folder, "layouts", "layout.xml")
    if not os.path.exists(lay_path):
        lay_path = "resources/layouts/layout.xml"
    res, lay = load_xml(res_path), load_xml(lay_path)

    fonts = {f.get("id"): BMFont(os.path.normpath(os.path.join(folder, f.get("filename")))) for f in res.iter("font")}
    shapes = {d.get("id"): d for d in res.iter("drawable-list")}
    img = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(img)
    roboto = os.path.expanduser("~/Library/Application Support/Garmin/ConnectIQ/Fonts/Roboto-Regular.ttf")
    if not os.path.exists(roboto):
        roboto = "resources/fonts/b612-master/fonts/ttf/B612-Regular.ttf"

    layout = [l for l in lay.iter("layout") if l.get("id") == "mainLayout"][0]
    problems = []
    for el in layout:
        if el.tag == "drawable" and el.get("id") in shapes:
            for s in shapes[el.get("id")].iter("shape"):
                x, y = coord(s.get("x"), W), coord(s.get("y"), H)
                w, h = coord(s.get("width"), W), coord(s.get("height"), H)
                d.rectangle((x, y, x + w - 1, y + h - 1), fill=COLORS[s.get("color")])
        elif el.tag == "label":
            lid, x, y = el.get("id"), coord(el.get("x"), W), coord(el.get("y"), H)
            color, just = COLORS[el.get("color")], el.get("justification")
            if lid in LABEL_FONTS:
                f, text = fonts[LABEL_FONTS[lid]], SAMPLE[lid]
                w = f.width(text)
                x0 = x - w if just.endswith("RIGHT") else (x - w / 2 if just.endswith("CENTER") else x)
                f.draw(img, x0, y, text, color)
                if x0 < 0 or x0 + w > W:
                    problems.append("%s runs off the screen (%d..%d of %d)" % (lid, x0, x0 + w, W))
            else:
                size = int(W * SYSTEM.get(el.get("font"), 0.05) * 1.25)
                f = ImageFont.truetype(roboto, size)
                w = f.getlength(el.get("text"))
                x0 = x - w if just.endswith("RIGHT") else (x - w / 2 if just.endswith("CENTER") else x)
                d.text((x0, y), el.get("text"), font=f, fill=color)
    if family != "rectangle":
        # show what a round screen hides
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, W - 1, H - 1), fill=255)
        img = Image.composite(img, Image.new("RGB", (W, H), (255, 0, 255)), mask)
    img.save(out)
    print("%s -> %s (resources: %s, layout: %s)" % (out, "OK" if not problems else "; ".join(problems), folder, lay_path))


if __name__ == "__main__":
    main()
