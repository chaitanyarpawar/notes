"""
Generate splash screen design mockup for PebbleNote
Shows the new layout with centered logo icon on white background
"""
from PIL import Image, ImageDraw, ImageFont
import os

# Create 1080x1920 splash screen mockup (9:16 ratio)
width, height = 1080, 1920

# Create white background
img = Image.new('RGB', (width, height), color='#FFFFFF')
draw = ImageDraw.Draw(img)

# Try to load the actual icon
icon_path = 'assets/icon/icon_home.png'
if os.path.exists(icon_path):
    icon = Image.open(icon_path)
    # Resize to 600x600 (300 * 2 for mockup scale) - NO BORDER
    icon = icon.resize((600, 600), Image.Resampling.LANCZOS)
    
    # Calculate position to center the icon
    icon_x = (width - 600) // 2
    icon_y = (height - 600) // 2 - 120  # Slightly above center
    
    # Paste icon (with alpha if available) - no clipping/border
    if icon.mode == 'RGBA':
        img.paste(icon, (icon_x, icon_y), icon)
    else:
        img.paste(icon, (icon_x, icon_y))

# Try to use elegant serif fonts - Playfair Display style (Georgia, Times New Roman as fallback)
font_tagline = None
for font_name in ['georgia.ttf', 'georgiaz.ttf', 'times.ttf', 'timesi.ttf', 'palatino.ttf', 'arial.ttf']:
    try:
        font_tagline = ImageFont.truetype(font_name, 56)  # Larger font size
        break
    except:
        continue
if font_tagline is None:
    font_tagline = ImageFont.load_default()

# Draw tagline in orange color - elegant serif style
tagline = "Capture Your Thoughts"
tagline_bbox = draw.textbbox((0, 0), tagline, font=font_tagline)
tagline_width = tagline_bbox[2] - tagline_bbox[0]
tagline_x = (width - tagline_width) // 2
tagline_y = height // 2 + 260

draw.text((tagline_x, tagline_y), tagline, fill='#FF9500', font=font_tagline)

# Save mockup
output_path = 'assets/icon/splash_screen_mockup.png'
img.save(output_path, 'PNG')
print(f"✅ Splash screen mockup saved to: {output_path}")
print(f"   Size: {width}x{height}px")
print(f"   Design: Centered PebbleNotes icon (220x220)")
print(f"   Background: White (#FFFFFF)")
print(f"   Tagline: 'Capture Your Thoughts' (Orange)")
