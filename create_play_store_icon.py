"""
Create a Google Play compliant icon for PebbleNote app
Following specifications from: https://developer.android.com/distribute/google-play/resources/icon-design-specifications
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_play_store_icon():
    # Google Play icon specifications
    size = 512  # 512x512px required
    
    # Create a new image with orange background (brand color)
    img = Image.new('RGB', (size, size), color='#FF9500')
    draw = ImageDraw.Draw(img)
    
    # Create the 'P' shape for PebbleNote
    # Using a more modern, bold design suitable for app icon
    
    # Background circle with slight gradient effect (using overlapping circles)
    center = size // 2
    
    # Draw the white 'P' letter
    # Using geometric shapes to create a bold, recognizable 'P'
    
    # P letter dimensions
    letter_size = int(size * 0.65)  # 65% of canvas for good visibility
    letter_x = int(size * 0.20)  # 20% from left
    letter_y = int(size * 0.15)  # 15% from top
    
    # Vertical stem of P
    stem_width = int(letter_size * 0.25)
    stem_height = letter_size
    stem_rect = [
        letter_x,
        letter_y,
        letter_x + stem_width,
        letter_y + stem_height
    ]
    draw.rounded_rectangle(stem_rect, radius=stem_width//3, fill='white')
    
    # Top bowl of P (rounded part)
    bowl_diameter = int(letter_size * 0.55)
    bowl_x = letter_x + stem_width // 2
    bowl_y = letter_y
    
    # Outer circle
    draw.ellipse([
        bowl_x,
        bowl_y,
        bowl_x + bowl_diameter,
        bowl_y + bowl_diameter
    ], fill='white')
    
    # Inner circle (hole in P)
    hole_diameter = int(bowl_diameter * 0.45)
    hole_offset = int((bowl_diameter - hole_diameter) / 2)
    draw.ellipse([
        bowl_x + hole_offset + stem_width//4,
        bowl_y + hole_offset,
        bowl_x + hole_offset + stem_width//4 + hole_diameter,
        bowl_y + hole_offset + hole_diameter
    ], fill='#FF9500')
    
    # Add a subtle highlight/3D effect on the top-left
    highlight_color = '#FFB347'  # Lighter orange
    draw.arc([10, 10, size-10, size-10], start=215, end=325, fill=highlight_color, width=8)
    
    # Save the icon
    output_path = 'assets/icon/icon_512.png'
    img.save(output_path, 'PNG', optimize=True, quality=100)
    print(f"✅ Created Google Play icon: {output_path}")
    print(f"   Size: {size}x{size}px")
    print(f"   Format: PNG (32-bit)")
    print(f"   File size: {os.path.getsize(output_path) / 1024:.2f} KB")
    
    # Also create the standard icon.png (same file, just copy)
    standard_path = 'assets/icon/icon.png'
    img.save(standard_path, 'PNG', optimize=True, quality=100)
    print(f"✅ Created standard icon: {standard_path}")
    
    # Create adaptive icon foreground (transparent background with just the P)
    fg_img = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(fg_img)
    
    # Draw white P on transparent background
    # Vertical stem
    fg_draw.rounded_rectangle(stem_rect, radius=stem_width//3, fill='white')
    
    # Outer circle
    fg_draw.ellipse([
        bowl_x,
        bowl_y,
        bowl_x + bowl_diameter,
        bowl_y + bowl_diameter
    ], fill='white')
    
    # Inner circle (hole in P) - now transparent
    fg_draw.ellipse([
        bowl_x + hole_offset + stem_width//4,
        bowl_y + hole_offset,
        bowl_x + hole_offset + stem_width//4 + hole_diameter,
        bowl_y + hole_offset + hole_diameter
    ], fill=(0, 0, 0, 0))
    
    fg_path = 'assets/icon/icon_foreground.png'
    fg_img.save(fg_path, 'PNG')
    print(f"✅ Created adaptive foreground: {fg_path}")
    
    # Create splash screen version (no white background)
    splash_img = img.copy()
    splash_path = 'assets/icon/icon_splash.png'
    splash_img.save(splash_path, 'PNG', optimize=True, quality=100)
    print(f"✅ Created splash screen icon: {splash_path}")
    
    print("\n📋 Next steps:")
    print("1. Run: flutter pub run flutter_launcher_icons")
    print("2. Verify the icon looks good on different devices")
    print("3. Upload icon_512.png to Google Play Console")

if __name__ == '__main__':
    # Ensure assets/icon directory exists
    os.makedirs('assets/icon', exist_ok=True)
    create_play_store_icon()
