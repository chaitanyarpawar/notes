"""
Create the PebbleNote splash logo image with:
- Orange background (#FF9500)
- White stylized "P" logo
- "PebbleNote" text
- "Capture Your Thoughts" tagline
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_splash_logo():
    # Canvas size (will be scaled down for different densities)
    width, height = 768, 1366
    
    # Orange background
    bg_color = (255, 149, 0)  # #FF9500
    
    # Create canvas
    img = Image.new('RGB', (width, height), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Try to load the P logo from existing assets
    p_logo_path = 'assets/icon/p_logo.png'
    
    if os.path.exists(p_logo_path):
        # Load and resize the P logo
        p_logo = Image.open(p_logo_path).convert('RGBA')
        
        # Scale logo to appropriate size (about 25% of width)
        logo_size = int(width * 0.28)
        p_logo = p_logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
        
        # Center position for logo (slightly above center)
        logo_x = (width - logo_size) // 2
        logo_y = int(height * 0.32)
        
        # Paste logo with transparency
        img.paste(p_logo, (logo_x, logo_y), p_logo)
        print(f"✅ Added P logo from {p_logo_path}")
    else:
        print(f"⚠️ P logo not found at {p_logo_path}")
    
    # Try to load fonts
    try:
        # Try system fonts for "PebbleNote" title
        title_font_paths = [
            'C:/Windows/Fonts/arialbd.ttf',
            'C:/Windows/Fonts/Arial Bold.ttf',
            '/System/Library/Fonts/Helvetica.ttc',
        ]
        title_font = None
        for path in title_font_paths:
            if os.path.exists(path):
                title_font = ImageFont.truetype(path, 72)
                break
        if not title_font:
            title_font = ImageFont.load_default()
        
        # Try system fonts for tagline (italic)
        tagline_font_paths = [
            'C:/Windows/Fonts/ariali.ttf',
            'C:/Windows/Fonts/Arial Italic.ttf',
            '/System/Library/Fonts/Helvetica.ttc',
        ]
        tagline_font = None
        for path in tagline_font_paths:
            if os.path.exists(path):
                tagline_font = ImageFont.truetype(path, 36)
                break
        if not tagline_font:
            tagline_font = ImageFont.load_default()
            
    except Exception as e:
        print(f"Font loading error: {e}")
        title_font = ImageFont.load_default()
        tagline_font = ImageFont.load_default()
    
    # Draw "PebbleNote" title
    title_text = "PebbleNote"
    title_bbox = draw.textbbox((0, 0), title_text, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    title_y = int(height * 0.54)
    
    # White text with slight shadow for depth
    draw.text((title_x + 2, title_y + 2), title_text, fill=(200, 120, 0), font=title_font)
    draw.text((title_x, title_y), title_text, fill='white', font=title_font)
    
    # Draw "Capture Your Thoughts" tagline
    tagline_text = "Capture Your Thoughts"
    tagline_bbox = draw.textbbox((0, 0), tagline_text, font=tagline_font)
    tagline_width = tagline_bbox[2] - tagline_bbox[0]
    tagline_x = (width - tagline_width) // 2
    tagline_y = title_y + 80
    
    # Slightly transparent white for tagline
    draw.text((tagline_x, tagline_y), tagline_text, fill=(255, 255, 255, 220), font=tagline_font)
    
    # Save the splash logo
    output_path = 'assets/icon/splash_logo.png'
    img.save(output_path, 'PNG', optimize=True)
    print(f"✅ Created splash logo: {output_path}")
    print(f"   Size: {width}x{height}")
    
    return output_path

if __name__ == '__main__':
    create_splash_logo()
