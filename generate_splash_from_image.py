"""
Generate Android splash screen images from the provided PebbleNote logo image.
Creates density-specific versions for all Android drawable folders.
"""

from PIL import Image
import os

# Android density specifications for splash screens
# Format: (folder_suffix, width, height)
DENSITIES = [
    ('mdpi', 320, 480),
    ('hdpi', 480, 800),
    ('xhdpi', 720, 1280),
    ('xxhdpi', 1080, 1920),
    ('xxxhdpi', 1440, 2560),
]

def generate_splash_images(source_image_path: str, output_base_path: str):
    """
    Generate splash images for all Android densities from source image.
    
    Args:
        source_image_path: Path to the source splash image
        output_base_path: Base path for Android res folder
    """
    # Load source image
    source = Image.open(source_image_path)
    print(f"✅ Loaded source image: {source.size[0]}x{source.size[1]}")
    
    # Convert to RGBA if needed
    if source.mode != 'RGBA':
        source = source.convert('RGBA')
    
    for folder_suffix, width, height in DENSITIES:
        # Calculate scaling to fit the target dimensions while maintaining aspect ratio
        source_ratio = source.width / source.height
        target_ratio = width / height
        
        if source_ratio > target_ratio:
            # Source is wider - fit to width
            new_width = width
            new_height = int(width / source_ratio)
        else:
            # Source is taller - fit to height
            new_height = height
            new_width = int(height * source_ratio)
        
        # Resize source image with high quality
        resized = source.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create target canvas with orange background
        canvas = Image.new('RGBA', (width, height), (255, 149, 0, 255))  # #FF9500
        
        # Center the resized image on canvas
        x_offset = (width - new_width) // 2
        y_offset = (height - new_height) // 2
        
        # Paste with alpha compositing
        canvas.paste(resized, (x_offset, y_offset), resized)
        
        # Convert to RGB for PNG output (no transparency needed)
        final = canvas.convert('RGB')
        
        # Determine output folder
        if folder_suffix == 'mdpi':
            folder_name = 'drawable'
        else:
            folder_name = f'drawable-{folder_suffix}'
        
        output_folder = os.path.join(output_base_path, folder_name)
        os.makedirs(output_folder, exist_ok=True)
        
        output_path = os.path.join(output_folder, 'launch_image.png')
        final.save(output_path, 'PNG', optimize=True)
        print(f"✅ Generated {folder_name}/launch_image.png ({width}x{height})")

def main():
    # Source image path (the attached image saved here)
    source_image = 'assets/icon/splash_logo.png'
    
    # Android res folder
    output_base = 'android/app/src/main/res'
    
    if not os.path.exists(source_image):
        print(f"❌ Source image not found: {source_image}")
        print("Please save the splash logo image to assets/icon/splash_logo.png")
        return
    
    print("🚀 Generating Android splash screen images...")
    generate_splash_images(source_image, output_base)
    print("\n✅ All splash images generated successfully!")
    print("\nNext: Run 'flutter build apk --debug' to test")

if __name__ == '__main__':
    main()
