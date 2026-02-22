# This script creates a 1024x500 feature graphic for Play Store using the provided logo
from PIL import Image, ImageDraw, ImageFont

# Load logo
logo = Image.open('assets/icon/icon_ic.png').convert('RGBA')

# Create orange background
feature = Image.new('RGBA', (1024, 500), '#FF9800')

# Resize logo to fit nicely (about 300px tall)
logo_ratio = logo.width / logo.height
logo_height = 300
logo_width = int(logo_ratio * logo_height)
logo = logo.resize((logo_width, logo_height), Image.LANCZOS)

# Paste logo centered horizontally, 60px from top
logo_x = (1024 - logo_width) // 2
logo_y = 60
feature.paste(logo, (logo_x, logo_y), logo)


# Add PebbleNote text below logo
font = ImageFont.truetype('arialbd.ttf', 64)
draw = ImageDraw.Draw(feature)
text = 'PebbleNote'
text_bbox = draw.textbbox((0, 0), text, font=font)
text_width = text_bbox[2] - text_bbox[0]
text_height = text_bbox[3] - text_bbox[1]
text_x = (1024 - text_width) // 2
text_y = logo_y + logo_height + 20
draw.text((text_x, text_y), text, font=font, fill='white')

# Add tagline
font2 = ImageFont.truetype('arial.ttf', 36)
tagline = 'Capture Your Thoughts'
tagline_bbox = draw.textbbox((0, 0), tagline, font=font2)
tagline_width = tagline_bbox[2] - tagline_bbox[0]
tagline_x = (1024 - tagline_width) // 2
tagline_y = text_y + text_height + 10
draw.text((tagline_x, tagline_y), tagline, font=font2, fill='white')

# Save as PNG
feature.save('feature_graphic.png')
print('Feature graphic created: feature_graphic.png')
