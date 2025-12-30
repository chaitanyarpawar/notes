#!/usr/bin/env python3
"""
Remove white space from Android mipmap icons by filling with orange background
"""
from PIL import Image
import os

def remove_whitespace(img_path):
    img = Image.open(img_path).convert('RGBA')
    # Get the bounding box of non-transparent/non-white content
    bbox = img.getbbox()
    if bbox:
        # Crop to content
        cropped = img.crop(bbox)
        # Create new image with same size, fill with orange
        new_img = Image.new('RGBA', (img.width, img.height), (255, 149, 0, 255))
        # Center the cropped content
        x = (img.width - cropped.width) // 2
        y = (img.height - cropped.height) // 2
        new_img.paste(cropped, (x, y), cropped)
        new_img.save(img_path)
        print(f'Fixed: {img_path}')

folders = [
    'android/app/src/main/res/mipmap-hdpi',
    'android/app/src/main/res/mipmap-mdpi',
    'android/app/src/main/res/mipmap-xhdpi',
    'android/app/src/main/res/mipmap-xxhdpi',
    'android/app/src/main/res/mipmap-xxxhdpi',
]

for folder in folders:
    if os.path.exists(folder):
        for f in os.listdir(folder):
            if f.endswith('.png'):
                remove_whitespace(os.path.join(folder, f))

print('Done!')
