"""
Update ic_launcher_foreground.png in all mipmap folders from source image.
"""

from PIL import Image
import os

# Adaptive icon foreground sizes for each density
# Foreground should be 432x432 at xxxhdpi (108dp * 4)
DENSITIES = [
    ('mipmap-mdpi', 108),      # 108dp * 1
    ('mipmap-hdpi', 162),      # 108dp * 1.5
    ('mipmap-xhdpi', 216),     # 108dp * 2
    ('mipmap-xxhdpi', 324),    # 108dp * 3
    ('mipmap-xxxhdpi', 432),   # 108dp * 4
]

def update_foreground_icons(source_path: str, res_path: str):
    """Update ic_launcher_foreground.png in all mipmap folders."""
    
    source = Image.open(source_path)
    print(f"✅ Loaded source: {source.size[0]}x{source.size[1]}")
    
    # Convert to RGBA
    if source.mode != 'RGBA':
        source = source.convert('RGBA')
    
    for folder, size in DENSITIES:
        # Resize with high quality
        resized = source.resize((size, size), Image.Resampling.LANCZOS)
        
        output_folder = os.path.join(res_path, folder)
        output_path = os.path.join(output_folder, 'ic_launcher_foreground.png')
        
        if os.path.exists(output_folder):
            resized.save(output_path, 'PNG', optimize=True)
            print(f"✅ Updated {folder}/ic_launcher_foreground.png ({size}x{size})")
        else:
            print(f"⚠️ Folder not found: {folder}")

if __name__ == '__main__':
    source = 'assets/icon/icon_foreground.png'
    res_path = 'android/app/src/main/res'
    
    if not os.path.exists(source):
        print(f"❌ Source not found: {source}")
        print("Please save the image as assets/icon/icon_foreground.png")
    else:
        update_foreground_icons(source, res_path)
        print("\n✅ All foreground icons updated!")
