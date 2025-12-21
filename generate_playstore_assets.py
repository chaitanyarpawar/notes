#!/usr/bin/env python3
"""
Generate all Play Store assets for PebbleNote app
- App icons in all required sizes
- Play Store icon (512x512)
- Feature graphic (1024x500)
"""

import os
import math

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Installing Pillow...")
    os.system("pip install Pillow")
    from PIL import Image, ImageDraw, ImageFont


def draw_pebblenote_icon(draw, size, with_background=True):
    """Draw the PebbleNote icon design matching the app's brand icon"""
    
    # Colors
    orange = (255, 149, 0)  # #FF9500
    line_color = (232, 160, 64)  # Slightly darker orange for lines
    white = (255, 255, 255)
    yellow = (255, 217, 102)  # For pencil tip
    
    margin = size * 0.05
    corner_radius = size * 0.22
    
    if with_background:
        # Draw orange rounded square background
        draw.rounded_rectangle(
            [margin, margin, size - margin, size - margin],
            radius=corner_radius,
            fill=orange
        )
    
    # Draw horizontal lines
    line_thickness = size * 0.028
    left_pad = size * 0.17
    right_pad = size * 0.17
    top_pad = size * 0.20
    line_gap = size * 0.13
    
    for i in range(5):
        y = top_pad + (line_gap * i)
        draw.rounded_rectangle(
            [left_pad, y, size - right_pad, y + line_thickness],
            radius=line_thickness / 2,
            fill=line_color
        )
    
    # Draw pencil (white body with yellow tip)
    pencil_length = size * 0.55
    pencil_thickness = size * 0.10
    
    # Calculate pencil position (diagonal from upper-left to lower-right)
    center_x = size * 0.62
    center_y = size * 0.65
    angle = math.pi / 4  # 45 degrees
    
    # Pencil endpoints
    half_len = pencil_length / 2
    dx = math.cos(angle) * half_len
    dy = math.sin(angle) * half_len
    
    start_x = center_x - dx
    start_y = center_y - dy
    end_x = center_x + dx
    end_y = center_y + dy
    
    # Draw pencil body (thick white line with rounded caps)
    draw.line(
        [(start_x, start_y), (end_x, end_y)],
        fill=white,
        width=int(pencil_thickness)
    )
    
    # Draw rounded caps
    cap_radius = pencil_thickness / 2
    draw.ellipse(
        [start_x - cap_radius, start_y - cap_radius,
         start_x + cap_radius, start_y + cap_radius],
        fill=white
    )
    draw.ellipse(
        [end_x - cap_radius, end_y - cap_radius,
         end_x + cap_radius, end_y + cap_radius],
        fill=white
    )
    
    # Draw yellow pencil tip (triangle)
    tip_size = pencil_thickness * 1.2
    tip_x = end_x + math.cos(angle) * (tip_size * 0.5)
    tip_y = end_y + math.sin(angle) * (tip_size * 0.5)
    
    # Triangle points for tip
    perp_angle = angle + math.pi / 2
    perp_dx = math.cos(perp_angle) * (pencil_thickness * 0.5)
    perp_dy = math.sin(perp_angle) * (pencil_thickness * 0.5)
    
    tip_points = [
        (end_x + perp_dx, end_y + perp_dy),
        (end_x - perp_dx, end_y - perp_dy),
        (tip_x, tip_y)
    ]
    draw.polygon(tip_points, fill=yellow)
    
    # Draw yellow dot on pencil body
    dot_x = center_x - dx * 0.3
    dot_y = center_y - dy * 0.3
    dot_radius = pencil_thickness * 0.25
    draw.ellipse(
        [dot_x - dot_radius, dot_y - dot_radius,
         dot_x + dot_radius, dot_y + dot_radius],
        fill=yellow
    )


def create_app_icon(output_path, size):
    """Create app icon at specified size"""
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_pebblenote_icon(draw, size)
    image.save(output_path, 'PNG')
    print(f"Created: {output_path} ({size}x{size})")


def create_playstore_icon():
    """Create 512x512 Play Store icon"""
    size = 512
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_pebblenote_icon(draw, size)
    
    output_dir = "assets/playstore"
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "app_icon_512.png")
    image.save(output_path, 'PNG')
    print(f"Created Play Store icon: {output_path}")
    return output_path


