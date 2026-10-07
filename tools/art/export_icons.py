"""Turn the rendered icon master into every platform size.

    RENDER_ART=1 flutter test test/tool_render_icon_test.dart   # -> tools/art/icon_1024.png
    python tools/art/export_icons.py

Writes assets/images/icon_1024.png (opaque RGB — App Store rejects alpha), every
size referenced by ios/.../AppIcon.appiconset/Contents.json, and the five Android
legacy mipmaps.
"""
import json, os, sys
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "tools/art/icon_1024.png")

im = Image.open(src).convert("RGB").resize((1024, 1024), Image.LANCZOS)
os.makedirs(os.path.join(ROOT, "assets/images"), exist_ok=True)
im.save(os.path.join(ROOT, "assets/images/icon_1024.png"), optimize=True)


def sized(px):
    out = im.resize((px, px), Image.LANCZOS)
    if px <= 120:  # keep borders crisp through heavy downscales
        out = out.filter(ImageFilter.UnsharpMask(radius=0.6, percent=60, threshold=1))
    return out.convert("RGB")


iconset = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
for e in json.load(open(os.path.join(iconset, "Contents.json")))["images"]:
    pt = float(e["size"].split("x")[0]); scale = int(e["scale"][0])
    px = round(pt * scale)
    sized(px).save(os.path.join(iconset, e["filename"]), optimize=True)
    print("ios", e["filename"], px)

res = os.path.join(ROOT, "android/app/src/main/res")
for d, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    sized(px).save(os.path.join(res, f"mipmap-{d}", "ic_launcher.png"), optimize=True)
    print("android", d, px)
