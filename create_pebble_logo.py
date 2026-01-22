#!/usr/bin/env python3
"""
Generate PebbleNote icon with full orange background (no white corners)
Recreates the stylized P logo with PebbleNote text
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math

def create_PebbleNote_icon():
    size = 1024
    orange = (255, 149, 0)  # Main orange
    dark_orange = (230, 120, 0)  # Darker orange for gradient effect
    white = (255, 255, 255)
    
    # Create full orange background - NO transparency, NO rounded corners
    img = Image.new('RGB', (size, size), orange)
    draw = ImageDraw.Draw(img)
    
    # Add subtle gradient from top-left to bottom-right
    for y in range(size):
        for x in range(size):
            # Calculate gradient factor
            factor = (x + y) / (2 * size)
            r = int(orange[0] - (orange[0] - dark_orange[0]) * factor * 0.3)
            g = int(orange[1] - (orange[1] - dark_orange[1]) * factor * 0.3)
            b = int(orange[2] - (orange[2] - dark_orange[2]) * factor * 0.3)
            img.putpixel((x, y), (r, g, b))
    
    draw = ImageDraw.Draw(img)
    
    # Draw stylized "P" logo
    # The P is a rounded shape with a curved tail
    center_x = size // 2
    center_y = size // 2 - 80  # Shift up to make room for text
    
    # P dimensions
    p_width = 380
    p_height = 420
    
    # Draw the main P shape (white with shadow effect)
    # First draw a shadow
    shadow_offset = 8
    
    # Create the P path - main body
    p_left = center_x - p_width // 2
    p_top = center_y - p_height // 2
    p_right = center_x + p_width // 2
    p_bottom = center_y + p_height // 2
    
    # Draw the P as overlapping shapes to create the stylized look
    # Main circular part of P
    circle_radius = 160
    circle_center_x = center_x + 20
    circle_center_y = center_y - 40
    
    # Shadow for depth
    shadow_color = (200, 100, 0, 100)
    
    # Draw the stem of P (vertical bar with curve)
    stem_width = 100
    stem_left = center_x - 120
    
    # Draw main P shape using ellipses and rectangles
    # Outer circle of P (the bowl)
    draw.ellipse([
        circle_center_x - circle_radius - 40,
        circle_center_y - circle_radius - 20,
        circle_center_x + circle_radius + 60,
        circle_center_y + circle_radius + 40
    ], fill=white)
    
    # Inner cutout (orange) to create the P bowl
    inner_radius = 70
    draw.ellipse([
        circle_center_x - inner_radius + 30,
        circle_center_y - inner_radius + 20,
        circle_center_x + inner_radius + 50,
        circle_center_y + inner_radius + 40
    ], fill=img.getpixel((circle_center_x, circle_center_y)))
    
    # Stem of P curving down
    # Draw as a curved shape
    stem_points = [
        (stem_left, center_y - 180),  # Top of stem
        (stem_left + stem_width, center_y - 180),
        (stem_left + stem_width, center_y + 180),  # Bottom curves
        (stem_left + stem_width - 20, center_y + 220),
        (stem_left + 60, center_y + 240),  # Curve out
        (stem_left + 120, center_y + 260),
        (stem_left + 180, center_y + 240),  # Tail end
        (stem_left + 160, center_y + 200),
        (stem_left, center_y + 160),
        (stem_left, center_y - 180),
    ]
    draw.polygon(stem_points, fill=white)
    
    # Draw "PebbleNote" text
    try:
        font_path = None
        for fp in [
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/arialbd.ttf", 
            "C:/Windows/Fonts/segoeui.ttf",
            "C:/Windows/Fonts/arial.ttf",
        ]:
            if os.path.exists(fp):
                font_path = fp
                break
        
        if font_path:
            font = ImageFont.truetype(font_path, 85)
        else:
            font = ImageFont.load_default()
        
        text = "PebbleNote"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = (size - text_width) // 2
        text_y = size - 180
        
        draw.text((text_x, text_y), text, font=font, fill=white)
        print(f"✅ Drew 'PebbleNote' text")
        
    except Exception as e:
        print(f"Font error: {e}")
    
    # Save
    os.makedirs("assets/icon", exist_ok=True)
    img.save("assets/icon/icon.png", "PNG")
    print(f"✅ Generated icon: assets/icon/icon.png ({size}x{size})")
    
    return img

if __name__ == "__main__":
    create_PebbleNote_icon()
