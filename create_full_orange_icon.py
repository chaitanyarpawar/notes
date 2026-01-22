#!/usr/bin/env python3
"""
Generate a PebbleNote icon with full orange background, "P" letter and "PebbleNote" text
"""
from PIL import Image, ImageDraw, ImageFont
import os

size = 1024
orange = (255, 149, 0)
white = (255, 255, 255)

# Create full orange background
img = Image.new('RGBA', (size, size), orange)
draw = ImageDraw.Draw(img)

# Find a suitable font
font_path = None
for fp in [
    "C:/Windows/Fonts/segoeuib.ttf",  # Segoe UI Bold
    "C:/Windows/Fonts/arialbd.ttf",   # Arial Bold
    "C:/Windows/Fonts/segoeui.ttf",
    "C:/Windows/Fonts/arial.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]:
    if os.path.exists(fp):
        font_path = fp
        break

# Draw the "P" (centered, large)
try:
    if font_path:
        font_large = ImageFont.truetype(font_path, 480)
    else:
        font_large = ImageFont.load_default()
    
    text_p = "P"
    # Use textbbox instead of textsize (Pillow 10+)
    bbox = draw.textbbox((0, 0), text_p, font=font_large)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (size - w) // 2
    y = (size - h) // 2 - 100  # Shift up to make room for text below
    draw.text((x, y), text_p, font=font_large, fill=white)
    print(f"✅ Drew 'P' at ({x}, {y})")
except Exception as e:
    print(f"Error drawing P: {e}")

# Draw "PebbleNote" below the P
try:
    if font_path:
        font_small = ImageFont.truetype(font_path, 100)
    else:
        font_small = ImageFont.load_default()
    
    text_name = "PebbleNote"
    bbox2 = draw.textbbox((0, 0), text_name, font=font_small)
    w2 = bbox2[2] - bbox2[0]
    h2 = bbox2[3] - bbox2[1]
    x2 = (size - w2) // 2
    y2 = size // 2 + 200  # Below the P
    draw.text((x2, y2), text_name, font=font_small, fill=white)
    print(f"✅ Drew 'PebbleNote' at ({x2}, {y2})")
except Exception as e:
    print(f"Error drawing PebbleNote: {e}")

# Save the icon
os.makedirs("assets/icon", exist_ok=True)
img.save("assets/icon/icon.png")
print("✅ Generated icon with P and PebbleNote: assets/icon/icon.png")
