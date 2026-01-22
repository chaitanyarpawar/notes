"""
Create solid orange ic_launcher_foreground.png for all mipmap and drawable folders.
This makes the Android 12+ native splash show just orange background.
"""

from PIL import Image
import os

# All folders that contain ic_launcher_foreground.png
FOLDERS = [
    # mipmap folders
    ('mipmap-mdpi', 108),
    ('mipmap-hdpi', 162),
    ('mipmap-xhdpi', 216),
    ('mipmap-xxhdpi', 324),
    ('mipmap-xxxhdpi', 432),
    # drawable folders
    ('drawable-mdpi', 108),
    ('drawable-hdpi', 162),
    ('drawable-xhdpi', 216),
    ('drawable-xxhdpi', 324),
    ('drawable-xxxhdpi', 432),
]

# Orange color matching app theme
ORANGE = (255, 149, 0, 255)  # #FF9500

def create_orange_foreground(res_path: str):
    """Create solid orange ic_launcher_foreground.png in all folders."""
    
    for folder, size in FOLDERS:
        output_folder = os.path.join(res_path, folder)
        output_path = os.path.join(output_folder, 'ic_launcher_foreground.png')
        
        if os.path.exists(output_folder):
            # Create solid orange image
            img = Image.new('RGBA', (size, size), ORANGE)
            img.save(output_path, 'PNG', optimize=True)
            print(f"✅ Created {folder}/ic_launcher_foreground.png ({size}x{size})")
        else:
            print(f"⚠️ Folder not found: {folder}")

if __name__ == '__main__':
    res_path = 'android/app/src/main/res'
    create_orange_foreground(res_path)
    print("\n✅ All foreground icons now solid orange!")
