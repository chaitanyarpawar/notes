"""
Update ic_launcher.png in all mipmap folders from source image.
"""

from PIL import Image
import os

# Standard launcher icon sizes for each density
DENSITIES = [
    ('mipmap-mdpi', 48),
    ('mipmap-hdpi', 72),
    ('mipmap-xhdpi', 96),
    ('mipmap-xxhdpi', 144),
    ('mipmap-xxxhdpi', 192),
]

def update_launcher_icons(source_path: str, res_path: str):
    """Update ic_launcher.png in all mipmap folders."""
    
    source = Image.open(source_path)
    print(f"✅ Loaded source: {source.size[0]}x{source.size[1]}")
    
    # Convert to RGBA
    if source.mode != 'RGBA':
        source = source.convert('RGBA')
    
    for folder, size in DENSITIES:
        # Resize with high quality
        resized = source.resize((size, size), Image.Resampling.LANCZOS)
        
        output_folder = os.path.join(res_path, folder)
        output_path = os.path.join(output_folder, 'ic_launcher.png')
        
        if os.path.exists(output_folder):
            resized.save(output_path, 'PNG', optimize=True)
            print(f"✅ Updated {folder}/ic_launcher.png ({size}x{size})")
        else:
            print(f"⚠️ Folder not found: {folder}")

if __name__ == '__main__':
    source = 'assets/icon/icon_foreground.png'
    res_path = 'android/app/src/main/res'
    
    if not os.path.exists(source):
        print(f"❌ Source not found: {source}")
    else:
        update_launcher_icons(source, res_path)
        print("\n✅ All launcher icons updated!")
