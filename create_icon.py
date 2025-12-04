#!/usr/bin/env python3
"""
Simple script to create an app icon for PebbleNote
Creates a 1024x1024 PNG icon with a clean notepad design
and a prominent "P" initial.
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
except ImportError:
    print("PIL (Pillow) not found. Installing...")
    os.system("pip install Pillow")
    from PIL import Image, ImageDraw, ImageFont
    
def create_pebblenote_icon():
    # Create a 1024x1024 image with transparent background
    size = 1024
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Define colors
    primary_color = (74, 144, 226)  # Blue theme color
    secondary_color = (255, 255, 255)  # White
    accent_color = (255, 193, 7)  # Amber accent
    shadow_color = (0, 0, 0, 50)  # Semi-transparent black
    
    # Draw shadow (offset rectangle)
    shadow_offset = 8
    margin = 100
    draw.rounded_rectangle([
        margin + shadow_offset, 
        margin + shadow_offset, 
        size - margin + shadow_offset, 
        size - margin + shadow_offset
    ], radius=60, fill=shadow_color)
    
    # Draw main notepad background
    draw.rounded_rectangle([
        margin, margin, 
        size - margin, size - margin
    ], radius=60, fill=secondary_color)
    
    # Draw notepad spiral binding holes
    hole_y_start = margin + 80
    hole_spacing = 60
    hole_radius = 15
    
    for i in range(10):
        y = hole_y_start + (i * hole_spacing)
        if y < size - margin - 60:
            draw.ellipse([
                margin + 40, y - hole_radius,
                margin + 40 + hole_radius * 2, y + hole_radius
            ], fill=primary_color)
    
    # Draw notepad lines
    line_start_x = margin + 120
    line_end_x = size - margin - 40
    line_y_start = margin + 150
    line_spacing = 45
    line_width = 3
    
    for i in range(12):
        y = line_y_start + (i * line_spacing)
        if y < size - margin - 100:
            draw.rectangle([
                line_start_x, y,
                line_end_x, y + line_width
            ], fill=(220, 220, 220))
    
    # Draw a pen/pencil icon
    pen_x = size - margin - 200
    pen_y = margin + 200
    pen_width = 15
    pen_length = 200
    
    # Pen body
    draw.rectangle([
        pen_x, pen_y,
        pen_x + pen_width, pen_y + pen_length
    ], fill=accent_color)
    
    # Pen tip
    draw.polygon([
        (pen_x, pen_y + pen_length),
        (pen_x + pen_width, pen_y + pen_length),
        (pen_x + pen_width // 2, pen_y + pen_length + 30)
    ], fill=(139, 69, 19))  # Brown tip
    
    # Draw app initial "P"
    try:
        # Try to use a system font
        font_size = 300
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", font_size)
            except:
                font = ImageFont.load_default()
        
        # Calculate text position to center it
        text = "P"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        text_x = (size - text_width) // 2 - 20
        text_y = (size - text_height) // 2 + 40
        
        # Draw text shadow
        draw.text((text_x + 4, text_y + 4), text, fill=(0, 0, 0, 100), font=font)
        # Draw main text
        draw.text((text_x, text_y), text, fill=primary_color, font=font)
        
    except Exception as e:
        print(f"Font error: {e}")
        # Fallback: draw a simple shape if font fails
        draw.ellipse([
            size//2 - 100, size//2 - 100,
            size//2 + 100, size//2 + 100
        ], fill=primary_color)
    
    # Save the icon
    icon_path = os.path.join("assets", "icon", "app_icon.png")
    image.save(icon_path, "PNG")
    print(f"Icon created successfully at: {icon_path}")
    
    # Also create a smaller version for favicon
    favicon = image.resize((32, 32), Image.Resampling.LANCZOS)
    favicon_path = os.path.join("web", "favicon.png")
    
    # Check if web directory exists
    if os.path.exists("web"):
        favicon.save(favicon_path, "PNG")
        print(f"Favicon created successfully at: {favicon_path}")
    
    return icon_path

if __name__ == "__main__":
    create_pebblenote_icon()