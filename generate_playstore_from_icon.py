#!/usr/bin/env python3
"""
Generate Play Store assets from existing icon file
Uses assets/icon/icon.png as the source
"""

import os

try:
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
except ImportError:
    print("Installing Pillow...")
    os.system("pip install Pillow")
    from PIL import Image, ImageDraw, ImageFont, ImageFilter


def resize_icon(source_path, output_path, size):
    """Resize icon to specified size with high quality"""
    img = Image.open(source_path)
    
    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Use high-quality resampling
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(output_path, 'PNG')
    print(f"Created: {output_path} ({size}x{size})")


def create_playstore_icons(source_icon):
    """Create Play Store icons from source icon"""
    output_dir = "assets/playstore"
    os.makedirs(output_dir, exist_ok=True)
    
    # 512x512 Play Store icon
    resize_icon(source_icon, os.path.join(output_dir, "app_icon_512.png"), 512)
    
    # 1024x1024 high-res icon
    resize_icon(source_icon, os.path.join(output_dir, "app_icon_1024.png"), 1024)


def create_feature_graphic(source_icon):
    """Create 1024x500 feature graphic for Play Store - Modern clean design"""
    width, height = 1024, 500
    
    # Modern clean white/light gray gradient background
    image = Image.new('RGB', (width, height), (255, 255, 255))
    draw = ImageDraw.Draw(image)
    
    # Create subtle gradient from light gray to white
    for y in range(height):
        # Subtle vertical gradient
        gray_value = int(248 + (y / height) * 7)  # 248 to 255
        for x in range(width):
            # Add slight horizontal variation for depth
            h_factor = abs(x - width/2) / (width/2)
            final_gray = int(gray_value - h_factor * 3)
            image.putpixel((x, y), (final_gray, final_gray, final_gray))
    
    draw = ImageDraw.Draw(image)
    
    # Load icon
    icon = Image.open(source_icon).convert('RGBA')
    
    # Resize icon
    icon_size = 300
    icon_resized = icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Position icon on the left
    icon_x = 150
    icon_y = (height - icon_size) // 2
    
    # Create elegant shadow effect
    shadow_size = icon_size + 40
    shadow = Image.new('RGBA', (shadow_size, shadow_size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle([20, 20, shadow_size - 20, shadow_size - 20], 
                                   radius=50, fill=(0, 0, 0, 25))
    shadow = shadow.filter(ImageFilter.GaussianBlur(15))
    
    # Paste shadow and icon
    image.paste(shadow, (icon_x - 20, icon_y - 10), shadow)
    
    # Create a white backing for the icon for clean look
    icon_bg = Image.new('RGBA', (icon_size, icon_size), (255, 255, 255, 255))
    image.paste(icon_bg, (icon_x, icon_y))
    image.paste(icon_resized, (icon_x, icon_y), icon_resized)
    
    # Add app name text with modern styling
    try:
        # Try to get a nice font
        font_paths_bold = [
            "C:\\Windows\\Fonts\\segoeuib.ttf",
            "C:\\Windows\\Fonts\\arialbd.ttf",
            "C:\\Windows\\Fonts\\segoeui.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        ]
        font_paths_regular = [
            "C:\\Windows\\Fonts\\segoeui.ttf",
            "C:\\Windows\\Fonts\\arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ]
        
        title_font = None
        for fp in font_paths_bold:
            if os.path.exists(fp):
                title_font = ImageFont.truetype(fp, 72)
                break
        if title_font is None:
            title_font = ImageFont.load_default()
        
        tagline_font = None
        for fp in font_paths_regular:
            if os.path.exists(fp):
                tagline_font = ImageFont.truetype(fp, 28)
                break
        if tagline_font is None:
            tagline_font = title_font
        
        # App name - dark gray for modern look
        text = "PebbleNotes"
        text_color = (51, 51, 51)  # Dark gray #333333
        text_x = icon_x + icon_size + 80
        text_y = height // 2 - 55
        
        draw.text((text_x, text_y), text, fill=text_color, font=title_font)
        
        # Tagline - lighter gray
        tagline = "Capture Your Thoughts"
        tagline_color = (128, 128, 128)  # Medium gray
        draw.text((text_x, text_y + 85), tagline, fill=tagline_color, font=tagline_font)
        
        # Add subtle orange accent line under the title
        orange_accent = (255, 149, 0)  # Brand orange
        line_y = text_y + 80
        draw.rectangle([text_x, line_y, text_x + 60, line_y + 3], fill=orange_accent)
        
    except Exception as e:
        print(f"Font error (using default): {e}")
    
    output_dir = "assets/playstore"
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "feature_graphic.png")
    image.save(output_path, 'PNG')
    print(f"Created feature graphic: {output_path}")


def create_android_icons(source_icon):
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
        resize_icon(source_icon, output_path, size)
        
        # Also create round icon
        round_path = os.path.join(folder_path, "ic_launcher_round.png")
        resize_icon(source_icon, round_path, size)


def create_ios_icons(source_icon):
    """Create iOS app icons in all required sizes"""
    # iOS requires specific sizes with @1x, @2x, @3x variants
    ios_icons = [
        # iPhone
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        # iPad
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        # App Store
        ("Icon-App-1024x1024@1x.png", 1024),
        # Additional sizes for compatibility
        ("Icon-App-50x50@1x.png", 50),
        ("Icon-App-50x50@2x.png", 100),
        ("Icon-App-57x57@1x.png", 57),
        ("Icon-App-57x57@2x.png", 114),
        ("Icon-App-72x72@1x.png", 72),
        ("Icon-App-72x72@2x.png", 144),
        ("Icon-App-60x60@1x.png", 60),
        ("Icon-App-80x80@1x.png", 80),
        ("Icon-App-87x87@1x.png", 87),
        ("Icon-App-120x120@1x.png", 120),
        ("Icon-App-152x152@1x.png", 152),
        ("Icon-App-167x167@1x.png", 167),
        ("Icon-App-180x180@1x.png", 180),
    ]
    
    ios_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_path, exist_ok=True)
    
    for filename, size in ios_icons:
        output_path = os.path.join(ios_path, filename)
        resize_icon(source_icon, output_path, size)


def create_web_icons(source_icon):
    """Create web icons"""
    web_path = "web/icons"
    os.makedirs(web_path, exist_ok=True)
    
    sizes = [192, 512]
    for size in sizes:
        output_path = os.path.join(web_path, f"Icon-{size}.png")
        resize_icon(source_icon, output_path, size)
    
    # Also create maskable icons
    for size in sizes:
        output_path = os.path.join(web_path, f"Icon-maskable-{size}.png")
        resize_icon(source_icon, output_path, size)
    
    # Create favicon (16x16 and 32x32, save as ICO or PNG)
    favicon_path = "web/favicon.png"
    resize_icon(source_icon, favicon_path, 32)
    print(f"Created: {favicon_path} (32x32)")


def main():
    print("=" * 50)
    print("PebbleNote - Play Store Asset Generator")
    print("(From existing icon)")
    print("=" * 50)
    print()
    
    source_icon = "assets/icon/icon.png"
    
    if not os.path.exists(source_icon):
        print(f"Error: Source icon not found at {source_icon}")
        return
    
    print(f"Source icon: {source_icon}")
    
    # Get source icon info
    img = Image.open(source_icon)
    print(f"Source size: {img.width}x{img.height}")
    print()
    
    # Create Play Store assets directory
    os.makedirs("assets/playstore", exist_ok=True)
    
    # 1. Create Play Store icons
    print("\n[1/5] Creating Play Store icons...")
    create_playstore_icons(source_icon)
    
    # 2. Create Feature Graphic
    print("\n[2/5] Creating Feature Graphic (1024x500)...")
    create_feature_graphic(source_icon)
    
    # 3. Create Android launcher icons
    print("\n[3/5] Creating Android launcher icons...")
    create_android_icons(source_icon)
    
    # 4. Create iOS icons
    print("\n[4/5] Creating iOS icons...")
    create_ios_icons(source_icon)
    
    # 5. Create Web icons
    print("\n[5/5] Creating Web icons...")
    create_web_icons(source_icon)
    
    print("\n" + "=" * 50)
    print("✅ All assets created successfully!")
    print("=" * 50)
    print("\nGenerated files:")
    print("  Play Store:")
    print("    - assets/playstore/app_icon_512.png")
    print("    - assets/playstore/app_icon_1024.png")
    print("    - assets/playstore/feature_graphic.png")
    print("  Android:")
    print("    - android/app/src/main/res/mipmap-*/ic_launcher.png")
    print("    - android/app/src/main/res/mipmap-*/ic_launcher_round.png")
    print("  iOS:")
    print("    - ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png")
    print("  Web:")
    print("    - web/icons/Icon-*.png")


if __name__ == "__main__":
    main()
