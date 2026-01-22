"""
Generate density-specific splash images with P logo, app name, and tagline
"""
from PIL import Image, ImageDraw, ImageFont
import os
import urllib.request

# Configuration
BACKGROUND_COLOR = (255, 149, 0)  # #FF9500 Orange
TEXT_COLOR = (255, 255, 255)  # White
TAGLINE_COLOR = (255, 255, 255, 200)  # White with slight transparency for softer look
APP_NAME = "PebbleNote"
TAGLINE = "Capture Your Thoughts"

# Density configurations: (folder_name, width, height, logo_size, title_font_size, tagline_font_size)
# Using portrait dimensions for phone screens
# Increased logo sizes by ~40%
DENSITIES = [
    ("drawable-mdpi", 320, 480, 110, 28, 18),
    ("drawable-hdpi", 480, 800, 170, 42, 26),
    ("drawable-xhdpi", 720, 1280, 220, 56, 34),
    ("drawable-xxhdpi", 1080, 1920, 340, 84, 52),
    ("drawable-xxxhdpi", 1440, 2560, 450, 112, 68),
    ("drawable", 512, 910, 200, 46, 28),  # Fallback - portrait ratio
]

# Font URLs from Google Fonts
ANTON_URL = "https://github.com/google/fonts/raw/main/ofl/anton/Anton-Regular.ttf"
FONTS_DIR = "fonts_cache"

def download_font(url, filename):
    """Download a font file if not cached"""
    os.makedirs(FONTS_DIR, exist_ok=True)
    filepath = os.path.join(FONTS_DIR, filename)
    
    if not os.path.exists(filepath):
        print(f"📥 Downloading {filename}...")
        urllib.request.urlretrieve(url, filepath)
    
    return filepath

def get_font(font_path, size, fallback_paths=None):
    """Get a font, with fallback options"""
    try:
        if font_path and os.path.exists(font_path):
            return ImageFont.truetype(font_path, size)
    except:
        pass
    
    if fallback_paths:
        for fp in fallback_paths:
            try:
                if os.path.exists(fp):
                    return ImageFont.truetype(fp, size)
            except:
                continue
    
    return ImageFont.load_default()

def create_splash_image(logo_path, output_path, img_width, img_height, logo_size, title_size, tagline_size, anton_font_path):
    """Create a splash image with P logo, PebbleNote title, and tagline"""
    
    # Create background with RGBA to handle transparency
    img = Image.new('RGBA', (img_width, img_height), BACKGROUND_COLOR + (255,))
    
    # Load and resize the P logo
    logo = Image.open(logo_path).convert('RGBA')
    logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Calculate vertical spacing
    spacing = int(img_height * 0.008)  # 0.8% of height for tighter spacing between logo and title
    extra_spacing = int(img_height * 0.015)  # Extra space between texts
    
    # Get fonts
    anton_font = get_font(anton_font_path, title_size)
    # Use italic font for tagline
    tagline_font = get_font(None, tagline_size, [
        "C:/Windows/Fonts/segoeuii.ttf",  # Segoe UI Italic
        "C:/Windows/Fonts/segoeui.ttf",   # Segoe UI
        "C:/Windows/Fonts/arial.ttf",
    ])
    
    # Calculate text dimensions
    temp_draw = ImageDraw.Draw(img)
    
    title_bbox = temp_draw.textbbox((0, 0), APP_NAME, font=anton_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_height = title_bbox[3] - title_bbox[1]
    
    tagline_bbox = temp_draw.textbbox((0, 0), TAGLINE, font=tagline_font)
    tagline_width = tagline_bbox[2] - tagline_bbox[0]
    tagline_height = tagline_bbox[3] - tagline_bbox[1]
    
    # Calculate total content height
    total_height = logo_size + spacing + title_height + spacing + extra_spacing + tagline_height
    
    # Starting Y position to center everything vertically
    start_y = (img_height - total_height) // 2
    
    # Position logo (centered horizontally)
    logo_x = (img_width - logo_size) // 2
    logo_y = start_y
    
    # Paste logo with transparency
    img.paste(logo, (logo_x, logo_y), logo)
    
    # Position title below logo
    title_x = (img_width - title_width) // 2
    title_y = logo_y + logo_size + spacing
    
    # Position tagline below title with extra spacing
    tagline_x = (img_width - tagline_width) // 2
    tagline_y = title_y + title_height + spacing + extra_spacing
    
    # Draw text
    draw = ImageDraw.Draw(img)
    draw.text((title_x, title_y), APP_NAME, fill=TEXT_COLOR, font=anton_font)
    draw.text((tagline_x, tagline_y), TAGLINE, fill=TAGLINE_COLOR, font=tagline_font)
    
    # Convert to RGB and save
    final_img = Image.new('RGB', (img_width, img_height), BACKGROUND_COLOR)
    final_img.paste(img, mask=img.split()[3])
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    final_img.save(output_path, 'PNG')
    print(f"✅ Created: {output_path} ({img_width}x{img_height})")

def main():
    # Use the P logo image only
    logo_path = "assets/icon/p_logo.png"
    
    base_path = "android/app/src/main/res"
    
    if not os.path.exists(logo_path):
        print(f"❌ Logo not found: {logo_path}")
        print("   Please ensure p_logo.png exists in assets/icon/")
        return
    
    print(f"📱 Creating splash images...")
    print(f"   Logo: {logo_path}")
    print(f"   Background: #FF9500 (Orange)")
    print(f"   Title: '{APP_NAME}' (Anton font)")
    print(f"   Tagline: '{TAGLINE}'")
    print()
    
    # Download Anton font
    try:
        anton_path = download_font(ANTON_URL, "Anton-Regular.ttf")
    except Exception as e:
        print(f"⚠️ Could not download Anton font: {e}")
        anton_path = None
    
    for folder, img_width, img_height, logo_size, title_size, tagline_size in DENSITIES:
        output_path = os.path.join(base_path, folder, "launch_image.png")
        create_splash_image(logo_path, output_path, img_width, img_height, logo_size, title_size, tagline_size, anton_path)
    
    print()
    print("🎉 All splash images created successfully!")

if __name__ == "__main__":
    main()