def create_feature_graphic():
    """Create 1024x500 feature graphic for Play Store"""
    width, height = 1024, 500
    orange = (255, 149, 0)
    
    image = Image.new('RGB', (width, height), orange)
    draw = ImageDraw.Draw(image)
    
    # Draw icon on the left
    icon_size = 300
    icon_x = 100
    icon_y = (height - icon_size) // 2
    
    # Create a temporary icon
    icon_img = Image.new('RGBA', (icon_size, icon_size), (0, 0, 0, 0))
    icon_draw = ImageDraw.Draw(icon_img)
    
    # Draw icon with lighter background for contrast
    light_orange = (255, 220, 180)
    corner_radius = icon_size * 0.22
    margin = icon_size * 0.05
    icon_draw.rounded_rectangle(
        [margin, margin, icon_size - margin, icon_size - margin],
        radius=corner_radius,
        fill=light_orange
    )
    
    # Draw the pencil and lines in darker orange
    draw_pebblenote_icon(icon_draw, icon_size, with_background=False)
    
    # Paste icon onto feature graphic
    image.paste(icon_img, (icon_x, icon_y), icon_img)
    
    # Add app name text
    try:
        # Try different font options
        font_paths = [
            "C:\\Windows\\Fonts\\segoeui.ttf",
            "C:\\Windows\\Fonts\\arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ]
        font = None
        for fp in font_paths:
            if os.path.exists(fp):
                font = ImageFont.truetype(fp, 72)
                break
        if font is None:
            font = ImageFont.load_default()
            
        # Draw "PebbleNote" text
        text = "PebbleNote"
        text_color = (255, 255, 255)  # White
        text_x = icon_x + icon_size + 80
        text_y = height // 2 - 60
        draw.text((text_x, text_y), text, fill=text_color, font=font)
        
        # Draw tagline
        try:
            small_font = ImageFont.truetype(font_paths[0] if os.path.exists(font_paths[0]) else font_paths[1], 32)
        except:
            small_font = font
        tagline = "Capture Your Thoughts"
        draw.text((text_x, text_y + 90), tagline, fill=(255, 240, 200), font=small_font)
        
    except Exception as e:
        print(f"Font error: {e}")
    
    output_dir = "assets/playstore"
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "feature_graphic.png")
    image.save(output_path, 'PNG')
    print(f"Created feature graphic: {output_path}")
    return output_path


def create_android_icons():
    """Create Android launcher icons in all required sizes"""
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    base_path = "android/app/src/main/res"
    
    for folder, size in sizes.items():
        folder_path = os.path.join(base_path, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # Create launcher icon
        output_path = os.path.join(folder_path, "ic_launcher.png")
        create_app_icon(output_path, size)
        
        # Also create round icon (same as regular for now)
        round_path = os.path.join(folder_path, "ic_launcher_round.png")
        create_app_icon(round_path, size)


def create_ios_icons():
    """Create iOS app icons"""
    sizes = [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
    
    ios_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_path, exist_ok=True)
    
    for size in sizes:
        output_path = os.path.join(ios_path, f"Icon-App-{size}x{size}@1x.png")
        create_app_icon(output_path, size)


def main():
    print("=" * 50)
    print("PebbleNote - Play Store Asset Generator")
    print("=" * 50)
    print()
    
    # Create Play Store assets directory
    os.makedirs("assets/playstore", exist_ok=True)
    
    # 1. Create Play Store icon (512x512)
    print("\n[1/4] Creating Play Store icon (512x512)...")
    create_playstore_icon()
    
    # 2. Create Feature Graphic (1024x500)
    print("\n[2/4] Creating Feature Graphic (1024x500)...")
    create_feature_graphic()
    
    # 3. Create Android launcher icons
    print("\n[3/4] Creating Android launcher icons...")
    create_android_icons()
    
    # 4. Create main app icon (1024x1024 for store)
    print("\n[4/4] Creating high-res icon (1024x1024)...")
    os.makedirs("assets/icon", exist_ok=True)
    create_app_icon("assets/icon/app_icon.png", 1024)
    create_app_icon("assets/playstore/app_icon_1024.png", 1024)
    
    print("\n" + "=" * 50)
    print("✅ All assets created successfully!")
    print("=" * 50)
    print("\nGenerated files:")
    print("  - assets/playstore/app_icon_512.png (Play Store icon)")
    print("  - assets/playstore/app_icon_1024.png (High-res icon)")
    print("  - assets/playstore/feature_graphic.png (Feature graphic)")
    print("  - android/app/src/main/res/mipmap-*/ic_launcher.png (Android icons)")
    print("  - assets/icon/app_icon.png (Main app icon)")


if __name__ == "__main__":
    main()
