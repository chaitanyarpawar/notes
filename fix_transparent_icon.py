#!/usr/bin/env python3
"""
Fix icon by filling all transparent areas with orange background
"""
from PIL import Image
import os

def fix_icon_transparency(img_path):
    """Fill transparent areas with orange"""
    img = Image.open(img_path).convert('RGBA')
    
    # Create orange background
    orange_bg = Image.new('RGBA', img.size, (255, 149, 0, 255))
    
    # Composite: put original on top of orange background
    result = Image.alpha_composite(orange_bg, img)
    
    # Convert to RGB (no transparency) and save
    result = result.convert('RGB')
    result.save(img_path)
    print(f'Fixed: {img_path}')

# Fix source icon first
source_icon = 'assets/icon/icon.png'
if os.path.exists(source_icon):
    fix_icon_transparency(source_icon)
    print('Source icon fixed!')

# Fix all Android mipmap icons
folders = [
    'android/app/src/main/res/mipmap-mdpi',
    'android/app/src/main/res/mipmap-hdpi',
    'android/app/src/main/res/mipmap-xhdpi',
    'android/app/src/main/res/mipmap-xxhdpi',
    'android/app/src/main/res/mipmap-xxxhdpi',
]

for folder in folders:
    if os.path.exists(folder):
        for f in os.listdir(folder):
            if f.endswith('.png'):
                fix_icon_transparency(os.path.join(folder, f))

print('All icons fixed!')
